//
//  UMLayerSCCP.m
//  ulibsccp
//
//  Created by Andreas Fink on 01/07/15.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMLayerSCCP.h"
#import "UMSCCP_UserProtocol.h"
#import "UMSCCP_sccpNUnitdata.h"

#import "UMSCCP_mtpPause.h"
#import "UMSCCP_mtpResume.h"
#import "UMSCCP_mtpStatus.h"
#import "UMSCCP_mtpTransfer.h"
#import "UMSCCP_Defs.h"
#import "UMSCCP_Segment.h"
#import "UMLayerSCCPApplicationContextProtocol.h"
#import <ulibgt/ulibgt.h>
#import "UMSCCP_Statistics.h"
#import "UMSCCP_StatisticSection.h"

@implementation UMLayerSCCP

-(UMMTP3Variant) variant
{
    return _mtp3.variant;
}

- (UMLayerMTP3 *)mtp3
{
    return _mtp3;
}

- (UMLayerSCCP *)init
{
    self = [super init];
    if(self)
    {
        [self genericInitialisation];
    }
    return self;
}

- (UMLayerSCCP *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq
{
    return [self initWithTaskQueueMulti:tq name:@""];
}

- (UMLayerSCCP *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq name:(NSString *)name
{
    self = [super initWithTaskQueueMulti:tq name:name];
    if(self)
    {
        [self genericInitialisation];
    }
    return self;
}

- (void)genericInitialisation
{
    _subsystemUsers = [[UMSynchronizedDictionary alloc]init];
    _dpcAvailability = [[UMSynchronizedDictionary alloc]init];
    _pendingSegments  = [[NSMutableDictionary alloc]init];
    _traceSendDestinations =[[UMSynchronizedArray alloc]init];
    _traceReceiveDestinations =[[UMSynchronizedArray alloc]init];
    _traceDroppedDestinations =[[UMSynchronizedArray alloc]init];
    _mtp3RoutingTable = [[SccpL3RoutingTable alloc]init];
    _xudt_max_hop_count = 16;
    _xudts_max_hop_count = 16;
    _gttSelectorRegistry = [[SccpGttRegistry alloc]init];
    _gttSelectorRegistry.logLevel = self.logLevel;
    _gttSelectorRegistry.logFeed = self.logFeed;
    for(int i=0;i<UMSCCP_StatisticSection_MAX;i++)
    {
        _processingStats[i] = [[UMSCCP_Statistics alloc] init];
        _throughputCounters[i] = [[UMThroughputCounter alloc] init];
    }
}

- (void)setLogLevel:(UMLogLevel)logLevel
{
    [super setLogLevel:logLevel];
    [_gttSelectorRegistry updateLogLevel:logLevel];
}

- (UMLogLevel)logLevel
{
    return [super logLevel];
}

- (void)setLogFeed:(UMLogFeed *)feed
{
    [super setLogFeed:feed];
    [_gttSelectorRegistry updateLogFeed:feed];
}

- (UMLogFeed *)logFeed
{
    return [super logFeed];
}

/* if MTP3 has a packet for us it will send us a mtpTransfer message */
- (void)mtpTransfer:(NSData *)data
       callingLayer:(id)mtp3Layer
                opc:(UMMTP3PointCode *)opc
                dpc:(UMMTP3PointCode *)dpc
                 si:(int)si
                 ni:(int)ni
        linksetName:(NSString *)linksetName
            options:(NSDictionary *)xoptions
{
    NSMutableDictionary*options;
    if(xoptions)
    {
        options = [xoptions mutableCopy];
    }
    else
    {
        options = [[NSMutableDictionary alloc]init];
    }
    options[@"mtp3-incoming-linkset"] = linksetName;

    UMSCCP_mtpTransfer *task = [[UMSCCP_mtpTransfer alloc]initForSccp:self mtp3:mtp3Layer opc:opc dpc:dpc si:si ni:ni data:data options:options];
    [self queueFromLower:task];
}

- (void)mtpPause:(NSData *)data
    callingLayer:(id)mtp3Layer
      affectedPc:(UMMTP3PointCode *)affPC
              si:(int)si
              ni:(int)ni
         options:(NSDictionary *)options
{
    UMSCCP_mtpPause *task = [[UMSCCP_mtpPause alloc]initForSccp:self
                                                           mtp3:mtp3Layer
                                              affectedPointCode:affPC
                                                             si:si
                                                             ni:ni
                                                        options:options];
    [self queueFromLowerWithPriority:task];
}

- (void)mtpResume:(NSData *)data
     callingLayer:(id)mtp3Layer
       affectedPc:(UMMTP3PointCode *)affPC
               si:(int)si
               ni:(int)ni
          options:(NSDictionary *)options
{
    UMSCCP_mtpResume *task = [[UMSCCP_mtpResume alloc]initForSccp:self
                                                             mtp3:mtp3Layer
                                                affectedPointCode:affPC
                                                               si:si
                                                               ni:ni
                                                          options:options];
    [self queueFromLowerWithPriority:task];
}

- (void)mtpStatus:(NSData *)data
     callingLayer:(id)mtp3Layer
       affectedPc:(UMMTP3PointCode *)affPC
               si:(int)si
               ni:(int)ni
           status:(int)status
          options:(NSDictionary *)options
{
    UMSCCP_mtpStatus *task = [[UMSCCP_mtpStatus alloc]initForSccp:self
                                                             mtp3:mtp3Layer
                                                affectedPointCode:affPC
                                                           status:status
                                                               si:si
                                                               ni:ni
                                                          options:options];
    [self queueFromLowerWithPriority:task];
}

- (id<UMSCCP_UserProtocol>)getUserForSubsystem:(SccpSubSystemNumber *)ssn
{
    return [self getUserForSubsystem:ssn number:[SccpAddress anyAddress]];
}

- (id<UMSCCP_UserProtocol>)getUserForSubsystem:(SccpSubSystemNumber *)ssn number:(SccpAddress *)sccpAddr
{
    NSString *number = [sccpAddr address];
    NSString *any = [[sccpAddr anyAddress] address];


    int subsystem = ssn.ssn;
    NSMutableDictionary *a = _subsystemUsers[@(subsystem)];
    if(a)
    {
        id<UMSCCP_UserProtocol>  user = a[number];
        if(user==NULL)
        {
            user = a[any];
        }
        if(user)
        {
            return user;
        }
    }
    a = _subsystemUsers[@(0)];
    if(a)
    {
        id<UMSCCP_UserProtocol>  user = a[number];
        if(user==NULL)
        {
            user = a[any];
        }
        return user;
    }
    return NULL;
}

- (void)setUser:(id<UMSCCP_UserProtocol>)usr forSubsystem:(SccpSubSystemNumber *)ssn number:(SccpAddress *)sccpAddress
{
    int subsystem = ssn.ssn;
    NSMutableDictionary *a = _subsystemUsers[@(ssn.ssn)];
    if(a==NULL)
    {
        a = [[NSMutableDictionary alloc]init];
    }
    a[sccpAddress.address] = usr;
    _subsystemUsers[@(subsystem)] = a;
}


- (void)setUser:(id<UMSCCP_UserProtocol>)usr forSubsystem:(SccpSubSystemNumber *)ssn
{
    [self setUser:usr forSubsystem:ssn number:[SccpAddress anyAddress]];
}

- (void)setDefaultUser:(id<UMSCCP_UserProtocol>)usr
{
    SccpSubSystemNumber *ssn = [[SccpSubSystemNumber alloc]init];
    ssn.ssn = 0;

    SccpAddress *addr = [[SccpAddress alloc]init];
    addr.address = @"default";

    [self setUser:usr forSubsystem:ssn number:addr];
}


-(UMMTP3_Error) sendXUDTsegment:(UMSCCP_Segment *)segment
                        calling:(SccpAddress *)src
                         called:(SccpAddress *)dst
                          class:(SCCP_ServiceClass)pclass
                       handling:(SCCP_Handling)handling
                       hopCount:(int)hopCount
                            opc:(UMMTP3PointCode *)opc
                            dpc:(UMMTP3PointCode *)dpc
                    optionsData:(NSData *)xoptionsdata
                        options:(NSDictionary *)options
                       provider:(UMLayerMTP3 *)provider
{
    NSMutableData *optionsData = [[NSMutableData alloc]init];
    [optionsData appendByte:0x10]; /* optional parameter "segmentation" */
    [optionsData appendByte:0x04]; /* length of optional parameter */
    [optionsData appendData:[segment segmentationHeader]];
    if(xoptionsdata)
    {
        [optionsData appendData:xoptionsdata]; /* length of optional parameter */
    }
    else
    {
        [optionsData appendByte:0x00]; /* end of optional parameters */
    }

    return [self sendXUDT:segment.data
                  calling:src
                   called:dst
                    class:pclass
                 handling:handling
                 hopCount:hopCount
                      opc:opc
                      dpc:dpc
              optionsData:optionsData
                  options:options
                 provider:provider];
}

-(UMMTP3_Error) sendPDU:(NSData *)pdu
                    opc:(UMMTP3PointCode *)opc
                    dpc:(UMMTP3PointCode *)dpc
                options:(NSDictionary *)options
{
    if(_mtp3==NULL)
    {
        return UMMTP3_error_no_route_to_destination;
    }
    return [_mtp3 sendPDU:pdu
                      opc:opc
                      dpc:dpc
                       si:MTP3_SERVICE_INDICATOR_SCCP
                       mp:0
                  options:options];
}

-(UMMTP3_Error) sendXUDT:(NSData *)data
                 calling:(SccpAddress *)src
                  called:(SccpAddress *)dst
                   class:(SCCP_ServiceClass)pclass
                handling:(SCCP_Handling)handling
                hopCount:(int)maxHopCount
                     opc:(UMMTP3PointCode *)opc
                     dpc:(UMMTP3PointCode *)dpc
             optionsData:(NSData *)xoptionsdata
                 options:(NSDictionary *)options
                provider:(UMLayerMTP3 *)provider
{
    NSData *srcEncoded = [src encode:_sccpVariant];
    NSData *dstEncoded = [dst encode:_sccpVariant];

    NSMutableData *sccp_pdu = [[NSMutableData alloc]init];
    uint8_t header[7];
    header[0] = SCCP_XUDT;
    header[1] = (pclass & 0x0F) | ((handling & 0x0F) << 4);
    header[2] = maxHopCount;
    header[3] = 4;
    header[4] = 4 + dstEncoded.length;
    header[5] = 4 + dstEncoded.length + srcEncoded.length;
    if(xoptionsdata.length > 0)
    {
        header[6] = 4 + dstEncoded.length + srcEncoded.length + data.length;
    }
    else
    {
        header[6] = 0;
    }
    [sccp_pdu appendBytes:header length:7];
    [sccp_pdu appendByte:dstEncoded.length];
    [sccp_pdu appendData:dstEncoded];
    [sccp_pdu appendByte:srcEncoded.length];
    [sccp_pdu appendData:srcEncoded];
    [sccp_pdu appendByte:data.length];
    [sccp_pdu appendData:data];
    if(xoptionsdata.length > 0)
    {
        [sccp_pdu appendData:xoptionsdata];
    }

    UMMTP3_Error result = [self sendPDU:sccp_pdu opc:opc dpc:dpc options:options];

    NSString *s;
    switch(result)
    {
        case UMMTP3_no_error:
            s = @"success";
            break;
        case UMMTP3_error_pdu_too_big:
            s = @"pdu-too-big";
            break;
        case UMMTP3_error_no_route_to_destination:
            s = @"no-route-to-destination";
            break;
        case UMMTP3_error_invalid_variant:
            s = @"invalid-variant";
            break;
        default:
            s = [NSString stringWithFormat:@"Unknown %d",result];
            break;
    }
    NSDictionary *o = @{
                        @"type" : @"XUDT",
                        @"action" : @"drop",
                        @"error"  : s,
                        @"opc"  : ( opc ? opc.stringValue : @"(not-set)" ),
                        @"dpc"  : ( dpc ? dpc.stringValue : @"(not-set)" ),
                        @"mtp3" : ( _mtp3 ? _mtp3.layerName : @"(not-set)")};
    if(result == UMMTP3_no_error)
    {
        id <UMSCCP_TraceProtocol> u = options[@"sccp-trace-tx-destination"];
        [ u sccpTraceSentPdu:sccp_pdu options:o];
        [ self traceSentPdu:sccp_pdu options:o];
    }
    else
    {
        id <UMSCCP_TraceProtocol> u = options[@"sccp-trace-dropped-destination"];
        [ u sccpTraceDroppedPdu:sccp_pdu options:o];
        [ self traceDroppedPdu:sccp_pdu options:o];
    }
    return result;
}




-(UMMTP3_Error) sendXUDTS:(NSData *)data
                  calling:(SccpAddress *)src
                   called:(SccpAddress *)dst
                    class:(SCCP_ServiceClass)serviceClass
                 hopCount:(int)hopCounter
              returnCause:(SCCP_ReturnCause)returnCause
                      opc:(UMMTP3PointCode *)opc
                      dpc:(UMMTP3PointCode *)dpc
              optionsData:(NSData *)xoptionsdata
                  options:(NSDictionary *)options
                 provider:(UMLayerMTP3 *)provider
{
    NSData *srcEncoded = [src encode:_sccpVariant];
    NSData *dstEncoded = [dst encode:_sccpVariant];

    NSMutableData *sccp_pdu = [[NSMutableData alloc]init];
    uint8_t header[7];
    header[0] = SCCP_XUDTS;
    header[1] = returnCause;
    header[2] = hopCounter;
    header[3] = 4;
    header[4] = 4 + dstEncoded.length;
    header[5] = 4 + dstEncoded.length + srcEncoded.length;
    if(xoptionsdata.length > 0)
    {
        header[6] = 4 + dstEncoded.length + srcEncoded.length + data.length;
    }
    else
    {
        header[6] = 0;
    }
    [sccp_pdu appendBytes:header length:7];
    [sccp_pdu appendByte:dstEncoded.length];
    [sccp_pdu appendData:dstEncoded];
    [sccp_pdu appendByte:srcEncoded.length];
    [sccp_pdu appendData:srcEncoded];
    [sccp_pdu appendByte:data.length];
    [sccp_pdu appendData:data];
    if(xoptionsdata.length > 0)
    {
        [sccp_pdu appendData:xoptionsdata];
    }

    UMMTP3_Error result = [self sendPDU:sccp_pdu opc:opc dpc:dpc options:options];
    NSString *s;
    NSString *action = @"drop";
    switch(result)
    {
        case UMMTP3_no_error:
            s = @"success";
            action = @"tx";
            break;
        case UMMTP3_error_pdu_too_big:
            s = @"pdu-too-big";
            break;
        case UMMTP3_error_no_route_to_destination:
            s = @"no-route-to-destination";
            break;
        case UMMTP3_error_invalid_variant:
            s = @"invalid-variant";
            break;
        default:
            s = [NSString stringWithFormat:@"Unknown %d",result];
            break;
    }
    NSDictionary *o = @{
                        @"type" : @"XUDTS",
                        @"action" : action,
                        @"error"  : s,
                        @"opc"  : ( opc ? opc.stringValue : @"(not-set)" ),
                        @"dpc"  : ( dpc ? dpc.stringValue : @"(not-set)" ),
                        @"mtp3" : ( _mtp3 ? _mtp3.layerName : @"(not-set)")};
    if(result == UMMTP3_no_error)
    {
        id <UMSCCP_TraceProtocol> u = options[@"sccp-trace-tx-destination"];
        [ u sccpTraceSentPdu:sccp_pdu options:o];
        [ self traceSentPdu:sccp_pdu options:o];
    }
    else
    {
        id <UMSCCP_TraceProtocol> u = options[@"sccp-trace-dropped-destination"];
        [ u sccpTraceDroppedPdu:sccp_pdu options:o];
        [ self traceDroppedPdu:sccp_pdu options:o];
    }
    return result;
}


- (SccpDestinationGroup *)findRoutes:(SccpAddress *)called
                               cause:(SCCP_ReturnCause *)cause
                    newCalledAddress:(SccpAddress **)called_out
                           localUser:(id<UMSCCP_UserProtocol> *)localUser
                       fromLocalUser:(BOOL)fromLocalUser
{
    SccpDestinationGroup *destination = NULL;
    SccpAddress *called1 = [called copy];
    if(_stpMode==NO)
    {
        if(!fromLocalUser)
        {
            /* routed by subsystem */
            if(self.logLevel <=UMLOG_DEBUG)
            {
                [self.logFeed debugText:@" Route to internal subsystem"];
            }

            id<UMSCCP_UserProtocol> upperLayer = [self getUserForSubsystem:called1.ssn number:called1];
            if(upperLayer == NULL)
            {
                [self.logFeed majorErrorText:[NSString stringWithFormat:@"no upper layer found for %@",called1.debugDescription]];
                *cause = SCCP_ReturnCause_Unequipped;
            }
            else
            {
                if(self.logLevel <=UMLOG_DEBUG)
                {
                    [self.logFeed debugText:@" Route to upper layer"];
                }
                if(localUser)
                {
                    *localUser = upperLayer;
                }
            }
        }
        else if(_default_destination_group)
        {
            destination = _default_destination_group;
        }
        else if(_next_pcs.count > 0)
        {
            destination = [[SccpDestinationGroup alloc]init];
            for(UMMTP3PointCode *pc in _next_pcs)
            {
                SccpDestination *e = [[SccpDestination alloc]init];
                e.dpc = pc;
                [destination addEntry:e];
            }
        }
        else
        {
            if(cause)
            {
                *cause = SCCP_ReturnCause_NoTranslationForAnAddressOfSuchNature;
            }
        }
    }
    else /* STP mode */
    {
        if(called1.ai.routingIndicatorBit == ROUTE_BY_GLOBAL_TITLE)
        {
            if(self.logLevel <=UMLOG_DEBUG)
            {
                [self.logFeed debugText:@" Route by global title"];
            }

            SccpGttRegistry *registry = self.gttSelectorRegistry;
            SccpGttSelector *gttSelector = [registry selectorForInstance:self.layerName
                                                                      tt:called1.tt.tt
                                                                     gti:called1.ai.globalTitleIndicator
                                                                      np:called1.npi.npi
                                                                     nai:called1.nai.nai];

            if(self.logLevel <=UMLOG_DEBUG)
            {
                [self.logFeed debugText:[NSString stringWithFormat:@" gtt-selector=%@",gttSelector.name]];
            }

            if(gttSelector == NULL)
            {
                /* we send a UDTS back as we have no forward route */
                if(self.logLevel <=UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@" SCCP selector is null for tt=%d, gti=%d, np:%d nai:%d. Returning NoTranslationForThisSpecificAddress" ,called1.tt.tt,
                                             called1.ai.globalTitleIndicator,
                                             called1.npi.npi,
                                             called1.nai.nai]];
                }
                if(cause)
                {
                    *cause = SCCP_ReturnCause_NoTranslationForAnAddressOfSuchNature;
                }
                return NULL;
            }
            else
            {
                if(gttSelector.preTranslation)
                {
                    called1 = [gttSelector.preTranslation translateAddress:called1];
                    if(self.logLevel <= UMLOG_DEBUG)
                    {
                        [self.logFeed debugText:[NSString stringWithFormat:@"pre-translation: ->%@",called1]];
                    }
                }
                SccpGttRoutingTableEntry *rte = [gttSelector findNextHopForDestination:called1];
                if(rte.routeTo == NULL)
                {
                    rte.routeTo = [registry getDestinationGroupByName:rte.routeToName];
                }
                destination = rte.routeTo;

                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@" %@",destination.description]];
                }

                if(destination == NULL)
                {
                    *cause = SCCP_ReturnCause_NoTranslationForThisSpecificAddress;
                }
                if(gttSelector.postTranslation)
                {
                    called1 = [gttSelector.postTranslation translateAddress:called1];
                    if(self.logLevel <= UMLOG_DEBUG)
                    {
                        [self.logFeed debugText:[NSString stringWithFormat:@"post-translation: ->%@",called1]];
                    }
                }
                if(called_out)
                {
                    *called_out = called1;
                }
            }
        }
        else /* ROUTE_BY_SUBSYSTEM */
        {
            /* routed by subsystem */
            if(self.logLevel <=UMLOG_DEBUG)
            {
                [self.logFeed debugText:@" Route by subsystem"];
            }

            id<UMSCCP_UserProtocol> upperLayer = [self getUserForSubsystem:called1.ssn number:called1];
            if(upperLayer == NULL)
            {
                [self.logFeed majorErrorText:[NSString stringWithFormat:@"no upper layer found for %@",called1.debugDescription]];
                *cause = SCCP_ReturnCause_Unequipped;
            }
            else
            {
                if(self.logLevel <=UMLOG_DEBUG)
                {
                    [self.logFeed debugText:@" Route to upper layer"];
                }
                if(localUser)
                {
                    *localUser = upperLayer;
                }
            }
        }
    }
    return destination;
}

- (void)chooseRouteFromGroup:(SccpDestinationGroup *)grp
                       cause:(SCCP_ReturnCause *)cause
                   localUser:(id<UMSCCP_UserProtocol> *) localUser
                         dpc:(UMMTP3PointCode **)dpc
                     m3ua_as:(NSString **)m3ua_as
               calledAddress:(SccpAddress *)called
{
    /*
     switch(grp.distributionMethod)
     {
     case SccpDestinationGroupDistributionMethod_share:
     case SccpDestinationGroupDistributionMethod_wrr:
     case SccpDestinationGroupDistributionMethod_cgpa:
     break;
     case SccpDestinationGroupDistributionMethod_cost:
     default:

     break;
     */

    if(grp==NULL)
    {
        if(cause)
        {
            *cause = SCCP_ReturnCause_MTPFailure;
        }
        return;
    }
    SccpDestination *dst = [grp chooseNextHopWithRoutingTable:_mtp3RoutingTable];
    if(dst==NULL)
    {
        if(cause)
        {
            *cause = SCCP_ReturnCause_MTPFailure;
        }
    }
    if(dst.dpc)
    {
        if(dpc)
        {
            *dpc = dst.dpc;
        }
    }
    if(dst.m3uaAs)
    {
        if(m3ua_as)
        {
            *m3ua_as = dst.m3uaAs;
        }
    }
    if(dst.ssn)
    {
        id<UMSCCP_UserProtocol> upperLayer = [self getUserForSubsystem:dst.ssn number:called];
        if(upperLayer == NULL)
        {
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"no upper layer found for  %@",called.debugDescription]];
            if(cause)
            {
                *cause = SCCP_ReturnCause_Unequipped;
            }
        }
        else
        {
            if(self.logLevel <=UMLOG_DEBUG)
            {
                [self.logFeed debugText:@" Route to upper layer"];
            }
            if(localUser)
            {
                *localUser = upperLayer;
            }
        }
    }
}


- (UMSynchronizedSortedDictionary *) routeTestForMSISDN:(NSString *)msisdn
                                        translationType:(int)tt
                                              fromLocal:(BOOL)fromLocal
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    int causeValue = -1;
    id<UMSCCP_UserProtocol> localUser = NULL;
    UMMTP3PointCode *pc = NULL;

    dict[@"original-number"] = msisdn;
    dict[@"original-tt"]     = @(tt);

    SccpAddress *dst = [[SccpAddress alloc]initWithHumanReadableString:msisdn variant:_mtp3.variant];
    dst.tt.tt = tt;

    SCCP_ReturnCause cause = SCCP_ReturnCause_not_set;
    SccpAddress *called_out = dst;
    NSString *m3ua_as = NULL;
    SccpDestinationGroup *grp = [self findRoutes:dst
                                           cause:&cause
                                newCalledAddress:&called_out
                                       localUser:&localUser
                                   fromLocalUser:fromLocal];
    if(grp)
    {
        [self chooseRouteFromGroup:grp
                             cause:&cause
                         localUser:&localUser
                               dpc:&pc
                           m3ua_as:&m3ua_as
                     calledAddress:dst];
    }
    if(causeValue >= 0)
    {
        dict[@"cause-value"] = @(causeValue);
    }
    else if(pc)
    {
        dict[@"destination-point-code"] = pc;
    }
    else if(localUser)
    {
        dict[@"local-user"] = @"yes";
    }
    else
    {
        dict[@"cause-value"] = @(SCCP_ReturnCause_Unequipped);
    }

    if(dict[@"cause-value"])
    {
        switch([dict[@"cause-value"]intValue])
        {
            case SCCP_ReturnCause_NoTranslationForAnAddressOfSuchNature:
                dict[@"cause-description"] = @"No translation for an address of such nature";
                break;
            case SCCP_ReturnCause_NoTranslationForThisSpecificAddress:
                dict[@"cause-description"] = @"No translation for this specific address";
                break;
            case SCCP_ReturnCause_SubsystemCongestion:
                dict[@"cause-description"] = @"Subsystem congestion";
                break;
            case SCCP_ReturnCause_SubsystemFailure:
                dict[@"cause-description"] = @"Subsystem Failure";
                break;

            case SCCP_ReturnCause_Unequipped:
                dict[@"cause-description"] = @"Unequipped";
                break;

            case SCCP_ReturnCause_MTPFailure:
                dict[@"cause-description"] = @"MTP failure";
                break;

            case SCCP_ReturnCause_NetworkCongestion:
                dict[@"cause-description"] = @"Network congestion";
                break;

            case SCCP_ReturnCause_Unqualified:
                dict[@"cause-description"] = @"Unqualified";
                break;

            case SCCP_ReturnCause_ErrorInMessageTransport:
                dict[@"cause-description"] = @"Errpr in message transport";
                break;

            case SCCP_ReturnCause_ErrorInLocalProcessing:
                dict[@"cause-description"] = @"Error in local processing";
                break;

            case SCCP_ReturnCause_DestinationCannotPerformReassembly:
                dict[@"cause-description"] = @"Destination cannot perform reassembly";
                break;

            case SCCP_ReturnCause_SCCPFailure:
                dict[@"cause-description"] = @"SCCP failure";
                break;

            case SCCP_ReturnCause_HopCounterViolation:
                dict[@"cause-description"] = @"Hop counter violation";
                break;

            case SCCP_ReturnCause_SegmentationNotSupported:
                dict[@"cause-description"] = @"Segmentation not supported";
                break;

            case SCCP_ReturnCause_SegmentationFailure:
                dict[@"cause-description"] = @"Segmentation failure";
                break;
            default:
                break;
        }
    }
    dict[@"new-number"] = called_out.stringValueE164;
    dict[@"new-tt"] = @(called_out.tt.tt);
    dict[@"destination-group"] = [grp statusForL3RoutingTable:_mtp3RoutingTable];
    if(m3ua_as)
    {
        dict[@"routed-to-m3ua-as"] = m3ua_as;
    }
    if(pc)
    {
        dict[@"routed-to-dpc"] = pc;
    }
    if(localUser)
    {
        dict[@"routed-to-local-user"] = localUser.layerName;
    }

    return dict;
}

- (BOOL)routePacket:(UMSCCP_Packet *)packet
{
    if(packet.incomingOpc==NULL)
    {
        packet.incomingOpc = _mtp3.opc;
    }
    if(packet.outgoingOpc==NULL)
    {
        packet.outgoingOpc = _mtp3.opc;
    }
    if(self.logLevel <=UMLOG_DEBUG)
    {
        NSMutableString *s = [[NSMutableString alloc]init];
        if(packet.incomingFromLocal)
        {
            [s appendFormat:@"MsgType %@   from local\n",packet.incomingPacketType];
        }
        else
        {
            [s appendFormat:@"MsgType %@   LS: %@\n",packet.incomingPacketType,packet.incomingLinkset];
        }
        [s appendFormat:@"OPC: %@\tCgPA: %@\n",packet.incomingOpc,packet.incomingCallingPartyAddress];
        [s appendFormat:@"DPC: %@\tCdPA: %@\n",packet.incomingDpc,packet.incomingCalledPartyAddress];
        [self.logFeed debugText:s];
    }

    BOOL returnValue = NO;
    BOOL doSendStatus = NO;
    id<UMSCCP_UserProtocol> localUser =NULL;
    UMMTP3PointCode *pc = NULL;
    UMLayerMTP3 *provider = _mtp3;

    SccpAddress *dst = packet.incomingCalledPartyAddress;
    SCCP_ReturnCause causeValue = SCCP_ReturnCause_not_set;
    SccpAddress *called_out = NULL;
    SccpDestinationGroup *grp = [self findRoutes:dst
                                           cause:&causeValue
                                newCalledAddress:&called_out
                                       localUser:&localUser
                                   fromLocalUser:packet.incomingFromLocal];
    
    if(self.logLevel <=UMLOG_DEBUG)
    {
        NSString *s = [NSString stringWithFormat:@"findRoutes:%@ returns:\n\tdestinationGroup=%@\n\tcause=%d\n\tnewCalledAddress=%@\n\tlocalUser=%@\n\tfromLocal=%@\n",dst,grp,causeValue,called_out,localUser,packet.incomingFromLocal ? @"YES" : @"NO"];
        [self logDebug:s];
    }

    if(called_out!=NULL)
    {
        packet.outgoingCalledPartyAddress = called_out;
    }
    
    if(causeValue != SCCP_ReturnCause_not_set)
    {
        NSString *s = [NSString stringWithFormat:@"Can not forward %@. No route to destination PC=%@. SRC=%@ DST=%@ DATA=%@",
                       packet.incomingPacketType,
                       packet.incomingOpc,
                       packet.incomingCallingPartyAddress,
                       packet.incomingCalledPartyAddress,
                       packet.incomingSccpData];
        [self logMinorError:s];
        if(packet.incomingHandling == SCCP_HANDLING_RETURN_ON_ERROR)
        {
            doSendStatus = YES;
        }
        [_unrouteablePacketsTraceDestination logPacket:packet];
    }

    else if(localUser)
    {
        packet.outgoingToLocal = YES;
        packet.outgoingLocalUser = localUser;
        if((packet.incomingServiceType == SCCP_UDTS) || (packet.incomingServiceType == SCCP_XUDTS) || (packet.incomingServiceType == SCCP_LUDTS))
        {
            [localUser sccpNNotice:packet.outgoingSccpData
                      callingLayer:self
                           calling:packet.outgoingCallingPartyAddress
                            called:packet.outgoingCalledPartyAddress
                            reason:packet.outgoingReturnCause
                           options:packet.outgoingOptions];
        }
        else
        {
            [localUser sccpNUnitdata:packet.outgoingSccpData
                        callingLayer:self
                             calling:packet.outgoingCallingPartyAddress
                              called:packet.outgoingCalledPartyAddress
                    qualityOfService:0
                               class:packet.outgoingServiceClass
                            handling:packet.outgoingHandling
                             options:packet.outgoingOptions];
        }
        returnValue = YES;
    }

    else if(grp)
    {
        SccpDestination *dest = [grp chooseNextHopWithRoutingTable:_mtp3RoutingTable];
        if(dest.ntt)
        {
            packet.outgoingCalledPartyAddress.tt.tt = [dest.ntt intValue];
        }
        if(_ntt)
        {
            packet.outgoingCalledPartyAddress.tt = _ntt;
        }

        if(dest.dpc)
        {
            pc = dest.dpc;
        }
        packet.outgoingDpc = pc;

        if(pc==NULL)
        {
            causeValue = SCCP_ReturnCause_NoTranslationForThisSpecificAddress;
            NSString *s = [NSString stringWithFormat:@"Can not forward %@. No route to destination PC=%@. SRC=%@ DST=%@ DATA=%@",
                           packet.incomingPacketType,
                           packet.incomingOpc,
                           packet.incomingCallingPartyAddress,
                           packet.incomingCalledPartyAddress,
                           packet.incomingSccpData];
            [self logMinorError:s];
            if(packet.incomingHandling == SCCP_HANDLING_RETURN_ON_ERROR)
            {
                doSendStatus = YES;
            }
            [_unrouteablePacketsTraceDestination logPacket:packet];
        }
        else
        {
            UMMTP3_Error e;
            switch(packet.outgoingServiceType)
            {
                case SCCP_UDT:
                    e = [self sendUDT:packet.outgoingSccpData
                              calling:packet.outgoingCallingPartyAddress
                               called:packet.outgoingCalledPartyAddress
                                class:packet.outgoingServiceClass
                             handling:packet.outgoingHandling
                                  opc:packet.outgoingOpc
                                  dpc:packet.outgoingDpc
                              options:packet.outgoingOptions
                             provider:provider];
                    break;
                case SCCP_UDTS:
                    e = [self sendUDTS:packet.outgoingSccpData
                               calling:packet.outgoingCallingPartyAddress
                                called:packet.outgoingCalledPartyAddress
                                 class:packet.outgoingServiceClass
                           returnCause:packet.outgoingReturnCause
                                   opc:packet.outgoingOpc
                                   dpc:packet.outgoingDpc
                               options:packet.outgoingOptions
                              provider:provider];
                    break;
                case SCCP_XUDT:
                    e = [self sendXUDT:packet.outgoingSccpData
                               calling:packet.outgoingCallingPartyAddress
                                called:packet.outgoingCalledPartyAddress
                                 class:packet.outgoingServiceClass
                              handling:packet.outgoingHandling
                              hopCount:packet.outgoingMaxHopCount
                                   opc:packet.outgoingOpc
                                   dpc:packet.outgoingDpc
                           optionsData:packet.outgoingOptionalData
                               options:packet.outgoingOptions
                              provider:provider];
                    break;
                case SCCP_XUDTS:
                    e = [self sendXUDTS:packet.outgoingSccpData
                                calling:packet.outgoingCallingPartyAddress
                                 called:packet.outgoingCalledPartyAddress
                                  class:packet.outgoingServiceClass
                               hopCount:packet.outgoingMaxHopCount
                            returnCause:packet.outgoingReturnCause
                                    opc:packet.outgoingOpc
                                    dpc:packet.outgoingDpc
                            optionsData:packet.outgoingOptionalData
                                options:packet.outgoingOptions
                               provider:provider];
                    break;
                case SCCP_LUDT:
                    e = UMMTP3_error_invalid_variant;
                    break;
                case SCCP_LUDTS:
                    e = UMMTP3_error_invalid_variant;
                    break;
            }
            NSString *s= NULL;
            switch(e)
            {
                case UMMTP3_no_error:
                    break;
                case UMMTP3_error_pdu_too_big:
                    
                    s = [NSString stringWithFormat:@"Can not forward %@. PDU too big. SRC=%@ DST=%@ DATA=%@",packet.outgoingPacketType,packet.outgoingOpc,packet.outgoingDpc,packet.outgoingSccpData];
                    break;
                case UMMTP3_error_no_route_to_destination:
                    s = [NSString stringWithFormat:@"Can not forward %@. No route to destination PC=%@. SRC=%@ DST=%@ DATA=%@",packet.outgoingPacketType,pc,packet.outgoingOpc,packet.outgoingDpc,packet.outgoingSccpData];
                    break;
                case UMMTP3_error_invalid_variant:
                    s = [NSString stringWithFormat:@"Can not forward %@. Invalid variant. SRC=%@ DST=%@ DATA=%@",packet.outgoingPacketType,packet.outgoingOpc,packet.outgoingDpc,packet.outgoingSccpData];
                    break;
            }
            if(s)
            {
                [self logMinorError:s];
                NSLog(@"Packet:\n%@\n",packet.description);
            }


             if(packet.incomingHandling == SCCP_HANDLING_RETURN_ON_ERROR)
            {
                doSendStatus = YES;
                switch(e)
                {
                    case UMMTP3_error_no_route_to_destination:
                        causeValue = SCCP_ReturnCause_MTPFailure;
                        [_unrouteablePacketsTraceDestination logPacket:packet];
                        break;
                    case UMMTP3_error_pdu_too_big:
                        causeValue = SCCP_ReturnCause_ErrorInMessageTransport;
                        [_problematicTraceDestination logPacket:packet];
                        break;
                    case UMMTP3_error_invalid_variant:
                        causeValue = SCCP_ReturnCause_ErrorInLocalProcessing;
                        [_problematicTraceDestination logPacket:packet];
                        break;
                    default:
                        doSendStatus = NO;
                        break;
                }
            }
        }
    }

    if(doSendStatus)
    {
        if(packet.incomingHandling == SCCP_HANDLING_RETURN_ON_ERROR)
        {
            if(packet.incomingServiceType==SCCP_UDT)
            {
                [self generateUDTS:packet.incomingSccpData
                           calling:packet.incomingCalledPartyAddress
                            called:packet.incomingCallingPartyAddress
                             class:packet.incomingServiceClass
                       returnCause:causeValue
                               opc:_mtp3.opc /* errors are always sent from this instance */
                               dpc:packet.incomingOpc
                           options:@{}
                          provider:_mtp3];
            }
            else if(packet.incomingServiceType==SCCP_XUDT)
            {
                [self generateXUDTS:packet.incomingSccpData
                            calling:packet.incomingCalledPartyAddress
                             called:packet.incomingCallingPartyAddress
                              class:packet.incomingServiceClass
                        returnCause:causeValue
                                opc:_mtp3.opc /* errors are always sent from this instance */
                                dpc:packet.incomingOpc
                            options:@{}
                           provider:_mtp3];
            }
            else if(packet.incomingServiceType==SCCP_LUDT)
            {
                [self generateLUDTS:packet.incomingSccpData
                            calling:packet.incomingCalledPartyAddress
                             called:packet.incomingCallingPartyAddress
                              class:packet.incomingServiceClass
                        returnCause:causeValue
                                opc:_mtp3.opc /* errors are always sent from this instance */
                                dpc:packet.incomingOpc
                            options:@{}
                           provider:_mtp3];
            }
            [_unrouteablePacketsTraceDestination logPacket:packet];
            
            [self generateUDTS:packet.incomingSccpData
                       calling:packet.incomingCalledPartyAddress
                        called:packet.incomingCallingPartyAddress
                         class:packet.incomingServiceClass
                   returnCause:causeValue
                           opc:_mtp3.opc /* errors are always sent from this instance */
                           dpc:packet.incomingOpc
                       options:@{}
                      provider:_mtp3];
        }

    }
    packet.routed = [[NSDate alloc]init];
    return returnValue;
}

- (UMMTP3_Error) sendUDT:(NSData *)data
                 calling:(SccpAddress *)src
                  called:(SccpAddress *)dst
                   class:(SCCP_ServiceClass)pclass   /* MGMT is class 0 */
                handling:(SCCP_Handling)handling
                     opc:(UMMTP3PointCode *)opc
                     dpc:(UMMTP3PointCode *)dpc
                 options:(NSDictionary *)options
                provider:(UMLayerMTP3 *)provider
{
    NSData *srcEncoded = [src encode:_sccpVariant];
    NSData *dstEncoded = [dst encode:_sccpVariant];

    NSMutableData *sccp_pdu = [[NSMutableData alloc]init];
    uint8_t header[5];
    header[0] = SCCP_UDT;
    header[1] = (pclass & 0x0F) ;
    if(handling == SCCP_HANDLING_RETURN_ON_ERROR)
    {
        header[1] |= 0x80;
    }
    header[2] = 3;
    header[3] = 3 + dstEncoded.length;
    header[4] = 3 + dstEncoded.length + srcEncoded.length;
    [sccp_pdu appendBytes:header length:5];
    [sccp_pdu appendByte:dstEncoded.length];
    [sccp_pdu appendData:dstEncoded];
    [sccp_pdu appendByte:srcEncoded.length];
    [sccp_pdu appendData:srcEncoded];
    [sccp_pdu appendByte:data.length];
    [sccp_pdu appendData:data];

    UMMTP3_Error result = [self sendPDU:sccp_pdu opc:opc dpc:dpc options:options];
    NSString *s;
    NSString *action = @"drop";
    switch(result)
    {
        case UMMTP3_no_error:
            s = @"success";
            action = @"tx";
            break;
        case UMMTP3_error_pdu_too_big:
            s = @"pdu-too-big";
            break;
        case UMMTP3_error_no_route_to_destination:
            s = @"no-route-to-destination";
            break;
        case UMMTP3_error_invalid_variant:
            s = @"invalid-variant";
            break;
        default:
            s = [NSString stringWithFormat:@"Unknown %d",result];
            break;
    }
    NSDictionary *o = @{
                        @"type" : @"UDT",
                        @"action" : action,
                        @"error"  : s,
                        @"opc"  : ( opc ? opc.stringValue : @"(not-set)" ),
                        @"dpc"  : ( dpc ? dpc.stringValue : @"(not-set)" ),
                        @"mtp3" : ( _mtp3 ? _mtp3.layerName : @"(not-set)")};
    if(result == UMMTP3_no_error)
    {
        id <UMSCCP_TraceProtocol> u = options[@"sccp-trace-tx-destination"];
        [ u sccpTraceSentPdu:sccp_pdu options:o];
        [ self traceSentPdu:sccp_pdu options:o];
    }
    else
    {
        id <UMSCCP_TraceProtocol> u = options[@"sccp-trace-dropped-destination"];
        [ u sccpTraceDroppedPdu:sccp_pdu options:o];
        [ self traceDroppedPdu:sccp_pdu options:o];
    }
    switch(result)
    {
        case UMMTP3_error_pdu_too_big:
            [self.logFeed majorErrorText:@"PDU too big"];
            break;
        case UMMTP3_error_no_route_to_destination:
            [self.logFeed majorErrorText:@"No route to destination"];
            break;
        case UMMTP3_error_invalid_variant:
            [self.logFeed majorErrorText:@"Invalid variant"];
            break;
        case UMMTP3_no_error:
            if(self.logLevel <= UMLOG_DEBUG)
            {
                [self.logFeed debugText:[NSString stringWithFormat:@"sendPDU to %@: %@->%@ success",_mtp3.layerName, opc,dpc]];
            }
            break;
        default:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"sendPDU %@: %@->%@ returns unknown error %d",_mtp3.layerName,opc,dpc,result]];

    }
    return result;
}


- (UMMTP3_Error) sendUDTS:(NSData *)data
                     calling:(SccpAddress *)src
                      called:(SccpAddress *)dst
                       class:(SCCP_ServiceClass)pclass
                 returnCause:(SCCP_ReturnCause)returnCause
                         opc:(UMMTP3PointCode *)opc
                         dpc:(UMMTP3PointCode *)dpc
                     options:(NSDictionary *)options
                    provider:(UMLayerMTP3 *)provider
{
    NSData *srcEncoded = [src encode:_sccpVariant];
    NSData *dstEncoded = [dst encode:_sccpVariant];

    NSMutableData *sccp_pdu = [[NSMutableData alloc]init];
    uint8_t header[5];
    header[0] = SCCP_UDTS;
    header[1] = returnCause;
    header[2] = 3;
    header[3] = 3 + dstEncoded.length;
    header[4] = 3 + dstEncoded.length + srcEncoded.length;
    [sccp_pdu appendBytes:header length:5];
    [sccp_pdu appendByte:dstEncoded.length];
    [sccp_pdu appendData:dstEncoded];
    [sccp_pdu appendByte:srcEncoded.length];
    [sccp_pdu appendData:srcEncoded];
    [sccp_pdu appendByte:data.length];
    [sccp_pdu appendData:data];

    UMMTP3_Error result = [self sendPDU:sccp_pdu opc:opc dpc:dpc options:options];
    NSString *s;
    NSString *action = @"drop";
    switch(result)
    {
        case UMMTP3_no_error:
            s = @"success";
            action = @"tx";
            break;
        case UMMTP3_error_pdu_too_big:
            s = @"pdu-too-big";
            break;
        case UMMTP3_error_no_route_to_destination:
            s = @"no-route-to-destination";
            break;
        case UMMTP3_error_invalid_variant:
            s = @"invalid-variant";
            break;
        default:
            s = [NSString stringWithFormat:@"Unknown %d",result];
            break;
    }
    NSDictionary *o = @{
                        @"type" : @"UDTS",
                        @"action" : action,
                        @"error"  : s,
                        @"opc"  : ( opc ? opc.stringValue : @"(not-set)" ),
                        @"dpc"  : ( dpc ? dpc.stringValue : @"(not-set)" ),
                        @"mtp3" : ( _mtp3 ? _mtp3.layerName : @"(not-set)")};
    if(result == UMMTP3_no_error)
    {
        id <UMSCCP_TraceProtocol> u = options[@"sccp-trace-tx-destination"];
        [ u sccpTraceSentPdu:sccp_pdu options:o];
        [ self traceSentPdu:sccp_pdu options:o];
    }
    else
    {
        id <UMSCCP_TraceProtocol> u = options[@"sccp-trace-dropped-destination"];
        [ u sccpTraceDroppedPdu:sccp_pdu options:o];
        [ self traceDroppedPdu:sccp_pdu options:o];
    }
    switch(result)
    {
        case UMMTP3_error_pdu_too_big:
            [self.logFeed majorErrorText:@"PDU too big"];
            break;
        case UMMTP3_error_no_route_to_destination:
            [self.logFeed majorErrorText:@"No route to destination"];
            break;
        case UMMTP3_error_invalid_variant:
            [self.logFeed majorErrorText:@"Invalid variant"];
            break;
        case UMMTP3_no_error:
            if(self.logLevel <= UMLOG_DEBUG)
            {
                [self.logFeed debugText:[NSString stringWithFormat:@"sendPDU to %@: %@->%@ success",_mtp3.layerName, opc,dpc]];
            }
            break;
        default:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"sendPDU %@: %@->%@ returns unknown error %d",_mtp3.layerName,opc,dpc,result]];

    }
    return result;
}

- (UMMTP3_Error) generateXUDTS:(NSData *)data
                      calling:(SccpAddress *)src
                       called:(SccpAddress *)dst
                        class:(SCCP_ServiceClass)pclass
                  returnCause:(SCCP_ReturnCause)reasonCode
                          opc:(UMMTP3PointCode *)opc
                          dpc:(UMMTP3PointCode *)dpc
                      options:(NSDictionary *)options
                     provider:(UMLayerMTP3 *)provider
{
    return [self generateUDTS:data
                      calling:src
                       called:dst
                        class:pclass
                  returnCause:reasonCode
                          opc:opc
                          dpc:dpc
                      options:options
                     provider:provider];
}

- (UMMTP3_Error) generateLUDTS:(NSData *)data
                       calling:(SccpAddress *)src
                        called:(SccpAddress *)dst
                         class:(SCCP_ServiceClass)pclass
                   returnCause:(SCCP_ReturnCause)reasonCode
                           opc:(UMMTP3PointCode *)opc
                           dpc:(UMMTP3PointCode *)dpc
                       options:(NSDictionary *)options
                      provider:(UMLayerMTP3 *)provider
{
    return [self generateUDTS:data
                      calling:src
                       called:dst
                        class:pclass
                  returnCause:reasonCode
                          opc:opc
                          dpc:dpc
                      options:options
                     provider:provider];
}

- (UMMTP3_Error) generateUDTS:(NSData *)data
                      calling:(SccpAddress *)src
                       called:(SccpAddress *)dst
                        class:(SCCP_ServiceClass)pclass
                  returnCause:(SCCP_ReturnCause)reasonCode
                          opc:(UMMTP3PointCode *)opc
                          dpc:(UMMTP3PointCode *)dpc
                      options:(NSDictionary *)options
                     provider:(UMLayerMTP3 *)provider
{

    UMSCCP_Packet *packet = [[UMSCCP_Packet alloc]init];
    packet.incomingOpc = opc;
    packet.incomingDpc = dpc;
    packet.incomingCallingPartyAddress = src;
    packet.incomingCalledPartyAddress = dst;
    packet.incomingServiceType = SCCP_UDTS;
    packet.incomingReturnCause = reasonCode;
    packet.incomingOptions = options;
    packet.incomingServiceClass = pclass;
    packet.incomingMtp3Layer = provider;
    packet.incomingSccpData = data;

    if(_routeErrorsBackToOriginatingPointCode || /* DISABLES CODE */ (1)) /* if this flag is set, we send the packet back to the original OPC, no matter what. We dont use local routing table to send the UDTS backt to the calling address */
    {
        return [self sendUDTS:data
               calling:src
                called:dst
                 class:pclass
           returnCause:reasonCode
                   opc:opc
                   dpc:dpc
               options:options
                     provider:provider];
    }
    else
    {
        BOOL routingResult = [self routePacket:packet];
        if(routingResult==YES) /* success */ 
        {
            return UMMTP3_no_error;
        }
        return UMMTP3_error_no_route_to_destination;
    }

#if 0
    SccpAddress *src2 = [src copy];
    src2.ai.pointCodeIndicator = YES;
    src2.pc = opc;

    NSData *srcEncoded = [src2 encode:_sccpVariant];
    NSData *dstEncoded = [dst encode:_sccpVariant];

    NSMutableData *sccp_pdu = [[NSMutableData alloc]init];
    uint8_t header[5];
    header[0] = SCCP_UDTS;
    header[1] = reasonCode;
    header[2] = 3;
    header[3] = 3 + dstEncoded.length;
    header[4] = 3 + dstEncoded.length + srcEncoded.length;
    [sccp_pdu appendBytes:header length:5];
    [sccp_pdu appendByte:dstEncoded.length];
    [sccp_pdu appendData:dstEncoded];
    [sccp_pdu appendByte:srcEncoded.length];
    [sccp_pdu appendData:srcEncoded];
    [sccp_pdu appendByte:data.length];
    [sccp_pdu appendData:data];
    if(dpc == opc) /* local generated */
    {
        [localUser sccpNNotice:(NSData *)data
                  callingLayer:self
                       calling:src
                        called:dst
                        reason:reasonCode
                       options:options];
    }

    UMMTP3_Error result = [self sendPDU:sccp_pdu opc:opc dpc:dpc options:options];
    NSString *s;
    NSString *action = @"drop";
    switch(result)
    {
        case UMMTP3_no_error:
            s = @"success";
            action = @"tx";
            break;
        case UMMTP3_error_pdu_too_big:
            s = @"pdu-too-big";
            break;
        case UMMTP3_error_no_route_to_destination:
            s = @"no-route-to-destination";
            break;
        case UMMTP3_error_invalid_variant:
            s = @"invalid-variant";
            break;
        default:
            s = [NSString stringWithFormat:@"Unknown %d",result];
            break;
    }
    NSDictionary *o = @{
                        @"type" : @"UDTS",
                        @"action" : action,
                        @"error"  : s,
                        @"opc"  : ( opc ? opc.stringValue : @"(not-set)" ),
                        @"dpc"  : ( dpc ? dpc.stringValue : @"(not-set)" ),
                        @"mtp3" : ( _mtp3 ? _mtp3.layerName : @"(not-set)")};
    if(result == UMMTP3_no_error)
    {
        id <UMSCCP_TraceProtocol> u = options[@"sccp-trace-tx-destination"];
        [ u sccpTraceSentPdu:sccp_pdu options:o];
        [ self traceSentPdu:sccp_pdu options:o];
    }
    else
    {
        id <UMSCCP_TraceProtocol> u = options[@"sccp-trace-dropped-destination"];
        [ u sccpTraceDroppedPdu:sccp_pdu options:o];
        [ self traceDroppedPdu:sccp_pdu options:o];
    }
    switch(result)
    {
        case UMMTP3_error_pdu_too_big:
            [self.logFeed majorErrorText:@"PDU too big"];
            break;
        case UMMTP3_error_no_route_to_destination:
            [self.logFeed majorErrorText:@"No route to destination"];
            break;
        case UMMTP3_error_invalid_variant:
            [self.logFeed majorErrorText:@"Invalid variant"];
            break;
        case UMMTP3_no_error:
            if(self.logLevel <= UMLOG_DEBUG)
            {
                [self.logFeed debugText:[NSString stringWithFormat:@"sendPDU to %@: %@->%@ success",_mtp3.layerName, opc,dpc]];
            }
            break;
        default:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"sendPDU %@: %@->%@ returns unknown error %d",_mtp3.layerName,opc,dpc,result]];
    }
    return result;
#endif

}

- (NSUInteger)maxPayloadSizeForServiceType:(SCCP_ServiceType) serviceType
                        callingAddressSize:(NSUInteger)cas
                         calledAddressSize:(NSUInteger)cds
                             usingSegments:(BOOL)useSeg
                                  provider:(UMLayerMTP3 *)provider
{
    NSUInteger maxSccpSize = provider.maxPduSize - 5;

    if(serviceType == SCCP_UDT)
    {
        return  (maxSccpSize - 8  - cas - cds);
    }
    if(serviceType == SCCP_XUDT)
    {
        if(useSeg)
        {
            return (maxSccpSize - 17 -cas -cds);
        }
        else
        {
            return (maxSccpSize - 10 -cas -cds);
        }
    }
    /* FIXME: other PDU types have other maximums */
    return  (maxSccpSize - 8  - cas - cds);
}

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerSCCPApplicationContextProtocol>)appContext
{
    [self readLayerConfig:cfg];
    if(cfg[@"attach-to"])
    {
        _mtp3_name =  [cfg[@"attach-to"] stringValue];
        _mtp3 = [appContext getMTP3:_mtp3_name];
        if(_mtp3 == NULL)
        {
            NSString *s = [NSString stringWithFormat:@"Can not find mtp3 layer '%@' referred from sccp '%@'",_mtp3_name,self.layerName];
            @throw([NSException exceptionWithName:[NSString stringWithFormat:@"CONFIG_ERROR FILE %s line:%ld",__FILE__,(long)__LINE__]
                                           reason:s
                                         userInfo:NULL]);
        }
        [_mtp3 setUserPart:MTP3_SERVICE_INDICATOR_SCCP user:self];
    }
    if(cfg[@"mode"])
    {
        NSString *v = [cfg[@"mode"] stringValue];
        if([v isEqualToString:@"stp"])
        {
            _stpMode = YES;
        }
        else if([v isEqualToString:@"ssp"])
        {
            _stpMode = NO;
        }
    }

    if(cfg[@"variant"])
    {
        NSString *v = [cfg[@"variant"] stringValue];
        if([v isEqualToString:@"itu"])
        {
            _sccpVariant = SCCP_VARIANT_ITU;
        }
        if([v isEqualToString:@"ansi"])
        {
            _sccpVariant = SCCP_VARIANT_ANSI;
        }
        else
        {
            _sccpVariant = SCCP_VARIANT_ITU;
        }
    }

    NSNumber *n = cfg[@"ntt"];
    if(n)
    {
        _ntt = [[SccpTranslationTableNumber alloc]initWithInt:[n intValue]];
    }

    NSArray<NSString *> *sa = cfg[@"next-pc"];
    if(sa.count>0)
    {
        SccpDestinationGroup *destination = [[SccpDestinationGroup alloc]init];
        NSMutableArray<UMMTP3PointCode *> *a = [[NSMutableArray alloc]init];
        for(NSString *s in sa)
        {
            UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithString:s variant:_mtp3.variant];
            if(pc)
            {
                [a addObject:pc];

                SccpDestination *e = [[SccpDestination alloc]init];
                e.dpc = pc;
                e.ntt = @(_ntt.tt);
                [destination addEntry:e];
            }
        }
        _next_pcs = a;
        _default_destination_group = destination;
    }

    [_gttSelectorRegistry updateLogLevel:self.logLevel];
    [_gttSelectorRegistry updateLogFeed:self.logFeed];
    if(cfg[@"gt-file"])
    {
        NSArray<NSString *> *a =cfg[@"gt-file"];
        for(NSString *f in a)
        {
            [self readFromGtFile:f];
        }
        NSLog(@"gt files read");
    }
    if(cfg[@"gtt-file"])
    {
        NSArray<NSString *> *a =cfg[@"gtt-file"];
        for(NSString *f in a)
        {
            [self readFromGtFile:f];
        }
        NSLog(@"gtt files read");
    }

}


- (NSDictionary *)config
{
    NSMutableDictionary *cfg = [[NSMutableDictionary alloc]init];
    [self addLayerConfig:cfg];

    cfg[@"attach-to"] = _mtp3_name;

    if(_sccpVariant==SCCP_VARIANT_ITU)
    {
        cfg[@"variant"] = @"itu";
    }
    else if(_sccpVariant==SCCP_VARIANT_ANSI)
    {
        cfg[@"variant"] = @"ansi";
    }
    return cfg;
}

/* connection oriented primitives */
- (void)sccpNConnectRequest:(UMSCCPConnection **)connection
               callingLayer:(id<UMSCCP_UserProtocol>)userLayer
                    calling:(SccpAddress *)src
                     called:(SccpAddress *)dst
                    options:(NSDictionary *)options
                synchronous:(BOOL)sync
{
    NSLog(@"sccpNConnectRequest not implemented");
}

- (void)sccpNDataRequest:(NSData *)data
              connection:(UMSCCPConnection *)connection
                 options:(NSDictionary *)options
             synchronous:(BOOL)sync
{
    [self.logFeed majorErrorText:@"sccpNDataRequest: not implemented"];
}

- (void)sccpNExpeditedData:(NSData *)data
                connection:(UMSCCPConnection *)connection
                   options:(NSDictionary *)options
               synchronous:(BOOL)sync
{
    [self.logFeed majorErrorText:@"sccpNExpeditedData: not implemented"];
}

- (void)sccpNResetRequest:(UMSCCPConnection *)connection
                  options:(NSDictionary *)options
              synchronous:(BOOL)sync
{
    [self.logFeed majorErrorText:@"sccpNResetRequest: not implemented"];
}


- (void)sccpNResetIndication:(UMSCCPConnection *)connection
                     options:(NSDictionary *)options
                 synchronous:(BOOL)sync
{
    [self.logFeed majorErrorText:@"sccpNResetIndication: not implemented"];
}


- (void)sccpNDisconnectRequest:(UMSCCPConnection *)connection
                       options:(NSDictionary *)options
                   synchronous:(BOOL)sync
{
    [self.logFeed majorErrorText:@"sccpNDisconnectRequest: not implemented"];
}


- (void)sccpNDisconnectIndicaton:(UMSCCPConnection *)connection
                         options:(NSDictionary *)options
                     synchronous:(BOOL)sync
{
    [self.logFeed majorErrorText:@"sccpNDisconnectIndicaton: not implemented"];
}

- (void)sccpNInform:(UMSCCPConnection *)connection
            options:(NSDictionary *)options
        synchronous:(BOOL)sync
{
    NSLog(@"sccpNInform not implemented");
}

/* connectionless primitives */
- (void)sccpNUnidata:(NSData *)data
        callingLayer:(id<UMSCCP_UserProtocol>)userLayer
             calling:(SccpAddress *)src
              called:(SccpAddress *)dst
    qualityOfService:(int)qos
               class:(SCCP_ServiceClass)pclass
            handling:(SCCP_Handling)handling
             options:(NSDictionary *)options
{
    UMSCCP_sccpNUnitdata *task;
    task = [[UMSCCP_sccpNUnitdata alloc]initForSccp:self
                                               user:userLayer
                                           userData:data
                                            calling:src
                                             called:dst
                                   qualityOfService:qos
                                              class:pclass
                                           handling:handling
                                            options:options];
    [self queueFromUpper:task];
}

- (void)sccpNNotice:(NSData *)data
       callingLayer:(id<UMSCCP_UserProtocol>)userLayer
            calling:(SccpAddress *)src
             called:(SccpAddress *)dst
            options:(NSDictionary *)options
{
    NSLog(@"sccpNNotice not implemented");
}

- (void)sccpNState:(NSData *)data
      callingLayer:(id<UMSCCP_UserProtocol>)userLayer
           calling:(SccpAddress *)src
            called:(SccpAddress *)dst
           options:(NSDictionary *)options
{
    NSLog(@"sccpNState not implemented");
}


- (void)sccpNCoord:(NSData *)data
      callingLayer:(id<UMSCCP_UserProtocol>)userLayer
           calling:(SccpAddress *)src
            called:(SccpAddress *)dst
           options:(NSDictionary *)options
{
    NSLog(@"sccpNCoord not implemented");
}


- (void)sccpNTraffic:(NSData *)data
        callingLayer:(id<UMSCCP_UserProtocol>)userLayer
             calling:(SccpAddress *)src
              called:(SccpAddress *)dst
             options:(NSDictionary *)options
{
    NSLog(@"sccpNTraffic not implemented");
}


- (void)sccpNPcState:(NSData *)data
        callingLayer:(id<UMSCCP_UserProtocol>)userLayer
             calling:(SccpAddress *)src
              called:(SccpAddress *)dst
             options:(NSDictionary *)options
{
    NSLog(@"sccpNPcState not implemented");
}


- (void)sccpNConnectRequest:(UMSCCPConnection **)connection
               callingLayer:(id<UMSCCP_UserProtocol>)userLayer
                    calling:(SccpAddress *)src
                     called:(SccpAddress *)dst
                    options:(NSDictionary *)xoptions
{

}

- (void)sccpNDataRequest:(NSData *)data
              connection:(UMSCCPConnection *)xconnection
                 options:(NSDictionary *)xoptions
{

}


- (void)sccpNExpeditedData:(NSData *)data
                connection:(UMSCCPConnection *)xconnection
                   options:(NSDictionary *)xoptions
{

}


- (void)sccpNResetRequest:(UMSCCPConnection *)xconnection
                  options:(NSDictionary *)xoptions
{

}


- (void)sccpNResetIndication:(UMSCCPConnection *)connection
                     options:(NSDictionary *)xoptions
{

}


- (void)sccpNDisconnectRequest:(UMSCCPConnection *)xconnection
                       options:(NSDictionary *)xoptions
{

}


- (void)sccpNDisconnectIndicaton:(UMSCCPConnection *)cxonnection
                         options:(NSDictionary *)xoptions
{

}


- (void)sccpNInform:(UMSCCPConnection *)connection
            options:(NSDictionary *)options
{

}

- (void)startUp
{

}

+ (NSString *)reasonString:(SCCP_ReturnCause)reason
{
    NSString *e;
    switch(reason)
    {
        case SCCP_ReturnCause_NoTranslationForAnAddressOfSuchNature:
            e = @"No translation for an address of such nature";
            break;
        case SCCP_ReturnCause_NoTranslationForThisSpecificAddress:
            e = @"No translation for this specific address";
            break;
        case SCCP_ReturnCause_SubsystemCongestion:
            e = @"Subsystem congestion";
            break;
        case SCCP_ReturnCause_SubsystemFailure:
            e = @"Subsystem Failure";
            break;
        case SCCP_ReturnCause_Unequipped:
            e = @"Unequipped";
            break;
        case SCCP_ReturnCause_MTPFailure:
            e = @"MTP failure";
            break;
        case SCCP_ReturnCause_NetworkCongestion:
            e = @"Network congestion";
            break;
        case SCCP_ReturnCause_Unqualified:
            e = @"Unqualified";
            break;
        case SCCP_ReturnCause_ErrorInMessageTransport:
            e = @"Error in message transport";
            break;
        case SCCP_ReturnCause_ErrorInLocalProcessing:
            e = @"Error in local processing";
            break;
        case SCCP_ReturnCause_DestinationCannotPerformReassembly:
            e = @"Destination cannot perform reassembly";
            break;
        case SCCP_ReturnCause_SCCPFailure:
            e = @"SCCP Failure";
            break;
        case SCCP_ReturnCause_HopCounterViolation:
            e = @"SCCP Hop counter violation";
            break;
        case SCCP_ReturnCause_SegmentationNotSupported:
            e = @"Segmentation not supported";
            break;
        case SCCP_ReturnCause_SegmentationFailure:
            e = @"Segmentation failure";
            break;
        default:
            e = [NSString stringWithFormat:@"Unknown SCCP error code %d",reason];
            break;
    }
    return e;
}


- (id)decodePdu:(NSData *)data /* should return a type which can be converted to json */
{
    SccpAddress *dst = NULL;
    SccpAddress *src = NULL;
    int m_protocol_class = -1;
    int m_return_cause = -1;
    int m_handling = -1;
    int m_type = -1;
    int m_hopcounter = -1;
    NSData *sccp_pdu = NULL;
    NSData *segment = NULL;
    int param_called_party_address;
    int param_calling_party_address;
    int param_data;
    int param_segment;

    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    @try
    {
        NSUInteger len = data.length;
        if(len < 6)
        {
            @throw([NSException exceptionWithName:@"SCCP_TOO_SMALL_PACKET_RECEIVED" reason:NULL userInfo:NULL] );
        }
        const uint8_t *d = data.bytes;
        int i = 0;
        int m_type = d[i++];

        switch(m_type)
        {
            case SCCP_UDT:
                m_protocol_class = d[i] & 0x0F;
                m_handling = (d[i++]>>4) & 0x0F;
                param_called_party_address = d[i] + i;
                i++;
                param_calling_party_address = d[i] + i;
                i++;
                param_data = d[i] + i;
                i++;
                param_segment = -1;
                break;

            case SCCP_UDTS:
                m_return_cause = d[i++] & 0x0F;
                param_called_party_address = d[i] + i;
                i++;
                param_calling_party_address = d[i] + i;
                i++;
                param_data      = d[i] + i;
                i++;
                param_segment   = -1;
                break;

            case SCCP_XUDT:
                m_protocol_class = d[i] & 0x0F;
                m_handling = (d[i++]>>4) & 0x0F;
                param_called_party_address = d[i] + i;
                i++;
                param_calling_party_address = d[i] + i;
                i++;
                param_data = d[i] + i;
                i++;
                param_segment = -1;
                break;

            case SCCP_XUDTS:
                m_return_cause = d[i++] & 0x0F;
                m_hopcounter = d[i++] & 0x0F;
                param_called_party_address = d[i] + i;
                i++;
                param_calling_party_address = d[i] + i;
                i++;
                param_data      = d[i] + i;
                i++;
                param_segment   = d[i] + i;
                i++;
                break;

            default:
                @throw([NSException exceptionWithName:@"SCCP_UNKNOWN_PACKET_TYPE" reason:NULL userInfo:NULL] );
        }
        if(param_called_party_address > len)
        {
            @throw([NSException exceptionWithName:@"SCCP_PTR1_POINTS_BEYOND_END" reason:NULL userInfo:NULL] );
        }

        if(param_calling_party_address > len)
        {
            @throw([NSException exceptionWithName:@"SCCP_PTR2_POINTS_BEYOND_END" reason:NULL userInfo:NULL] );
        }
        if(param_data > len)
        {
            @throw([NSException exceptionWithName:@"SCCP_PTR3_POINTS_BEYOND_END" reason:NULL userInfo:NULL] );
        }
        if((param_segment > len) && (param_segment > 0))
        {
            @throw([NSException exceptionWithName:@"SCCP_PTR4_POINTS_BEYOND_END" reason:NULL userInfo:NULL] );
        }

        NSData *dstData = NULL;
        NSData *srcData = NULL;

        if(param_called_party_address>0)
        {
            i = (int)d[param_called_party_address];
            dstData = [NSData dataWithBytes:&d[param_called_party_address+1] length:i];
            dst = [[SccpAddress alloc]initWithItuData:dstData];
        }
        if(param_calling_party_address>0)
        {
            i = (int)d[param_calling_party_address];
            srcData = [NSData dataWithBytes:&d[param_calling_party_address+1] length:i];
            src = [[SccpAddress alloc]initWithItuData:srcData];

        }
        if(param_data > 0)
        {
            i = (int)d[param_data];
            sccp_pdu = [NSData dataWithBytes:&d[param_data+1] length:i];
        }
        if(param_segment > 0)
        {
            i = (int)d[param_segment];
            segment = [NSData dataWithBytes:&d[param_segment+1] length:i];
        }

        if(src == NULL)
        {
            @throw([NSException exceptionWithName:@"SCCP_MISSING_CALLING_PARTY_ADDRESS" reason:NULL userInfo:NULL] );
        }
        if(dst==NULL)
        {
            @throw([NSException exceptionWithName:@"SCCP_MISSING_CALLED_PARTY_ADDRESS" reason:NULL userInfo:NULL] );
        }

        switch(m_type)
        {
            case SCCP_UDT:
                dict[@"pdu-type"] = @"UDT";
                break;
            case SCCP_UDTS:
                dict[@"pdu-type"] = @"UDTS";
                break;
            case SCCP_XUDT:
                dict[@"pdu-type"] = @"XUDT";
                break;
            case SCCP_XUDTS:
                dict[@"pdu-type"] = @"XUDTS";
                break;
        }
    }
    @catch(NSException *e)
    {
        dict[@"decoding-error"] = e.name;
    }
    if(dst)
    {
        dict[@"called-address"] = [dst objectValue];

    }
    if(src)
    {
        dict[@"calling-address"] = [src objectValue];
    }
    if(m_protocol_class != -1)
    {
        dict[@"protocol-class"] = @(m_protocol_class);
    }
    if(m_return_cause != -1)
    {
        dict[@"return-cause"] = @(m_return_cause);
    }
    if(m_handling != -1)
    {
        dict[@"handling"] = @(m_handling);
    }
    if(m_type != -1)
    {
        dict[@"type"] = @(m_type);
    }
    if(m_hopcounter != -1)
    {
        dict[@"hop-counter"] = @(m_hopcounter);
    }
    if(sccp_pdu)
    {
        dict[@"pdu"] = [sccp_pdu hexString];
    }
    if(segment)
    {
        dict[@"segment"] = [segment hexString];
    }
    return dict;
}

- (NSString *)status
{
    NSMutableDictionary *m = [_subsystemUsers mutableCopy];
    NSString *s = [NSString stringWithFormat:@"Routing %@",m.description];
    return s;
}


- (void)addSendTraceDestination:(id<UMSCCP_TraceProtocol>)destination
{
    [_traceSendDestinations addObject:destination];
}

- (void)addReceiveTraceDestination:(id<UMSCCP_TraceProtocol>)destination
{
    [_traceReceiveDestinations addObject:destination];
}

- (void)removeSendTraceDestination:(id<UMSCCP_TraceProtocol>)destination
{
    [_traceSendDestinations removeObject:destination];
}

- (void)removeReceiveTraceDestination:(id<UMSCCP_TraceProtocol>)destination
{
    [_traceReceiveDestinations removeObject:destination];
}

- (void)traceSentPdu:(NSData *)pdu
             options:(NSDictionary *)o
{
    NSInteger n = [_traceSendDestinations count];
    for (NSInteger i=0;i<n;i++)
    {
        id a = [_traceSendDestinations objectAtIndex:i];
        [a sccpTraceSentPdu:pdu options:o];
    }
}

- (void)traceSentPacket:(UMSCCP_Packet *)packet
                options:(NSDictionary *)o
{
}

- (void)traceReceivedPdu:(NSData *)pdu
                 options:(NSDictionary *)o
{
    NSInteger n = [_traceReceiveDestinations count];
    for (NSInteger i=0;i<n;i++)
    {
        id a = [_traceReceiveDestinations objectAtIndex:i];
        [a sccpTraceReceivedPdu:pdu options:o];
    }
}

- (void)traceReceivedPacket:(UMSCCP_Packet *)packet
                    options:(NSDictionary *)o
{
}


- (void)traceDroppedPdu:(NSData *)pdu options:(NSDictionary *)o
{
    NSInteger n = [_traceDroppedDestinations count];
    for (NSInteger i=0;i<n;i++)
    {
        id a = [_traceDroppedDestinations objectAtIndex:i];
        [a sccpTraceReceivedPdu:pdu options:o];
    }
}

- (void)traceDroppedPacket:(UMSCCP_Packet *)packet
                   options:(NSDictionary *)o
{
}

- (NSDictionary *)apiStatus
{
    NSDictionary *d = [[NSDictionary alloc]init];
    return d;
}

- (UMSynchronizedSortedDictionary *)routeStatus
{
    UMSynchronizedSortedDictionary *d = [_mtp3RoutingTable status];
    return d;
}

- (void)stopDetachAndDestroy
{
    /* FIXME: do something here */
}

- (void)addProcessingStatistic:(UMSCCP_StatisticSection)section
                  waitingDelay:(NSTimeInterval)waitingDelay
               processingDelay:(NSTimeInterval)processingDelay
{
    UMAssert( (section < UMSCCP_StatisticSection_MAX),@"unknown section");
    [_processingStats[section] addWaitingDelay:waitingDelay processingDelay:processingDelay];

}

- (void)increaseThroughputCounter:(UMSCCP_StatisticSection)section
{
    [_throughputCounters[section] increase];
}

- (UMSynchronizedSortedDictionary *)statisticalInfo
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *throughput = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *delays = [[UMSynchronizedSortedDictionary alloc]init];

    for(UMSCCP_StatisticSection i=0;i<UMSCCP_StatisticSection_MAX;i++)
    {
        NSString *key;
        switch(i)
        {
            case  UMSCCP_StatisticSection_RX:
                key = @"rx";
                break;
            case UMSCCP_StatisticSection_TX:
                key = @"tx";
                break;
            case UMSCCP_StatisticSection_TRANSIT:
                key = @"transit";
                break;

            case UMSCCP_StatisticSection_UDT_RX:
                key = @"rx-udt";
                break;

            case UMSCCP_StatisticSection_UDTS_RX:
                key = @"rx-udts";
                break;

            case UMSCCP_StatisticSection_XUDT_RX:
                key = @"rx-xudt";
                break;

            case UMSCCP_StatisticSection_XUDTS_RX:
                key = @"rx-xudts";
                break;

            case UMSCCP_StatisticSection_UDT_TX:
                key = @"tx-udt";
                break;

            case UMSCCP_StatisticSection_UDTS_TX:
                key = @"tx-udts";
                break;

            case UMSCCP_StatisticSection_XUDT_TX:
                key = @"tx-xudt";
                break;

            case UMSCCP_StatisticSection_XUDTS_TX:
                key = @"tx-xudts";
                break;

            case UMSCCP_StatisticSection_UDT_TRANSIT:
                key = @"tr-udt";
                break;

            case UMSCCP_StatisticSection_UDTS_TRANSIT:
                key = @"tr-udts";
                break;

            case UMSCCP_StatisticSection_XUDT_TRANSIT:
                key = @"tr-xudt";
                break;

            case UMSCCP_StatisticSection_XUDTS_TRANSIT:
                key = @"tr-xudts";
                break;
        }

        UMThroughputCounter *tc = _throughputCounters[i];
        UMSCCP_Statistics   *stat = _processingStats[i];

        throughput[key] = [tc getSpeedTripleJson];
        delays[key] = [stat getStatDict];
    }

    dict[@"throughput"] = throughput;
    dict[@"delays"] = delays;
    return dict;
}

- (SccpGttSelector *)parseSelectorWords:(NSArray *)words currentSelector:(SccpGttSelector *)currentSel registry:(SccpGttRegistry *)registry
{

    /* example */
    /*
     0= cs7
     1= gtt
     2= selector
     3= E164_OUT
     4= tt
     5= 0
     6= gti
     7= 4
     8= np
     9= 1
     10= nai
     11= 4
     */


    if(( (words.count > 3) &&
        ([words[0] isEqualToString:@"cs7"]) &&
        ([words[1] isEqualToString:@"gtt"]) &&
        ([words[2] isEqualToString:@"selector"])))
    {
        NSString *selectorName = words[3];
        currentSel = [registry getSelectorByName:selectorName];

        if(words.count > 7)
        {
            BOOL isNew = NO;
            if(currentSel == NULL)
            {
                currentSel = [[SccpGttSelector alloc]initWithInstanceName:_layerName];
                currentSel.name = selectorName;
                isNew = YES;
            }

            if(![words[4] isEqualToString:@"tt"])
            {
                return NULL;
            }
            currentSel.tt = [words[5] intValue];
            if(![words[6] isEqualToString:@"gti"])
            {
                return NULL;
            }
            currentSel.gti = [words[7] intValue];
            if((currentSel.gti ==4) && (words.count > 11))
            {
                if(![words[8] isEqualToString:@"np"])
                {
                    return NULL;
                }
                currentSel.np = [words[9] intValue];

                if(![words[10] isEqualToString:@"nai"])
                {
                    return NULL;
                }
                currentSel.nai = [words[11] intValue];
            }
            if(isNew)
            {
                [registry addEntry:currentSel];
            }
            else
            {
                [registry updateEntry:currentSel];
            }
        }
        return currentSel;

    }
    else if( (words.count > 1) && ([words[0] isEqualToString:@"pre-gtt-address-conversion"]))
    {
        currentSel.preTranslationName = words[1];
    }
    else if( (words.count > 1) && ([words[0] isEqualToString:@"post-gtt-address-conversion"]))
    {
        currentSel.postTranslationName = words[1];
    }
    else if( (words.count > 3) && ([words[0] isEqualToString:@"gta"]))
    {
        NSString *gta = words[1];
        NSString *destType = words[2]; /* app-grp or asname or pcssn  */
        if(([destType isEqualToString:@"app-grp"]) && (words.count > 3))
        {
            NSString *appGrpName = words[3];
            SccpGttRoutingTableEntry *entry = [[SccpGttRoutingTableEntry alloc]init];
            entry.digits = gta;
            entry.routeToName = appGrpName;
            entry.table = currentSel.name;
            entry.enabled=YES;
            entry.name =  [SccpGttRoutingTableEntry entryNameForGta:entry.digits tableName:entry.table];
            [currentSel.routingTable addEntry:entry];
        }
        else if([destType isEqualToString:@"asname"])
        {
            NSString *s =@"gta XXX asname ... is not supported yet";
            @throw([NSException exceptionWithName:@"PARSING_ERROR" reason:s userInfo:NULL]);

        }
        else if([destType isEqualToString:@"pcssn"])
        {
            NSString *s = @"gta XXX pcssn ... is not supported yet";
            @throw([NSException exceptionWithName:@"PARSING_ERROR" reason:s userInfo:NULL]);
        }
    }
    return currentSel;
}

- (SccpDestinationGroup *)parseDestinationGroupWords:(NSArray *)words currentDestinationGroup:(SccpDestinationGroup *)currentAppGrp registry:(SccpGttRegistry *)registry
{
    if(( (words.count > 3) &&
        ([words[0] isEqualToString:@"cs7"]) &&
        ([words[1] isEqualToString:@"gtt"]) &&
        ([words[2] isEqualToString:@"application-group"])))
    {
        NSString *name = words[3];
        currentAppGrp = registry.sccp_destinations_dict[name];
        if(currentAppGrp == NULL)
        {
            currentAppGrp = [[SccpDestinationGroup alloc]init];
            currentAppGrp.name = name;
            registry.sccp_destinations_dict[name] = currentAppGrp;
        }
    }
    else if( (words.count > 1) && ([words[0] isEqualToString:@"multiplicity"]))
    {
        if([words[1] isEqualToString:@"cgpa"]) /* Share based on calling party and weighting factor */
        {
            currentAppGrp.distributionMethod = SccpDestinationGroupDistributionMethod_cgpa;
        }
        else if([words[1] isEqualToString:@"cost"]) /* Use destination with least cost if available */
        {
            currentAppGrp.distributionMethod = SccpDestinationGroupDistributionMethod_cost;
        }
        else if([words[1] isEqualToString:@"share"]) /* Share equally between all destinations */
        {
            currentAppGrp.distributionMethod = SccpDestinationGroupDistributionMethod_share;
        }
        else if([words[1] isEqualToString:@"wrr"]) /* Share based on weighted round robin method*/
        {
            currentAppGrp.distributionMethod = SccpDestinationGroupDistributionMethod_wrr;
        }
    }

    else if( (words.count > 0) && ([words[0] isEqualToString:@"sccp-class1-loadbalance"]))
    {
        currentAppGrp.class1LoadBalance = YES;
    }
    else if( (words.count > 0) && ([words[0] isEqualToString:@"distribute-sccp-sequenced-negate"]))
    {
        currentAppGrp.distributeSccpSequencedNegate = YES;
    }
    else if( (words.count > 1) && ([words[0] isEqualToString:@"instance"]))
    {
        currentAppGrp.dpcInstance = words[1];
    }
    else if( (words.count > 2) && (([words[0] isEqualToString:@"pc"]) || ([words[0] isEqualToString:@"asname"])))
    {
        NSInteger k = words.count;
        NSInteger i = 2;
        NSString *pcString;
        NSString *asname;
        if([words[0] isEqualToString:@"pc"])
        {
            pcString       = words[1];
        }
        else
        {
            asname       = words[1];
        }
        NSNumber *cost = NULL;
        NSString *ssnString  = NULL;
        NSString *weightString = NULL;
        BOOL usePcssn = NO;
        NSString *nttString = NULL;
        BOOL allowXUDTconversion = NO;

        /* allowed syntaxes

         pc 1-1-1 ssn <ssn = 0,2...255> <cost> gt
         pc 1-1-1 { ssn <ssn = 0,2...255> } <cost> gt ntt <0...255>
         pc 1-1-1 { ssn <ssn = 0,2...255> } <cost> pcssn {sccp-allow-pak-conv} weight {number}
         */
        while(i<k)
        {
            NSString *w = words[i];
            NSInteger iv = [w integerValue];
            if(([w isEqualToString:@"ssn"]) && ((i+1) <k ))
            {
                ssnString = words[i+1];
                i = i+1;
            }
            else if([w isEqualToString:@"gt"])
            {
                usePcssn = NO;
            }
            else if([w isEqualToString:@"pcssn"])
            {
                usePcssn = YES;
            }
            else if( ([w isEqualToString:@"ntt"]) && ((i+1) <k) )
            {
                nttString  = words[i+1];
                i = i+1;
            }
            else if( ([w isEqualToString:@"weight"]) && ((i+1) <k) )
            {
                weightString = words[i+1];
                i = i+1;
            }
            else if([w isEqualToString:@"sccp-allow-pak-conv"])
            {
                allowXUDTconversion = YES;
            }
            else if((iv>0) && (iv<=64))
            {
                cost = @(iv);
            }
            else
            {
                NSLog(@"Can't understand %@",words);
            }
            i++;
        }

        SccpDestination *e = [[SccpDestination alloc]init];

        e.dpc = [[UMMTP3PointCode alloc]initWithString:pcString variant:_mtp3.variant];
        if(cost)
        {
            e.cost = cost;
        }
        else
        {
            e.cost = @(5);
        }
        if(ssnString)
        {
            e.ssn = [[SccpSubSystemNumber alloc]initWithName:ssnString];
        }
        if(nttString)
        {
            e.ntt = @([nttString integerValue]);
        }
        if(weightString)
        {
            e.weight = @([weightString doubleValue]);
        }
        else
        {
            e.weight = @(100.0);
        }
        if(asname)
        {
            e.m3uaAs = asname;
        }
        e.usePcssn = usePcssn;
        if(allowXUDTconversion)
        {
            e.allowConversion = @(YES);
        }
        [currentAppGrp addEntry:e];
    }
    return currentAppGrp;
}

- (SccpNumberTranslation *)parseAddressConversionWords:(NSArray *)words currentAddressConversion:(SccpNumberTranslation *)currentAddrConv registry:(SccpGttRegistry *)registry
{
    if(( (words.count > 3) &&
        ([words[0] isEqualToString:@"cs7"]) &&
        ([words[1] isEqualToString:@"gtt"]) &&
        ([words[2] isEqualToString:@"address-conversion"])))
    {
        NSString *name = words[3];
        currentAddrConv = registry.sccp_number_translations_dict[name];
        if(currentAddrConv == NULL)
        {
            currentAddrConv = [[SccpNumberTranslation alloc]init];
            currentAddrConv.name = name;
            registry.sccp_number_translations_dict[name] = currentAddrConv;
        }
    }

    else if( (words.count > 10) && ([words[0] isEqualToString:@"update"]))
    {
        NSInteger k = words.count;
        NSInteger i = 1;
        NSString *inAddress = NULL;
        NSString *outAddress = NULL;
        NSNumber *np = NULL;
        NSNumber *nai = NULL;
        NSNumber *remove = NULL;

        while(i<k)
        {
            if(([words[i] isEqualToString:@"in-address"]) && ((i+1) <k ))
            {
                inAddress = words[i+1];
                i = i+1;
            }
            else if(([words[i] isEqualToString:@"out-address"]) && ((i+1) <k ))
            {
                outAddress = words[i+1];
                i = i+1;
            }
            else if(([words[i] isEqualToString:@"np"]) && ((i+1) <k ))
            {
                NSString *s  = words[i+1];
                np = @( [s integerValue]);
                i = i+1;
            }
            else if(([words[i] isEqualToString:@"nai"]) && ((i+1) <k ))
            {
                NSString *s  = words[i+1];
                nai = @( [s integerValue]);
                i = i+1;
            }
            else if(([words[i] isEqualToString:@"remove"]) && ((i+1) <k ))
            {
                NSString *s  = words[i+1];
                nai = @( [s integerValue]);
                i = i+1;
            }
            else
            {
                NSString *s = [NSString stringWithFormat:@"Can't parse words: %@",words];
                @throw([NSException exceptionWithName:@"PARSING_ERROR" reason:s userInfo:NULL]);
            }
            i++;
        }

        if(inAddress)
        {
            SccpNumberTranslationEntry *e = [[SccpNumberTranslationEntry alloc]init];
            e.inAddress = inAddress;
            e.outAddress = outAddress;
            e.replacementNP = np;
            e.replacementNAI =nai;
            e.removeDigits = remove;
            [currentAddrConv addEntry:e];
        }
    }
    return currentAddrConv;
}

- (void)readFromGtFile:(NSString *)fn
{
    @try
    {
        BOOL errIgnore = NO;
        NSError *err = NULL;

        NSString *fullPath  = [fn stringByStandardizingPath];
        NSString *filename  = [fullPath lastPathComponent];
        NSString *newPath   = [fullPath stringByDeletingLastPathComponent];
        NSString *oldPath   = [[NSFileManager defaultManager] currentDirectoryPath];

        SccpGttRegistry *registry = [[SccpGttRegistry alloc]init];
        registry.logLevel = self.logLevel;
        registry.logFeed = self.logFeed;

        SccpGtFileSection currentSection = SccpGtFileSection_root;

        SccpGttSelector *currentSel = NULL;
        SccpDestinationGroup *currentDestGrp = NULL;
        SccpNumberTranslation *currentAddrConv = NULL;

#ifdef LINUX
        chdir([newPath UTF8String]);
#else
        [[NSFileManager defaultManager] changeCurrentDirectoryPath:newPath];
#endif
        NSString *configFile = [NSString stringWithContentsOfFile:filename
                                                         encoding:NSUTF8StringEncoding
                                                            error:&err];

        if(err)
        {
            NSString *s = [NSString stringWithFormat:@"Can not read file %@. Error %@",fn,err];
            if(errIgnore == YES)
            {
                NSLog(@"%@",s);
            }
            else
            {
                @throw([NSException exceptionWithName:@"config"
                                               reason:s
                                             userInfo:@{@"backtrace": UMBacktrace(NULL,0) }]);
            }
        }

        NSCharacterSet *ws = [UMObject whitespaceAndNewlineCharacterSet];
        NSInteger includeStatementsCount = 0;
        NSArray *lines = [configFile componentsSeparatedByString:@"\n"];
        //NSMutableArray *config = [[NSMutableArray alloc]init];
        do
        {
            includeStatementsCount = 0;
            NSMutableArray *lines2 = [[NSMutableArray alloc]init];
            for (NSString *line1 in lines)
            {
                NSString *line = [line1 stringByTrimmingCharactersInSet:ws];
                NSArray *words = [line componentsSeparatedByCharactersInSet:ws];
                /* remove empty words */
                NSMutableArray *words2 = [[NSMutableArray alloc]init];
                for(NSString *word in words)
                {
                    if(word.length > 0)
                    {
                        [words2 addObject:word];
                    }
                }

                if((words.count==2) && ([words[0]isEqualToString:@"include"]))
                {
                    includeStatementsCount++;
                    NSString *includeFileName = words[1];
                    NSString *includedFile = [NSString stringWithContentsOfFile:includeFileName
                                                                       encoding:NSUTF8StringEncoding
                                                                          error:&err];
                    if(err)
                    {
                        NSString *s = [NSString stringWithFormat:@"Can not read file %@. Error %@",fn,err];
                        if(errIgnore == YES)
                        {
                            NSLog(@"%@",s);
                        }
                        else
                        {
                            @throw([NSException exceptionWithName:@"config"
                                                           reason:s
                                                         userInfo:@{@"backtrace": UMBacktrace(NULL,0) }]);
                        }
                    }
                    NSArray *includedLines = [includedFile componentsSeparatedByString:@"\n"];
                    for(NSString *includedLine in includedLines)
                    {
                        [lines2 addObject:includedLine];
                    }
                }
                else
                {
                    [lines2 addObject:line];
                }

            }
            lines = lines2;
        } while(includeStatementsCount > 0);

#ifdef LINUX
        chdir([oldPath UTF8String]);
#else
        [[NSFileManager defaultManager] changeCurrentDirectoryPath:oldPath];
#endif

        long linenumber = 0;
        for (NSString *line1 in lines)
        {
            NSString *line = [line1 stringByTrimmingCharactersInSet:ws];
            linenumber++;

            NSArray *words = [line componentsSeparatedByCharactersInSet:ws];
            /* remove empty words */
            NSMutableArray *words2 = [[NSMutableArray alloc]init];
            for(NSString *word in words)
            {
                if(word.length > 0)
                {
                    [words2 addObject:word];
                }
            }
            words = words2;

            if(words.count == 0) /* empty line */
            {
                continue;
            }

            if([words[0] isEqualToString:@"!"]) /* a comment line */
            {
                continue;
            }
            if([words[0] isEqualToString:@"exit"])
            {
                currentSection = SccpGtFileSection_root;
                currentSel = NULL;
                currentDestGrp = NULL;
                currentAddrConv = NULL;
            }
            else if((currentSection == SccpGtFileSection_selector) ||
                    ( (words.count > 3) &&
                     ([words[0] isEqualToString:@"cs7"]) &&
                     ([words[1] isEqualToString:@"gtt"]) &&
                     ([words[2] isEqualToString:@"selector"])))
            {
                currentSel = [self parseSelectorWords:words currentSelector:currentSel registry:registry];
                if(currentSel)
                {
                    currentSection = SccpGtFileSection_selector;
                }
                else
                {
                    currentSection = SccpGtFileSection_root;
                }
            }
            else if((currentSection == SccpGtFileSection_application_group) ||
                    ( (words.count > 3) &&
                     ([words[0] isEqualToString:@"cs7"]) &&
                     ([words[1] isEqualToString:@"gtt"]) &&
                     ([words[2] isEqualToString:@"application-group"])))
            {
                currentDestGrp = [self parseDestinationGroupWords:words currentDestinationGroup:currentDestGrp registry:registry];
                if(currentDestGrp)
                {
                    currentSection = SccpGtFileSection_application_group;
                }
                else
                {
                    currentSection = SccpGtFileSection_root;
                }
            }
            else if((currentSection == SccpGtFileSection_address_conversion) ||
                    ( (words.count > 3) &&
                     ([words[0] isEqualToString:@"cs7"]) &&
                     ([words[1] isEqualToString:@"gtt"]) &&
                     ([words[2] isEqualToString:@"address-conversion"])))
            {

                currentAddrConv = [self parseAddressConversionWords:words currentAddressConversion:currentAddrConv registry:registry];
                if(currentAddrConv)
                {
                    currentSection = SccpGtFileSection_address_conversion;
                }
                else
                {
                    currentSection = SccpGtFileSection_root;
                }
            }
            else
            {
                NSString *s = [NSString stringWithFormat:@"Can not parse line %ld from file %@: %@",linenumber,filename,line];
                @throw([NSException exceptionWithName:@"PARSING_ERROR" reason:s userInfo:NULL]);
            }
        }
        [registry finishUpdate];
        _gttSelectorRegistry = registry;
    }
    @catch(NSException *e)
    {
        NSString *s = [NSString stringWithFormat:@"Exception while reading file: %@\n%@",fn,e];
        [self logMajorError:s];
    }
}

@end



