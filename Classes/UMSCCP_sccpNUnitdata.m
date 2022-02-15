//
//  UMSCCP_sccpNUnitdata.m
//  ulibsccp
//
//  Created by Andreas Fink on 31.03.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMSCCP_sccpNUnitdata.h"
#import <ulibmtp3/ulibmtp3.h>
#import <ulibgt/ulibgt.h>
#import "UMLayerSCCP.h"
#import "UMSCCP_StatisticSection.h"
#import "UMSCCP_Packet.h"
#import "UMSCCP_PrometheusData.h"

static int segmentReferenceId;

@implementation UMSCCP_sccpNUnitdata

- (UMSCCP_sccpNUnitdata *)initForSccp:(UMLayerSCCP *)sccp
                                 user:(id<UMSCCP_UserProtocol>)xuser
                             userData:(NSData *)xdata
                              calling:(SccpAddress *)xsrc
                               called:(SccpAddress *)xdst
                     qualityOfService:(int)xqos
                                class:(SCCP_ServiceClass)pclass
                             handling:(SCCP_Handling)handling
                              options:(NSDictionary *)xoptions
{
    self = [super initWithName:@"UMSCCP_sccpNUnitdata"
                      receiver:sccp
                        sender:xuser
       requiresSynchronisation:NO];
    if(self)
    {
        _created = [NSDate date];
        _sccpLayer = sccp;
        _sccpUser = xuser;
        _data = xdata;
        _src = xsrc;
        _dst = xdst;
        _options = xoptions;
        _qos = xqos;
        _maxHopCount = 255;
        _protocolClass = pclass;
        _handling = handling;
        _statisticsSection = UMSCCP_StatisticSection_TX;
        _statisticsSection2 = UMSCCP_StatisticSection_UDT_TX;
    }
    return self;
}
 
- (UMSCCP_sccpNUnitdata *)initForSccp:(UMLayerSCCP *)sccp
                                 user:(id<UMSCCP_UserProtocol>)xuser
                     userDataSegments:(NSArray *)xdataSegments
                              calling:(SccpAddress *)xsrc
                               called:(SccpAddress *)xdst
                     qualityOfService:(int)xqos
                                class:(SCCP_ServiceClass)pclass
                             handling:(SCCP_Handling)handling
                              options:(NSDictionary *)xoptions;
{
    self = [super initWithName:@"UMSCCP_sccpNUnitdata"
                      receiver:sccp
                        sender:xuser
       requiresSynchronisation:NO];
    if(self)
    {
        _created = [NSDate date];
        _sccpLayer = sccp;
        _sccpUser = xuser;
        _dataSegments = [xdataSegments mutableCopy];
        _src = xsrc;
        _dst = xdst;
        _options = xoptions;
        _qos = xqos;
        _protocolClass = pclass;
        _handling = handling;
        if(_options)
        {
            NSString *s = _options[@"hop-counter"];
            if(s)
            {
                _maxHopCount = [s intValue] -1;
            }
        }
        else
        {
            _maxHopCount = 15;
        }
    }
    return self;
}


- (void)main
{
    @autoreleasepool
    {
        @try
        {
            /* int cls =0;*/
            _startOfProcessing = [NSDate date];

            UMMTP3PointCode         *xopc = _sccpLayer.mtp3.opc;
            UMMTP3PointCode         *xdpc = _nextHop.dpc;

            NSString *xopc_string = _options[@"opc"];
            NSString *xdpc_string = _options[@"dpc"];
            if((xdpc_string.length > 0) && (![xdpc_string isEqualToString:@"default"]))
            {
                xdpc = [[UMMTP3PointCode alloc] initWithString:xdpc_string
                                                       variant:_sccpLayer.mtp3.variant];
            }
            if((xopc_string.length > 0) && (![xopc_string isEqualToString:@"default"]))
            {
                xopc = [[UMMTP3PointCode alloc] initWithString:xopc_string
                                                       variant:_sccpLayer.mtp3.variant];
            }
            NSData *srcEncoded = [_src encode:_sccpLayer.sccpVariant];
            NSData *dstEncoded = [_dst encode:_sccpLayer.sccpVariant];
            NSUInteger cas = srcEncoded.length;
            NSUInteger cds = dstEncoded.length;
            NSUInteger maxPdu = 0;
            //BOOL useUDT         = [_options[@"sccp-udt"] boolValue];
            BOOL useXUDT        = [_options[@"sccp-xudt"] boolValue];
            //BOOL useLUDT        = [_options[@"sccp-ludt"] boolValue];
            BOOL useSegments    = [_options[@"sccp-segment"] boolValue];
            int segmentSize    = [_options[@"sccp-segment-size"] intValue];
            NSArray *segmentSizes =  _options[@"sccp-segment-sizes"];

            NSDictionary *sccp_options = _options[@"sccp-optional"];
            NSMutableData *optional_data;
            if(sccp_options)
            {
                optional_data = [[NSMutableData alloc]init];
                NSArray *keys = [sccp_options allKeys];
                int paramType;
                for(NSString *key in keys)
                {
                    if([key isEqualToString:@"destination-local-reference"])
                    {
                        paramType = 0x01;
                    }
                    else if([key isEqualToString:@"source-local-reference"])
                    {
                        paramType = 0x02;
                    }
                    else if([key isEqualToString:@"called-party-address"])
                    {
                        paramType = 0x03;
                    }
                    else if([key isEqualToString:@"calling-party-address"])
                    {
                        paramType = 0x04;
                    }
                    else if([key isEqualToString:@"protocol-class"])
                    {
                        paramType = 0x05;
                    }
                    else if([key isEqualToString:@"segmenting-reassembling"])
                    {
                        paramType = 0x06;
                    }
                    else if([key isEqualToString:@"receive-sequence-number"])
                    {
                        paramType = 0x07;
                    }
                    else if([key isEqualToString:@"sequencing-segmenting"])
                    {
                        paramType = 0x08;
                    }
                    else if([key isEqualToString:@"credit"])
                    {
                        paramType = 0x09;
                    }
                    else if([key isEqualToString:@"release-cause"])
                    {
                        paramType = 0x0a;
                    }
                    else if([key isEqualToString:@"return-cause"])
                    {
                        paramType = 0x0b;
                    }
                    else if([key isEqualToString:@"reset-cause"])
                    {
                        paramType = 0x0c;
                    }
                    else if([key isEqualToString:@"error-cause"])
                    {
                        paramType = 0x0d;
                    }
                    else if([key isEqualToString:@"refusal-cause"])
                    {
                        paramType = 0x0e;
                    }
                    else if([key isEqualToString:@"data"])
                    {
                        paramType = 0x0f;
                    }
                    else if([key isEqualToString:@"segmentation"])
                    {
                        paramType = 0x10;
                    }
                    else if([key isEqualToString:@"hop-counter"])
                    {
                        paramType = 0x11;
                    }
                    else if([key isEqualToString:@"importance"])
                    {
                        paramType = 0x12;
                    }
                    else if([key isEqualToString:@"long-data"])
                    {
                        paramType = 0x13;
                    }
                    uint8_t header[2];
                    NSData *d = sccp_options[key];
                    header[0] = paramType;
                    header[1] = d.length & 0xFF;
                    [optional_data appendBytes:&header[0] length:2];
                    [optional_data appendData:d];
                }
                if(optional_data.length>0)
                {
                    useXUDT = YES;
                }
            }

            if(_data.length > 0)
            {
                /* we have single data as input, no segments yet */
                if(useXUDT == NO)
                {
                    maxPdu = [_sccpLayer maxPayloadSizeForServiceType:SCCP_UDT
                                                   callingAddressSize:cas
                                                    calledAddressSize:cds
                                                        usingSegments:useSegments
                                                             provider:_sccpLayer.mtp3];
                    if((segmentSize !=0) && (segmentSize<maxPdu))
                    {
                        maxPdu = segmentSize;
                    }

                    if(_data.length > maxPdu)
                    {
                        /* no choice, we must segment */
                        useSegments=YES;
                        useXUDT = YES;
                        maxPdu = [_sccpLayer maxPayloadSizeForServiceType:SCCP_XUDT
                                                       callingAddressSize:cas
                                                        calledAddressSize:cds
                                                            usingSegments:YES
                                                                 provider:_sccpLayer.mtp3];
                        if((segmentSize !=0) && (segmentSize<maxPdu))
                        {
                            maxPdu = segmentSize;
                        }
                    }
                }
                else /* use XUDT is set */
                {
                    maxPdu = [_sccpLayer maxPayloadSizeForServiceType:SCCP_XUDT
                                                   callingAddressSize:cas
                                                    calledAddressSize:cds
                                                        usingSegments:useSegments
                                                             provider:_sccpLayer.mtp3];
                    if((segmentSize !=0) && (maxPdu>segmentSize))
                    {
                        maxPdu = segmentSize;
                    }
                    if(_data.length > maxPdu)
                    {
                        /* no choice, we must segment */
                        useSegments = YES;
                        useXUDT = YES;
                        maxPdu = [_sccpLayer maxPayloadSizeForServiceType:SCCP_XUDT
                                                       callingAddressSize:cas
                                                        calledAddressSize:cds
                                                            usingSegments:useSegments
                                                                 provider:_sccpLayer.mtp3];
                        if((segmentSize !=0) && (maxPdu>segmentSize))
                        {
                            maxPdu = segmentSize;
                        }
                    }
                }
                if(useSegments) /* we want or must use segments. we prepare it only here */
                {
                    int ref;
                    @synchronized(self)
                    {
                        segmentReferenceId = segmentReferenceId + 1;
                        segmentReferenceId = segmentReferenceId % 0xFFFFFF;
                        ref = segmentReferenceId;
                    }

                    _dataSegments  = [self splitDataIntoSegments:_data
                                                withSegmentSizes:segmentSizes
                                                       reference:ref
                                                          maxPdu:maxPdu];
                    NSUInteger count = _dataSegments.count;
                    _data = NULL;
                    for(int i=0;i<count;i++)
                    {
                        UMSCCP_Segment *s = _dataSegments[i];

                        UMSCCP_Packet *packet = [[UMSCCP_Packet alloc]init];
                        packet.sccp = _sccpLayer;
                        packet.logFeed = _sccpLayer.logFeed;
                        packet.logLevel = _sccpLayer.logLevel;
                        packet.incomingMtp3Layer = _sccpLayer.mtp3;
                        packet.incomingCallingPartyAddress = _src;
                        packet.incomingCalledPartyAddress = _dst;
                        packet.incomingCallingPartyCountry = [_src country];
                        packet.incomingCalledPartyCountry = [_dst country];
                        packet.incomingCallingPartyCountry = [packet.incomingCallingPartyAddress country];
                        packet.incomingCalledPartyCountry = [packet.incomingCalledPartyAddress country];
                        packet.incomingServiceClass = _protocolClass;
                        packet.incomingHandling = _handling;
                        packet.incomingSccpData = s.data;
                        packet.incomingSegment = s;
                        packet.incomingOptions = _options;
                        packet.incomingMaxHopCount = _maxHopCount;
                        packet.incomingOptionalData = optional_data;
                        packet.incomingServiceType = SCCP_XUDT;
                        packet.incomingFromLocal = YES;
                        [_sccpLayer.filterDelegate sccpDecodeTcapGsmmap:packet];
                        _statisticsSection2 = UMSCCP_StatisticSection_XUDT_TX;
                        [packet copyIncomingToOutgoing];
                        UMSCCP_FilterResult r = UMSCCP_FILTER_RESULT_UNMODIFIED;
                        if(_sccpLayer.filterDelegate)
                        {
                            r =  [_sccpLayer.filterDelegate filterFromLocalSubsystem:packet];
                        }
                        if(r  & UMSCCP_FILTER_RESULT_DROP)
                        {
                            [_sccpLayer.logFeed debugText:@"fromLocalFilter returns DROP"];
                            return;
                        }
                        [_sccpLayer routePacket:packet];
                    }
                }
                else /* we have pure data only */
                {
                    UMSCCP_Packet *packet = [[UMSCCP_Packet alloc]init];
                    packet.sccp = _sccpLayer;
                    packet.logFeed = _sccpLayer.logFeed;
                    packet.logLevel = _sccpLayer.logLevel;
                    packet.incomingMtp3Layer = _sccpLayer.mtp3;
                    packet.incomingCallingPartyAddress = _src;
                    packet.incomingCalledPartyAddress = _dst;
                    packet.incomingCallingPartyCountry = [packet.incomingCallingPartyAddress country];
                    packet.incomingCalledPartyCountry = [packet.incomingCalledPartyAddress country];
                    packet.incomingServiceClass = _protocolClass;
                    packet.incomingHandling = _handling;
                    packet.incomingSccpData = _data;
                    packet.incomingOptions = _options;
                    packet.incomingMaxHopCount = _maxHopCount;
                    packet.incomingOptionalData = optional_data;
                    packet.incomingFromLocal = YES;
                    if(useXUDT)
                    {
                        packet.incomingServiceType = SCCP_XUDT;
                        _statisticsSection2 = UMSCCP_StatisticSection_XUDT_TX;
                    }
                    else
                    {
                        packet.incomingServiceType = SCCP_UDT;
                        _statisticsSection2 = UMSCCP_StatisticSection_UDT_TX;
                    }
                    [packet copyIncomingToOutgoing];
                    UMSCCP_FilterResult r = UMSCCP_FILTER_RESULT_UNMODIFIED;
                    if(_sccpLayer.filterDelegate)
                    {
                        r =  [_sccpLayer.filterDelegate filterFromLocalSubsystem:packet];
                    }
                    if(r & UMSCCP_FILTER_RESULT_DROP)
                    {
                        [_sccpLayer.logFeed debugText:@"fromLocalFilter returns DROP"];
                        return;
                    }
                    [_sccpLayer routePacket:packet];
                    
                    
                    if(_sccpLayer.statisticDb)
                    {
                        NSString *callingPrefix = packet.incomingCallingPartyAddress.address;
                        NSString *calledPrefix = packet.incomingCalledPartyAddress.address;

                        if(packet.incomingCallingPartyAddress.npi.npi == SCCP_NPI_ISDN_MOBILE_E214)
                        {
                            callingPrefix =  [_sccpLayer.statisticDb e214prefixOf:packet.incomingCallingPartyAddress.address];
                        }
                        else if(packet.incomingCallingPartyAddress.npi.npi == SCCP_NPI_LAND_MOBILE_E212)
                        {
                            callingPrefix =  [_sccpLayer.statisticDb e212prefixOf:packet.incomingCallingPartyAddress.address];

                        }
                        else
                        {
                            callingPrefix =  [_sccpLayer.statisticDb e164prefixOf:packet.incomingCallingPartyAddress.address];
                        }

                        
                        if(packet.incomingCalledPartyAddress.npi.npi == SCCP_NPI_ISDN_MOBILE_E214)
                        {
                            calledPrefix =  [_sccpLayer.statisticDb e214prefixOf:packet.incomingCalledPartyAddress.address];
                        }
                        else if(packet.incomingCalledPartyAddress.npi.npi == SCCP_NPI_LAND_MOBILE_E212)
                        {
                            calledPrefix =  [_sccpLayer.statisticDb e212prefixOf:packet.incomingCalledPartyAddress.address];

                        }
                        else
                        {
                            calledPrefix =  [_sccpLayer.statisticDb e164prefixOf:packet.incomingCalledPartyAddress.address];
                        }

                        NSString *gttSelector=packet.routingSelector;
                        NSString *incomingLinkset = @"local";
                        NSString *outgoingLinkset = packet.outgoingLinkset;
                        if(packet.outgoingToLocal)
                        {
                            outgoingLinkset=@"local";
                        }
                        [_sccpLayer.statisticDb addByteCount:(int)packet.outgoingSccpData.length
                                             incomingLinkset:incomingLinkset
                                             outgoingLinkset:outgoingLinkset
                                               callingPrefix:callingPrefix
                                                calledPrefix:calledPrefix
                                                 gttSelector:gttSelector
                                               sccpOperation:packet.incomingServiceType
                                           incomingPointCode:(int)packet.incomingOpc.integerValue
                                           outgoingPointCode:(int)packet.outgoingDpc.integerValue
                                                 destination:packet.outgoingDestination];
                        [_sccpLayer.prometheusData increaseMapCounter:UMSCCP_StatisticSection_TX operations:packet.incomingGsmMapOperations];
                    }
                }
            }
        }
        @catch(NSException *ex)
        {
            [_sccpLayer.logFeed majorErrorText:[NSString stringWithFormat:@"Error: %@",ex]];
        }
        _endOfProcessing = [NSDate date];
        [_sccpLayer addProcessingStatistic:_statisticsSection
                              waitingDelay:[_startOfProcessing timeIntervalSinceDate:_created]
                           processingDelay:[_endOfProcessing timeIntervalSinceDate:_startOfProcessing]];
        [_sccpLayer addProcessingStatistic:_statisticsSection2
                              waitingDelay:[_startOfProcessing timeIntervalSinceDate:_created]
                           processingDelay:[_endOfProcessing timeIntervalSinceDate:_startOfProcessing]];
        [_sccpLayer increaseThroughputCounter:_statisticsSection];
        [_sccpLayer increaseThroughputCounter:_statisticsSection2];
    }
}

- (NSArray <UMSCCP_Segment *>*)splitDataIntoSegments:(NSData *)data withSegmentSizes:(NSArray<NSNumber *>*)segmentSizes reference:(long)ref maxPdu:(NSUInteger)maxPdu
{
    BOOL debug =( _sccpLayer.logLevel <=UMLOG_DEBUG);
    if(debug)
    {
        NSMutableString *s = [[NSMutableString alloc]init];
        [s appendFormat:@"Entering splitDataIntoSegments: %@\n",[data hexString]];
        [s appendFormat:@"\twithSegmentSizes: {"];
        for(int i=0;i<segmentSizes.count;i++)
        {
            NSNumber *num = segmentSizes[i];
            int n = [num intValue];
            if(i>0)
            {
                [s appendFormat:@", %d",n];
            }
            else
            {
                [s appendFormat:@"%d", n];
            }
        }
        [s appendFormat:@"}\n"];
        [s appendFormat:@"\treference:%ld\n",ref];
        [s appendFormat:@"\tmaxPdu:%ld\n",(long)maxPdu];
        [_sccpLayer logDebug:s];
    }
    NSMutableArray<UMSCCP_Segment *> *segments = [[NSMutableArray alloc]init];

    NSData *remainingData = [data copy];
    
    NSUInteger remainingLength = remainingData.length;
    NSUInteger index=0;
    while(remainingLength > 0)
    {
        NSUInteger currentLength = maxPdu;
        if((segmentSizes!=NULL) && (segmentSizes.count < index))
        {
            NSNumber *n = segmentSizes[index];
            currentLength = [n intValue];
            if(currentLength > maxPdu)
            {
                currentLength = maxPdu;
            }
        }
        else if((segmentSizes!=NULL) && (segmentSizes.count>0))
        {
            NSNumber *n = segmentSizes[segmentSizes.count -1];
            currentLength = [n intValue];
            if(currentLength > maxPdu)
            {
                currentLength = maxPdu;
            }
        }
        else
        {
            currentLength = maxPdu;
        }
        if(currentLength > remainingLength)
        {
            currentLength = remainingLength;
        }
        UMSCCP_Segment *currentSegment = [[UMSCCP_Segment alloc]init];
        if(index==0)
        {
            currentSegment.first = YES;
        }
        else
        {
            currentSegment.first = NO;
        }
        currentSegment.class1 = (_protocolClass == SCCP_CLASS_INSEQ_CL);
        currentSegment.reference = ref;
        currentSegment.data = [NSData dataWithBytes:remainingData.bytes length:currentLength];
        [segments addObject:currentSegment];
    
        remainingData = [NSData dataWithBytes:&remainingData.bytes[currentLength] length:(remainingLength - currentLength)];
        remainingLength = remainingData.length;
        index++;
    }
    
    for(int i=0;i<segments.count;i++)
    {
        UMSCCP_Segment *s = segments[i];
        s.remainingSegment = (int)segments.count - i - 1;
        s.segmentIndex = i;
    }

    if(debug)
    {
        NSMutableString *s = [[NSMutableString alloc]init];
        [s appendFormat:@"returning segments:\n"];
        for(int i=0;i<segments.count;i++)
        {
            UMSCCP_Segment *seg = segments[i];
            [s appendFormat:@"\t%@\n",seg.description];
        }
        [_sccpLayer logDebug:s];
    }
    return segments;
}
@end
