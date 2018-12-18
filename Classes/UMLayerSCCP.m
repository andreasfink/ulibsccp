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
    for(int i=0;i<UMSCCP_StatisticSection_MAX;i++)
    {
        _processingStats[i] = [[UMSCCP_Statistics alloc] init];
        _throughputCounters[i] = [[UMThroughputCounter alloc] init];
    }
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
                       handling:(int)handling
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
                handling:(int)handling
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
              returnCause:(int)returnCause
                 hopCount:(int)hopCounter
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


- (void)findRoute:(SccpAddress **)dst1
       causeValue:(int *)cause
        localUser:(id<UMSCCP_UserProtocol> *)user
        pointCode:(UMMTP3PointCode **)pc
        fromLocal:(BOOL)isLocal
{
    SccpAddress *dst = [*dst1 copy];
    
    if(_stpMode==NO)
    {
        /* simple mode */
        if((!_next_pc1) && (!_next_pc2))
        {
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"no next pointcode set in SSP mode. Dropping packet for %@",dst.debugDescription]];
        }
        else
        {
            if(isLocal)
            {
                int pick_random = [UMUtil randomFrom:1 to:2];

                /* packet from upper layer going out to next_pc */
                SccpL3RoutingTableEntry *rtentry1 = [_mtp3RoutingTable getEntryForPointCode:_next_pc1];
                SccpL3RoutingTableEntry *rtentry2 = [_mtp3RoutingTable getEntryForPointCode:_next_pc2];
                if((rtentry1.status==SccpL3RouteStatus_available) && (rtentry2.status==SccpL3RouteStatus_available))
                {
                    if(pick_random==1)
                    {
                        *pc = _next_pc1;
                    }
                    else
                    {
                        *pc = _next_pc2;
                    }
                }
                else if((rtentry1.status==SccpL3RouteStatus_available) && (rtentry2.status!=SccpL3RouteStatus_available))
                {
                    *pc = _next_pc1;
                }
                else if((rtentry1.status!=SccpL3RouteStatus_available) && (rtentry2.status==SccpL3RouteStatus_available))
                {
                    *pc = _next_pc2;
                }
                else if((rtentry1.status==SccpL3RouteStatus_restricted) && (rtentry2.status==SccpL3RouteStatus_restricted))
                {
                    if(pick_random==1)
                    {
                        *pc = _next_pc1;
                    }
                    else
                    {
                        *pc = _next_pc2;
                    }
                }
                else if((rtentry1.status==SccpL3RouteStatus_restricted) && (rtentry2.status==SccpL3RouteStatus_unavailable))
                {
                    *pc = _next_pc1;
                }
                else if((rtentry1.status==SccpL3RouteStatus_unavailable) && (rtentry2.status==SccpL3RouteStatus_restricted))
                {
                    *pc = _next_pc2;
                }
                else
                {
                    *cause = SCCP_ReturnCause_MTPFailure;
                }
            }
            else
            {
                /* packet from lower layer going up to subsystem */
                id<UMSCCP_UserProtocol> upperLayer = [self getUserForSubsystem:dst.ssn number:dst];
                if(upperLayer == NULL)
                {
                    [self.logFeed majorErrorText:[NSString stringWithFormat:@"no upper layer found for %@ ssn=%d number=%@",dst.debugDescription,(int)dst.ssn,dst.stringValueE164]];
                    *cause = SCCP_ReturnCause_Unequipped;
                }
                else
                {
                    *user = upperLayer;
                }
            }
        }
    }
    else /* STP mode */
    {
        if(dst.ai.routingIndicatorBit == ROUTE_BY_GLOBAL_TITLE)
        {
            if(logLevel <=UMLOG_DEBUG)
            {
                [self.logFeed debugText:@" Route by global title"];
            }

            SccpGttRegistry *registry = self.gttSelectorRegistry;
            SccpGttSelector *selector = [registry selectorForInstance:self.layerName
                                                                   tt:dst.tt.tt
                                                                  gti:dst.ai.globalTitleIndicator
                                                                   np:dst.npi.npi
                                                                  nai:dst.nai.nai];
            if(selector == NULL)
            {
                /* we send a UDTS back as we have no forward route */
                if(logLevel <=UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@" SCCP selector is null for tt=%d, gti=%d, np:%d nai:%d. Returning NoTranslationForThisSpecificAddress" ,dst.tt.tt,dst.ai.globalTitleIndicator,dst.npi.npi,dst.nai.nai]];
                }
                *cause = SCCP_ReturnCause_NoTranslationForThisSpecificAddress;
            }
            else
            {
                /* this call takes care of the pre/post translation */
                SccpDestination *destination = [selector chooseNextHopWithL3RoutingTable:self.mtp3RoutingTable
                                                                             destination:&dst];
                if(destination==NULL)
                {
                    if(logLevel <=UMLOG_DEBUG)
                    {
                        [self.logFeed debugText:@" GTT SCCP selector returns no nextHop. Returning NoTranslationForThisSpecificAddress"];
                    }

                    *cause = SCCP_ReturnCause_NoTranslationForThisSpecificAddress;
                }
                else
                {
                    if(logLevel <=UMLOG_DEBUG)
                    {
                        [self.logFeed debugText:[NSString stringWithFormat:@" Route to SCCP destination %@",destination]];
                    }


                    if(destination.ssn)
                    {
                        if(logLevel <=UMLOG_DEBUG)
                        {
                            [self.logFeed debugText:[NSString stringWithFormat:@" GTT SCCP selector returns SSN=%@",destination.ssn]];
                        }
                        /* routed by subsystem */
                        id<UMSCCP_UserProtocol> upperLayer = [self getUserForSubsystem:dst.ssn number:dst];
                        if(upperLayer == NULL)
                        {
                            [self.logFeed majorErrorText:[NSString stringWithFormat:@"no upper layer found for %@",dst.debugDescription]];

                            if(logLevel <=UMLOG_DEBUG)
                            {
                                [self.logFeed debugText:[NSString stringWithFormat:@" SSN %@ is unequipped",destination.ssn]];
                            }
                            *cause = SCCP_ReturnCause_Unequipped;
                        }
                        else
                        {
                            *user = upperLayer;
                        }
                    }
                    else if(destination.dpc)
                    {
                        if(logLevel <=UMLOG_DEBUG)
                        {
                            [self.logFeed debugText:[NSString stringWithFormat:@" next hop DPC= %@", destination.dpc]];
                        }
                        *pc =destination.dpc;
                    }
                    else if(destination.m3uaAs)
                    {
                        /* not yet implemented */
                        if(logLevel <=UMLOG_DEBUG)
                        {
                            [self.logFeed debugText:[NSString stringWithFormat:@" next hopM3UAAS= %@", destination.m3uaAs]];
                        }
                        *cause = SCCP_ReturnCause_ErrorInLocalProcessing;
                    }
                }
            }
        }
        else /* ROUTE_BY_SUBSYSTEM */
        {
            /* routed by subsystem */
            if(logLevel <=UMLOG_DEBUG)
            {
                [self.logFeed debugText:@" Route by subsystem"];
            }

            id<UMSCCP_UserProtocol> upperLayer = [self getUserForSubsystem:dst.ssn number:dst];
            if(upperLayer == NULL)
            {
                [self.logFeed majorErrorText:[NSString stringWithFormat:@"no upper layer found for %@",dst.debugDescription]];
                *cause = SCCP_ReturnCause_Unequipped;
            }
            else
            {
                if(logLevel <=UMLOG_DEBUG)
                {
                    [self.logFeed debugText:@" Route to upper layer"];
                }
                *user = upperLayer;
            }
        }
    }
    if((_ntt) && (isLocal))
    {
        dst.tt = [_ntt copy];
    }
    *dst1 = dst;
}


- (BOOL) routeUDT:(NSData *)data /* returns true if processed locally, false if transited */
          calling:(SccpAddress *)src
           called:(SccpAddress *)dst
            class:(SCCP_ServiceClass)pclass
         handling:(int)handling
              opc:(UMMTP3PointCode *)opc
              dpc:(UMMTP3PointCode *)dpc
          options:(NSDictionary *)options
         provider:(UMLayerMTP3 *)provider
        fromLocal:(BOOL)fromLocal
{
    BOOL returnValue = NO;
    int causeValue = -1;
    id<UMSCCP_UserProtocol> localUser =NULL;
    UMMTP3PointCode *pc = NULL;
    if(logLevel <=UMLOG_DEBUG)
    {
        NSString *s = [NSString stringWithFormat:@"calling findRoute (DST=%@,local=%d,pc=%@) dpc=%@",dst,fromLocal,pc,dpc];
        [self.logFeed debugText:s];
    }

    /* predefined routing */
    if((dpc) && (provider) && (fromLocal))
    {
        pc = dpc;
    }
    else
    {
        provider = _mtp3;

        if(logLevel <=UMLOG_DEBUG)
        {
            NSString *s = [NSString stringWithFormat:@"calling findRoute (DST=%@,local=%d,pc=%@)",dst,fromLocal,pc];
            [self.logFeed debugText:s];
        }
        [self findRoute:&dst
             causeValue:&causeValue
              localUser:&localUser
              pointCode:&pc
              fromLocal:fromLocal];

        if(logLevel <=UMLOG_DEBUG)
        {
            NSString *s = [NSString stringWithFormat:@"findRoute (DST=%@,local=%d) returns causeValue=%d, localUser=%@, pc=%@",dst,fromLocal,causeValue,localUser,pc];
            [self.logFeed debugText:s];
        }
    }

    if(pc)
    {
        UMMTP3_Error e = [self sendUDT:data
                               calling:src
                                called:dst
                                 class:pclass
                              handling:handling
                                   opc:_mtp3.opc
                                   dpc:pc
                               options:options
                              provider:provider];
        NSString *s= NULL;
        switch(e)
        {
            case UMMTP3_no_error:
                break;
            case UMMTP3_error_pdu_too_big:
                s = [NSString stringWithFormat:@"Can not forward UDT. PDU too big. SRC=%@ DST=%@ DATA=%@",src,dst,data];
                break;
            case UMMTP3_error_no_route_to_destination:
                s = [NSString stringWithFormat:@"Can not forward UDT. No route to destination PC=%@. SRC=%@ DST=%@ DATA=%@",pc,src,dst,data];
                break;
            case UMMTP3_error_invalid_variant:
                s = [NSString stringWithFormat:@"Can not forward UDT. Invalid variant. SRC=%@ DST=%@ DATA=%@",src,dst,data];
                break;
        }
        if(s)
        {
            [self logMinorError:s];
        }
        if(handling & UMSCCP_HANDLING_RETURN_ON_ERROR)
        {
            switch(e)
            {
                case UMMTP3_error_no_route_to_destination:
                    [self sendUDTS:data
                           calling:src
                            called:dst
                            reason:SCCP_ReturnCause_MTPFailure
                               opc:_mtp3.opc
                               dpc:opc
                           options:@{}
                          provider:_mtp3];
                    break;
                case UMMTP3_error_pdu_too_big:
                    [self sendUDTS:data
                           calling:src
                            called:dst
                            reason:SCCP_ReturnCause_ErrorInMessageTransport
                               opc:_mtp3.opc
                               dpc:opc
                           options:@{}
                          provider:provider];

                    break;
                case UMMTP3_error_invalid_variant:
                    [self sendUDTS:data
                           calling:src
                            called:dst
                            reason:SCCP_ReturnCause_ErrorInLocalProcessing
                               opc:_mtp3.opc
                               dpc:opc
                           options:@{}
                          provider:provider];
                    break;
                default:
                    break;
            }
        }
    }
    else if(localUser)
    {
        [localUser sccpNUnitdata:data
                    callingLayer:self
                         calling:src
                          called:dst
                qualityOfService:0
                           class:pclass
                        handling:handling
                         options:options];
        returnValue = YES;
    }
    else
    {
        causeValue = SCCP_ReturnCause_Unequipped;
        [self logMinorError:[NSString stringWithFormat:@"[1] Can not route UDT. Cause %d SRC=%@ DST=%@ DATA=%@",causeValue,src,dst,data]];
        if(handling & UMSCCP_HANDLING_RETURN_ON_ERROR)
        {
            [self sendUDTS:data
                   calling:src
                    called:dst
                    reason:causeValue
                       opc:_mtp3.opc
                       dpc:opc
                   options:@{}
                  provider:_mtp3];
        }
    }
    return returnValue;
}

- (BOOL) routeUDTS:(NSData *)data /* returns true if processed locally, false if transited */
           calling:(SccpAddress *)src
            called:(SccpAddress *)dst
            reason:(int)reasonCode
               opc:(UMMTP3PointCode *)opc
               dpc:(UMMTP3PointCode *)dpc
           options:(NSDictionary *)options
          provider:(UMLayerMTP3 *)provider
         fromLocal:(BOOL)fromLocal
{
    BOOL returnValue = NO;
    id<UMSCCP_UserProtocol> localUser =NULL;
    UMMTP3PointCode *pc = NULL;

    if((dpc) && (provider) && (fromLocal)) /* only from layer above, we can do a force route. otherwise we would loop to self */
    {
        pc = dpc;
    }
    else
    {
        int causeValue = -1;
        id<UMSCCP_UserProtocol> localUser =NULL;
        UMMTP3PointCode *pc = NULL;
        provider = _mtp3;

        if(logLevel <=UMLOG_DEBUG)
        {
            NSString *s = [NSString stringWithFormat:@"calling findRoute (DST=%@,local=%d,pc=%@)",dst,fromLocal,pc];
            [self.logFeed debugText:s];
        }

        [self findRoute:&dst
             causeValue:&causeValue
              localUser:&localUser
              pointCode:&pc
              fromLocal:fromLocal];

        if(logLevel <=UMLOG_DEBUG)
        {
            NSString *s = [NSString stringWithFormat:@"findRoute (DST=%@,local=%d) returns causeValue=%d, localUser=%@, pc=%@",dst,fromLocal,causeValue,localUser,pc];
            [self.logFeed debugText:s];
        }
    }

    if(pc)
    {
        UMMTP3_Error e = [self sendUDTS:data
                                calling:src
                                 called:dst
                                 reason:reasonCode
                                    opc:_mtp3.opc
                                    dpc:pc
                                options:options
                               provider:provider];

        NSString *s = NULL;
        switch(e)
        {
            case UMMTP3_no_error:
                break;
           case UMMTP3_error_pdu_too_big:
                s = [NSString stringWithFormat:@"Can not forward UDTS. PDU too big. Dropping PDU. SRC=%@ DST=%@ REASON=%d DATA=%@",src,dst,reasonCode,data];
                break;
            case UMMTP3_error_no_route_to_destination:
                s = [NSString stringWithFormat:@"Can not forward UDTS. No route to destination. Dropping PDU.  SRC=%@ DST=%@ REASON=%d DATA=%@",src,dst,reasonCode,data];
                break;
            case UMMTP3_error_invalid_variant:
                s = [NSString stringWithFormat:@"Can not forward UDTS. Invalid variant. Dropping PDU. SRC=%@ DST=%@ REASON=%d DATA=%@",src,dst,reasonCode,data];
                break;
        }
        if(s)
        {
            [self logMinorError:s];
        }
    }
    else if(localUser)
    {
        [localUser sccpNNotice:data
                  callingLayer:self
                       calling:src
                        called:dst
                        reason:reasonCode
                       options:options];
        returnValue = YES;
    }
    else
    {
        [self logMinorError:[NSString stringWithFormat:@"[2] Can not route UDTS %@->%@ Reason=%d %@",src,dst,reasonCode,data]];
    }

    return returnValue;
}

- (BOOL) routeXUDT:(NSData *)data /* returns true if processed locally, false if transited */
           calling:(SccpAddress *)src
            called:(SccpAddress *)dst
             class:(SCCP_ServiceClass)pclass
          handling:(int)handling
          hopCount:(int)hopCount
               opc:(UMMTP3PointCode *)opc
               dpc:(UMMTP3PointCode *)dpc
       optionsData:(NSData *)xoptionsdata
           options:(NSDictionary *)options
          provider:(UMLayerMTP3 *)provider
         fromLocal:(BOOL)fromLocal
{
    BOOL returnValue = NO;

    int causeValue = -1;

    id<UMSCCP_UserProtocol> localUser =NULL;
    UMMTP3PointCode *pc = NULL;

    hopCount--;
    if(hopCount < 0)
    {
        causeValue = SCCP_ReturnCause_HopCounterViolation;
    }
    else
    {
        /* predefined routing */
        if((dpc) && (provider) && (fromLocal)) /* only from layer above, we can do a force route. otherwise we would loop to self */
        {
            pc = dpc;
        }
        else
        {
            int causeValue = -1;
            id<UMSCCP_UserProtocol> localUser =NULL;
            UMMTP3PointCode *pc = NULL;
            provider = _mtp3;
            [self findRoute:&dst
                 causeValue:&causeValue
                  localUser:&localUser
                  pointCode:&pc
                  fromLocal:fromLocal];
        }
        if(pc)
        {
            UMMTP3_Error e = [self sendXUDT:data
                                    calling:src
                                     called:dst
                                      class:pclass   /* MGMT is class 0 */
                                   handling:handling
                                   hopCount:hopCount
                                        opc:_mtp3.opc
                                        dpc:pc
                                optionsData:xoptionsdata
                                    options:options
                                   provider:provider];
            NSString *s = NULL;
            switch(e)
            {
                case UMMTP3_no_error:
                    break;
                case UMMTP3_error_pdu_too_big:
                    s = [NSString stringWithFormat:@"Can not forward XUDT. PDU too big. SRC=%@ DST=%@ DATA=%@",src,dst,data];
                    causeValue = SCCP_ReturnCause_ErrorInMessageTransport;
                    break;
                case UMMTP3_error_no_route_to_destination:
                    s = [NSString stringWithFormat:@"Can not forward XUDT. No route to destination. SRC=%@ DST=%@ DATA=%@",src,dst,data];
                    causeValue = SCCP_ReturnCause_NoTranslationForThisSpecificAddress;
                    
                    break;
                case UMMTP3_error_invalid_variant:
                    s = [NSString stringWithFormat:@"Can not forward XUDT. Invalid variant. SRC=%@ DST=%@ DATA=%@",src,dst,data];
                    causeValue = SCCP_ReturnCause_NoTranslationForAnAddressOfSuchNature;
                    break;
            }
            if(s)
            {
                [self logMinorError:s];
            }
            if(handling & UMSCCP_HANDLING_RETURN_ON_ERROR)
            {
                switch(e)
                {
                    case UMMTP3_error_no_route_to_destination:
                        causeValue = SCCP_ReturnCause_MTPFailure;
                        break;
                    case UMMTP3_error_pdu_too_big:
                        causeValue = SCCP_ReturnCause_ErrorInMessageTransport;
                        break;
                    case UMMTP3_error_invalid_variant:
                        causeValue = SCCP_ReturnCause_ErrorInLocalProcessing;
                        break;
                    default:
                        break;
                }
            }
        }
        else if(localUser)
        {
            [localUser sccpNUnitdata:data
                        callingLayer:self
                             calling:src
                              called:dst
                    qualityOfService:0
                               class:pclass
                            handling:handling
                             options:options];
            returnValue = YES;
        }
        else
        {
            causeValue = SCCP_ReturnCause_Unequipped;
        }
    }
    if(causeValue != -1)
    {
        [self logMinorError:[NSString stringWithFormat:@"Can not route XUDT. Cause=%d SRC=%@ DST=%@ DATA=%@",causeValue,src,dst,data]];
        if(handling & UMSCCP_HANDLING_RETURN_ON_ERROR)
        {
            [self sendXUDTS:data
                    calling:src
                     called:dst
                returnCause:causeValue
                   hopCount:_xudts_max_hop_count
                        opc:_mtp3.opc
                        dpc:opc
                optionsData:xoptionsdata
                    options:@{}
                   provider:provider];
        }
    }
    return returnValue;
}


-(BOOL) routeXUDTsegment:(UMSCCP_Segment *)segment /* returns true if processed locally, false if transited */
                 calling:(SccpAddress *)src
                  called:(SccpAddress *)dst
                   class:(SCCP_ServiceClass)pclass
                handling:(int)handling
                hopCount:(int)hopCount
                     opc:(UMMTP3PointCode *)opc
                     dpc:(UMMTP3PointCode *)dpc
             optionsData:(NSData *)xoptionsdata
                 options:(NSDictionary *)options
                provider:(UMLayerMTP3 *)provider
               fromLocal:(BOOL)fromLocal
{
    BOOL returnValue = NO;
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
    returnValue = [self routeXUDT:segment.data
                          calling:src
                           called:dst
                            class:pclass
                         handling:handling
                         hopCount:hopCount
                              opc:opc
                              dpc:dpc
                      optionsData:optionsData
                          options:options
                         provider:provider
                        fromLocal:fromLocal];
    return returnValue;
}

- (BOOL) routeXUDTS:(NSData *)data  /* returns true if processed locally, false if transited */
            calling:(SccpAddress *)src
             called:(SccpAddress *)dst
             reason:(int)reasonCode
           hopCount:(int)hopCount
                opc:(UMMTP3PointCode *)opc
                dpc:(UMMTP3PointCode *)dpc
        optionsData:(NSData *)xoptionsdata
            options:(NSDictionary *)options
           provider:(UMLayerMTP3 *)provider
          fromLocal:(BOOL)fromLocal;
{
    BOOL returnValue = NO;
    id<UMSCCP_UserProtocol> localUser =NULL;
    UMMTP3PointCode *pc = NULL;

    hopCount--;
    if(hopCount < 0)
    {
        [self logMinorError:[NSString stringWithFormat:@"Dropping XUDT to maxhopcount reached SRC=%@ DST=%@ DATA=%@",src,dst,data]];
        return returnValue;
    }

    if((dpc) && (provider))
    {
        pc = dpc;
    }

    else
    {
        int causeValue = -1;
        id<UMSCCP_UserProtocol> localUser =NULL;
        UMMTP3PointCode *pc = NULL;
        provider = _mtp3;
        [self findRoute:&dst
             causeValue:&causeValue
              localUser:&localUser
              pointCode:&pc
              fromLocal:fromLocal];

    }

    if(pc)
    {
        UMMTP3_Error e = [self sendXUDTS:data
                                calling:src
                                 called:dst
                            returnCause:reasonCode
                               hopCount:hopCount
                                    opc:_mtp3.opc
                                    dpc:pc
                             optionsData:xoptionsdata
                                options:options
                               provider:provider];
        NSString *s = NULL;
        switch(e)
        {
            case UMMTP3_no_error:
                break;
            case UMMTP3_error_pdu_too_big:
                s = [NSString stringWithFormat:@"Can not forward UDTS. PDU too big. Dropping PDU. SRC=%@ DST=%@ REASON=%d DATA=%@",src,dst,reasonCode,data];
                break;
            case UMMTP3_error_no_route_to_destination:
                s = [NSString stringWithFormat:@"Can not forward UDTS. No route to destination. Dropping PDU.  SRC=%@ DST=%@ REASON=%d DATA=%@",src,dst,reasonCode,data];
                break;
            case UMMTP3_error_invalid_variant:
                s = [NSString stringWithFormat:@"Can not forward UDTS. Invalid variant. Dropping PDU. SRC=%@ DST=%@ REASON=%d DATA=%@",src,dst,reasonCode,data];
                break;
        }
        if(s)
        {
            [self logMinorError:s];
        }
    }
    else if(localUser)
    {
        /* FIXME: we should do reassembly here before delivering to upper layer */
        [localUser sccpNNotice:data
                  callingLayer:self
                       calling:src
                        called:dst
                        reason:reasonCode
                       options:options];
        returnValue= YES;
    }
    else
    {
        [self logMinorError:[NSString stringWithFormat:@"[3] Can not route UDTS %@->%@ Reason=%d %@",src,dst,reasonCode,data]];
    }
    return returnValue;
}

- (UMMTP3_Error) sendUDT:(NSData *)data
                 calling:(SccpAddress *)src
                  called:(SccpAddress *)dst
                   class:(SCCP_ServiceClass)pclass   /* MGMT is class 0 */
                handling:(int)handling
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
    header[1] = (pclass & 0x0F) | (( handling & 0xF)<<4);
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
            if(logLevel <= UMLOG_DEBUG)
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
                   reason:(int)reasonCode
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
            if(logLevel <= UMLOG_DEBUG)
            {
                [self.logFeed debugText:[NSString stringWithFormat:@"sendPDU to %@: %@->%@ success",_mtp3.layerName, opc,dpc]];
            }
            break;
        default:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"sendPDU %@: %@->%@ returns unknown error %d",_mtp3.layerName,opc,dpc,result]];

    }
    return result;
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
            NSString *s = [NSString stringWithFormat:@"Can not find mtp3 layer '%@' referred from sccp '%@'",_mtp3_name,layerName];
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

    NSString *s = cfg[@"next-pc"];
    if(s.length > 0)
    {
        _next_pc1 = [[UMMTP3PointCode alloc]initWithString:s variant:_mtp3.variant];
        _next_pc2 = [[UMMTP3PointCode alloc]initWithString:s variant:_mtp3.variant];
    }
    s = cfg[@"next-pc1"];
    if(s.length > 0)
    {
        _next_pc1 = [[UMMTP3PointCode alloc]initWithString:s variant:_mtp3.variant];
    }
    s = cfg[@"next-pc2"];
    if(s.length > 0)
    {
        _next_pc2 = [[UMMTP3PointCode alloc]initWithString:s variant:_mtp3.variant];
    }
    NSNumber *n = cfg[@"ntt"];
    if(n)
    {
        _ntt = [[SccpTranslationTableNumber alloc]initWithInt:[n intValue]];
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
            handling:(int)handling
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
        
        int m_handling;
        int param_called_party_address;
        int param_calling_party_address;
        int param_data;
        int param_segment;
        
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

- (void)traceSentPdu:(NSData *)pdu options:(NSDictionary *)o
{
    NSInteger n = [_traceSendDestinations count];
    for (NSInteger i=0;i<n;i++)
    {
        id a = [_traceSendDestinations objectAtIndex:i];
        [a sccpTraceSentPdu:pdu options:o];
    }
}

- (void)traceReceivedPdu:(NSData *)pdu options:(NSDictionary *)o
{
    NSInteger n = [_traceReceiveDestinations count];
    for (NSInteger i=0;i<n;i++)
    {
        id a = [_traceReceiveDestinations objectAtIndex:i];
        [a sccpTraceReceivedPdu:pdu options:o];
    }
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
- (NSDictionary *)apiStatus
{
    NSDictionary *d = [[NSDictionary alloc]init];
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



@end

