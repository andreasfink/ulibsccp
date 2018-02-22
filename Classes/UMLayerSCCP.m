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
#import "UMSCCP_MTP3RoutingTable.h"

@implementation UMLayerSCCP

@synthesize sccpVariant;
@synthesize allProviders;
@synthesize defaultNextHop;
@synthesize defaultProvider;
@synthesize gttSelectorRegistry;
@synthesize attachTo;
@synthesize attachedTo;
@synthesize pendingSegments;

-(UMMTP3Variant) variant
{
    return mtp3.variant;
}

- (UMLayerMTP3 *)mtp3
{
    return mtp3;
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
    self = [super initWithTaskQueueMulti:tq];
    if(self)
    {
        [self genericInitialisation];
    }
    return self;
}

- (void)genericInitialisation
{
    allProviders = [[UMSynchronizedDictionary alloc]init];
    subsystemUsers = [[UMSynchronizedDictionary alloc]init];
    dpcAvailability = [[UMSynchronizedDictionary alloc]init];
    pendingSegments  = [[NSMutableDictionary alloc]init];
    traceSendDestinations =[[UMSynchronizedArray alloc]init];
    traceReceiveDestinations =[[UMSynchronizedArray alloc]init];
    traceDroppedDestinations =[[UMSynchronizedArray alloc]init];
    _routingTable = [[UMSCCP_MTP3RoutingTable alloc]init];
}

- (void)mtpTransfer:(NSData *)data
       callingLayer:(id)mtp3Layer
                opc:(UMMTP3PointCode *)opc
                dpc:(UMMTP3PointCode *)dpc
                 si:(int)si
                 ni:(int)ni
        linksetName:(NSString *)linksetName
            options:(NSDictionary *)options
{
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
    NSMutableDictionary *a = subsystemUsers[@(subsystem)];
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
    a = subsystemUsers[@(0)];
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
    NSMutableDictionary *a = subsystemUsers[@(ssn.ssn)];
    if(a==NULL)
    {
        a = [[NSMutableDictionary alloc]init];
    }
    a[sccpAddress.address] = usr;
    subsystemUsers[@(subsystem)] = a;
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
                          class:(int)class_and_handling
                    maxHopCount:(int)maxHopCount
                  returnOnError:(BOOL)reterr
                            opc:(UMMTP3PointCode *)opc
                            dpc:(UMMTP3PointCode *)dpc
                    optionsData:(NSData *)xoptionsdata
                        options:(NSDictionary *)options
                       provider:(SccpL3Provider *)provider
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
    NSData *srcEncoded = [src encode:sccpVariant];
    NSData *dstEncoded = [dst encode:sccpVariant];
    if(reterr)
    {
        class_and_handling = class_and_handling | 0x80;
    }
    NSMutableData *sccp_pdu = [[NSMutableData alloc]init];
    uint8_t header[7];
    header[0] = SCCP_XUDT;
    header[1] = class_and_handling;
    header[2] = maxHopCount;
    header[3] = 4;
    header[4] = 4 + dstEncoded.length;
    header[5] = 4 + dstEncoded.length + srcEncoded.length;
    header[6] = 4 + dstEncoded.length + srcEncoded.length + segment.data.length;
    
    [sccp_pdu appendBytes:header length:7];
    [sccp_pdu appendByte:dstEncoded.length];
    [sccp_pdu appendData:dstEncoded];
    [sccp_pdu appendByte:srcEncoded.length];
    [sccp_pdu appendData:srcEncoded];
    [sccp_pdu appendByte:segment.data.length];
    [sccp_pdu appendData:segment.data];
    //[sccp_pdu appendByte:optionsData.length];
    [sccp_pdu appendData:optionsData];
    
    id <UMSCCP_TraceProtocol> u = options[@"sccp-trace-tx-destination"];
    [u sccpTraceSentPdu:sccp_pdu options:options];

    NSInteger n = [traceSendDestinations count];
    for (NSInteger i=0;i<n;i++)
    {
        id a = [traceSendDestinations objectAtIndex:i];
        NSMutableDictionary *o = [[NSMutableDictionary alloc]init];
        o[@"type"]=@"XUDT-Segment";
        o[@"opc"]=opc.stringValue;
        o[@"dpc"]=dpc.stringValue;
        o[@"provider"]=provider.name;
        o[@"mtp3"]=provider.mtp3Layer.layerName;
        [a sccpTraceSentPdu:sccp_pdu options:o];
    }
    UMMTP3_Error result = [provider sendPDU:sccp_pdu opc:opc dpc:dpc];
    return result;
}


-(UMMTP3_Error) sendXUDTdata:(NSData *)data
                     calling:(SccpAddress *)src
                      called:(SccpAddress *)dst
                       class:(int)class_and_handling
                 maxHopCount:(int)maxHopCount
               returnOnError:(BOOL)reterr
                         opc:(UMMTP3PointCode *)opc
                         dpc:(UMMTP3PointCode *)dpc
                 optionsData:(NSData *)xoptionsdata
                     options:(NSDictionary *)options
                    provider:(SccpL3Provider *)provider
{
    NSData *srcEncoded = [src encode:sccpVariant];
    NSData *dstEncoded = [dst encode:sccpVariant];
    
    if(reterr)
    {
        class_and_handling = class_and_handling | 0x80;
    }
    NSMutableData *sccp_pdu = [[NSMutableData alloc]init];
    uint8_t header[7];
    header[0] = SCCP_XUDT;
    header[1] = class_and_handling;
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
    id <UMSCCP_TraceProtocol> u = options[@"sccp-trace-tx-destination"];
    [u sccpTraceSentPdu:sccp_pdu options:options];


    NSInteger n = [traceSendDestinations count];
    for (NSInteger i=0;i<n;i++)
    {
        id a = [traceSendDestinations objectAtIndex:i];
        NSMutableDictionary *o = [[NSMutableDictionary alloc]init];
        o[@"type"]=@"XUDT-Data";
        o[@"opc"]=opc.stringValue;
        o[@"dpc"]=dpc.stringValue;
        o[@"provider"]=provider.name;
        o[@"mtp3"]=provider.mtp3Layer.layerName;
        [a sccpTraceSentPdu:sccp_pdu options:o];
    }

    UMMTP3_Error result = [provider sendPDU:sccp_pdu opc:opc dpc:dpc];
    return result;
}

- (UMMTP3_Error) sendUDT:(NSData *)data
                calling:(SccpAddress *)src
                 called:(SccpAddress *)dst
                  class:(int)class_and_handling   /* MGMT is class 0 */
          returnOnError:(BOOL)reterr
                    opc:(UMMTP3PointCode *)opc
                    dpc:(UMMTP3PointCode *)dpc
                options:(NSDictionary *)options
               provider:(SccpL3Provider *)provider
{
    NSData *srcEncoded = [src encode:sccpVariant];
    NSData *dstEncoded = [dst encode:sccpVariant];
    
    if(reterr)
    {
        class_and_handling = class_and_handling | 0x80;
    }
    NSMutableData *sccp_pdu = [[NSMutableData alloc]init];
    uint8_t header[5];
    header[0] = SCCP_UDT;
    header[1] = class_and_handling;
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
    
    id <UMSCCP_TraceProtocol> u = options[@"sccp-trace-tx-destination"];
    [u sccpTraceSentPdu:sccp_pdu options:options];

    NSInteger n = [traceSendDestinations count];
    for (NSInteger i=0;i<n;i++)
    {
        id a = [traceSendDestinations objectAtIndex:i];
        NSMutableDictionary *o = [[NSMutableDictionary alloc]init];
        o[@"type"]=@"UDT";
        if(opc)
        {
            o[@"opc"]=opc.stringValue;
        }
        else
        {
            o[@"opc"]=@"(not-set)";
        }
        if(dpc)
        {
            o[@"dpc"]=dpc.stringValue;
        }
        else
        {
            o[@"dpc"]=@"(not-set)";
        }
        if(provider)
        {
            o[@"provider"]=provider.name;
            if(provider.mtp3Layer)
            {
                o[@"mtp3"]=provider.mtp3Layer.layerName;
            }
            else
            {
                o[@"mtp3"]=@"(not-set)";
            }
        }
        else
        {
            o[@"provider"]=@"(not-set)";
        }
        [a sccpTraceSentPdu:sccp_pdu options:o];
    }

    UMMTP3_Error result = [provider sendPDU:sccp_pdu opc:opc dpc:dpc];
    
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
                [self.logFeed debugText:[NSString stringWithFormat:@"sendPDU to %@: %@->%@ success",provider.name, opc,dpc]];
            }
            break;
        default:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"sendPDU %@: %@->%@ returns unknown error %d",provider.name,opc,dpc,result]];

    }
    return result;
}

- (NSUInteger)maxPayloadSizeForServiceType:(SCCP_ServiceType) serviceType
                        callingAddressSize:(NSUInteger)cas
                         calledAddressSize:(NSUInteger)cds
                             usingSegments:(BOOL)useSeg
                                  provider:(SccpL3Provider *)provider
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
        mtp3_name =  [cfg[@"attach-to"] stringValue];
        mtp3 = [appContext getMTP3:mtp3_name];
        if(mtp3 == NULL)
        {
            NSString *s = [NSString stringWithFormat:@"Can not find mtp3 layer '%@' referred from sccp '%@'",mtp3_name,layerName];
            @throw([NSException exceptionWithName:[NSString stringWithFormat:@"CONFIG_ERROR FILE %s line:%ld",__FILE__,(long)__LINE__]
                                           reason:s
                                         userInfo:NULL]);
        }
        [mtp3 setUserPart:MTP3_SERVICE_INDICATOR_SCCP user:self];
        self.attachedTo = mtp3;
    }
    if(cfg[@"variant"])
    {
        NSString *v = [cfg[@"variant"] stringValue];
        if([v isEqualToString:@"itu"])
        {
            sccpVariant = SCCP_VARIANT_ITU;
        }
        if([v isEqualToString:@"ansi"])
        {
            sccpVariant = SCCP_VARIANT_ANSI;
        }
        else
        {
            sccpVariant = SCCP_VARIANT_ITU;
        }
    }
}

- (NSDictionary *)config
{
    NSMutableDictionary *cfg = [[NSMutableDictionary alloc]init];
    [self addLayerConfig:cfg];
    
    cfg[@"attach-to"] = attachTo;
    
    if(sccpVariant==SCCP_VARIANT_ITU)
    {
        cfg[@"variant"] = @"itu";
    }
    else if(sccpVariant==SCCP_VARIANT_ANSI)
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
    [logFeed majorErrorText:@"sccpNDataRequest: not implemented"];
}

- (void)sccpNExpeditedData:(NSData *)data
                connection:(UMSCCPConnection *)connection
                   options:(NSDictionary *)options
               synchronous:(BOOL)sync
{
    [logFeed majorErrorText:@"sccpNExpeditedData: not implemented"];
}

- (void)sccpNResetRequest:(UMSCCPConnection *)connection
                  options:(NSDictionary *)options
              synchronous:(BOOL)sync
{
    [logFeed majorErrorText:@"sccpNResetRequest: not implemented"];
}


- (void)sccpNResetIndication:(UMSCCPConnection *)connection
                     options:(NSDictionary *)options
                 synchronous:(BOOL)sync
{
    [logFeed majorErrorText:@"sccpNResetIndication: not implemented"];
}


- (void)sccpNDisconnectRequest:(UMSCCPConnection *)connection
                       options:(NSDictionary *)options
                   synchronous:(BOOL)sync
{
    [logFeed majorErrorText:@"sccpNDisconnectRequest: not implemented"];
}


- (void)sccpNDisconnectIndicaton:(UMSCCPConnection *)connection
                         options:(NSDictionary *)options
                     synchronous:(BOOL)sync
{
    [logFeed majorErrorText:@"sccpNDisconnectIndicaton: not implemented"];
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
             options:(NSDictionary *)options
{
    UMSCCP_sccpNUnitdata *task;
    task = [[UMSCCP_sccpNUnitdata alloc]initForSccp:self
                                               user:userLayer
                                           userData:data
                                            calling:src
                                             called:dst
                                   qualityOfService:qos
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
    NSMutableDictionary *m = [subsystemUsers mutableCopy];
    NSString *s = [NSString stringWithFormat:@"Routing %@",m.description];
    return s;
}


- (void)addSendTraceDestination:(id<UMSCCP_TraceProtocol>)destination
{
    [traceSendDestinations addObject:destination];
}

- (void)addReceiveTraceDestination:(id<UMSCCP_TraceProtocol>)destination
{
    [traceReceiveDestinations addObject:destination];
}

- (void)removeSendTraceDestination:(id<UMSCCP_TraceProtocol>)destination
{
    [traceSendDestinations removeObject:destination];
}

- (void)removeReceiveTraceDestination:(id<UMSCCP_TraceProtocol>)destination
{
    [traceReceiveDestinations removeObject:destination];
}

- (void)traceSentPdu:(NSData *)pdu options:(NSDictionary *)o
{
    NSInteger n = [traceSendDestinations count];
    for (NSInteger i=0;i<n;i++)
    {
        id a = [traceSendDestinations objectAtIndex:i];
        [a sccpTraceSentPdu:pdu options:o];
    }
}

- (void)traceReceivedPdu:(NSData *)pdu options:(NSDictionary *)o
{
    NSInteger n = [traceReceiveDestinations count];
    for (NSInteger i=0;i<n;i++)
    {
        id a = [traceReceiveDestinations objectAtIndex:i];
        [a sccpTraceReceivedPdu:pdu options:o];
    }
}

- (void)traceDroppedPdu:(NSData *)pdu options:(NSDictionary *)o
{
    NSInteger n = [traceDroppedDestinations count];
    for (NSInteger i=0;i<n;i++)
    {
        id a = [traceDroppedDestinations objectAtIndex:i];
        [a sccpTraceReceivedPdu:pdu options:o];
    }
}
@end
