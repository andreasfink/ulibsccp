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

static int segmentReferenceId;

@implementation UMSCCP_sccpNUnitdata

- (UMSCCP_sccpNUnitdata *)initForSccp:(UMLayerSCCP *)sccp
                                 user:(id<UMSCCP_UserProtocol>)xuser
                             userData:(NSData *)xdata
                              calling:(SccpAddress *)xsrc
                               called:(SccpAddress *)xdst
                     qualityOfService:(int)xqos
                                class:(SCCP_ServiceClass)pclass
                             handling:(int)handling
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
                             handling:(int)handling
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

        BOOL useXUDT        = [_options[@"sccp-xudt"] boolValue];
        BOOL useSegments    = [_options[@"sccp-segment"] boolValue];

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
                [optional_data appendByte:0x00]; /* end of parameter */
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

                }
            }
            else
            {
                maxPdu = [_sccpLayer maxPayloadSizeForServiceType:SCCP_XUDT
                                               callingAddressSize:cas
                                                calledAddressSize:cds
                                                    usingSegments:useSegments
                                                         provider:_sccpLayer.mtp3];

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

                _dataSegments = [[NSMutableArray alloc]init];
                UMSCCP_Segment *segment = [[UMSCCP_Segment alloc]init];
                segment.first = YES;
                segment.class1 = YES;
                segmentReferenceId = ref;

                const uint8_t *bytes = _data.bytes;
                NSUInteger n = _data.length;
                NSUInteger p = 0;
                while(p < n)
                {
                    NSUInteger m;
                    if((n - p) > maxPdu)
                    {
                        m = maxPdu;
                    }
                    else
                    {
                        m = (n-p);
                    }
                    segment.data = [NSData dataWithBytes:&bytes[p] length:m];
                    [_dataSegments addObject:segment];

                    segment = [[UMSCCP_Segment alloc]init];
                    segment.first = NO;
                    segment.class1 = YES;
                    segmentReferenceId = ref;
                    p = p + m;
                }
                NSUInteger count = _dataSegments.count;
                for(int i=0;i<count;i++)
                {
                    UMSCCP_Segment *s = [_dataSegments objectAtIndex:(NSUInteger)i];
                    s.remainingSegment = (int)count - i -1;
                }
                _data = NULL;
                for(int i=0;i<count;i++)
                {
                    UMSCCP_Segment *s = [_dataSegments objectAtIndex:(NSUInteger)i];
                    s.remainingSegment = (int)count - i -1;

                    UMSCCP_Packet *packet = [[UMSCCP_Packet alloc]init];
                    packet.incomingMtp3Layer = _sccpLayer.mtp3;
                    packet.incomingCallingPartyAddress = _src;
                    packet.incomingCalledPartyAddress = _dst;
                    packet.incomingServiceClass = _protocolClass;
                    packet.incomingHandling = _handling;
                    packet.incomingData = _data;
                    packet.incomingOptions = _options;
                    packet.incomingMaxHopCount = _maxHopCount;
                    packet.incomingOptionalData = optional_data;
                    packet.incomingServiceType = SCCP_XUDT;
                    _statisticsSection2 = UMSCCP_StatisticSection_XUDT_TX;
                    [_sccpLayer routePacket:packet];
                }
            }
            else /* we have pure data only */
            {
                UMSCCP_Packet *packet = [[UMSCCP_Packet alloc]init];
                packet.incomingMtp3Layer = _sccpLayer.mtp3;
                packet.incomingCallingPartyAddress = _src;
                packet.incomingCalledPartyAddress = _dst;
                packet.incomingServiceClass = _protocolClass;
                packet.incomingHandling = _handling;
                packet.incomingData = _data;
                packet.incomingOptions = _options;
                packet.incomingMaxHopCount = _maxHopCount;
                packet.incomingOptionalData = optional_data;
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
                [_sccpLayer routePacket:packet];
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


@end
