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

static int segmentReferenceId;

@implementation UMSCCP_sccpNUnitdata

@synthesize sccpUser;
@synthesize sccpLayer;
@synthesize data;
@synthesize src;
@synthesize dst;
@synthesize options;
@synthesize nextHop;
@synthesize qos;
@synthesize tcap_asn1;
@synthesize maxHopCount;

- (UMSCCP_sccpNUnitdata *)initForSccp:(UMLayerSCCP *)sccp
                                 user:(id<UMSCCP_UserProtocol>)xuser
                             userData:(NSData *)xdata
                              calling:(SccpAddress *)xsrc
                               called:(SccpAddress *)xdst
                     qualityOfService:(int)xqos
                              options:(NSDictionary *)xoptions;
{
    self = [super initWithName:@"UMSCCP_sccpNUnitdata"
                      receiver:sccp
                        sender:xuser
       requiresSynchronisation:NO];
    if(self)
    {
        sccpLayer = sccp;
        sccpUser = xuser;
        data = xdata;
        src = xsrc;
        dst = xdst;
        options = xoptions;
        qos = xqos;
        maxHopCount = 255;
    }
    return self;
}

- (UMSCCP_sccpNUnitdata *)initForSccp:(UMLayerSCCP *)sccp
                                 user:(id<UMSCCP_UserProtocol>)xuser
                     userDataSegments:(NSArray *)xdataSegments
                              calling:(SccpAddress *)xsrc
                               called:(SccpAddress *)xdst
                     qualityOfService:(int)xqos
                              options:(NSDictionary *)xoptions;
{
    self = [super initWithName:@"UMSCCP_sccpNUnitdata"
                      receiver:sccp
                        sender:xuser
       requiresSynchronisation:NO];
    if(self)
    {
        sccpLayer = sccp;
        sccpUser = xuser;
        dataSegments = [xdataSegments mutableCopy];
        src = xsrc;
        dst = xdst;
        options = xoptions;
        qos = xqos;
        if(options)
        {
            NSString *s = options[@"hop-counter"];
            if(s)
            {
                maxHopCount = [s intValue] -1;
            }
        }
        else
        {
            maxHopCount = 15;
        }
    }
    return self;
}


- (void)main
{
    @try
    {
        [self route];
        if(nextHop==NULL)
        {
            [self sendNoRouteError];
        }
        else
        {
            /* int cls =0;*/
             
            UMMTP3PointCode         *xopc =sccpLayer.attachedTo.opc;
            UMMTP3PointCode         *xdpc = nextHop.dpc;

            NSString *xopc_string = options[@"opc"];
            NSString *xdpc_string = options[@"dpc"];
 
            if((xdpc_string.length > 0) && (![xdpc_string isEqualToString:@"default"]))
            {
                xdpc = [[UMMTP3PointCode alloc] initWithString:xdpc_string
                                                       variant:sccpLayer.mtp3.variant];
            }

            if((xopc_string.length > 0) && (![xopc_string isEqualToString:@"default"]))
            {
                xopc = [[UMMTP3PointCode alloc] initWithString:xopc_string
                                                       variant:sccpLayer.mtp3.variant];
            }
            
            UMMTP3_Error e = UMMTP3_no_error;

            NSData *srcEncoded = [src encode:sccpLayer.sccpVariant];
            NSData *dstEncoded = [dst encode:sccpLayer.sccpVariant];
            NSUInteger cas = srcEncoded.length;
            NSUInteger cds = dstEncoded.length;
            NSUInteger maxPdu = 0;
            
            BOOL useXUDT        = [options[@"sccp-xudt"] boolValue];
            BOOL useSegments    = [options[@"sccp-segment"] boolValue];
            
            NSDictionary *sccp_options = options[@"sccp-optional"];
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

            if(data.length > 0)
            {
                /* we have single data as input, no segments yet */
                if(useXUDT == NO)
                {
                    maxPdu = [sccpLayer maxPayloadSizeForServiceType:SCCP_UDT
                                                  callingAddressSize:cas
                                                   calledAddressSize:cds
                                                       usingSegments:useSegments
                                                            provider:sccpLayer.mtp3];
                    
                    if(data.length > maxPdu)
                    {
                        /* no choice, we must segment */
                        useSegments=YES;
                        useXUDT = YES;
                        maxPdu = [sccpLayer maxPayloadSizeForServiceType:SCCP_XUDT
                                                      callingAddressSize:cas
                                                       calledAddressSize:cds
                                                           usingSegments:YES
                                                                provider:sccpLayer.mtp3];
                        
                    }
                }
                else
                {
                    maxPdu = [sccpLayer maxPayloadSizeForServiceType:SCCP_XUDT
                                                  callingAddressSize:cas
                                                   calledAddressSize:cds
                                                       usingSegments:useSegments
                                                            provider:sccpLayer.mtp3];
                    
                    if(data.length > maxPdu)
                    {
                        /* no choice, we must segment */
                        useSegments = YES;
                        useXUDT = YES;
                        maxPdu = [sccpLayer maxPayloadSizeForServiceType:SCCP_XUDT
                                                      callingAddressSize:cas
                                                       calledAddressSize:cds
                                                           usingSegments:useSegments
                                                                provider:sccpLayer.mtp3];
                        
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
                    
                    dataSegments = [[NSMutableArray alloc]init];
                    UMSCCP_Segment *segment = [[UMSCCP_Segment alloc]init];
                    segment.first = YES;
                    segment.class1 = YES;
                    segmentReferenceId = ref;
                    
                    const uint8_t *bytes = data.bytes;
                    NSUInteger n = data.length;
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
                        [dataSegments addObject:segment];
                        
                        segment = [[UMSCCP_Segment alloc]init];
                        segment.first = NO;
                        segment.class1 = YES;
                        segmentReferenceId = ref;
                        p = p + m;
                    }
                    NSUInteger count = dataSegments.count;
                    for(int i=0;i<count;i++)
                    {
                        UMSCCP_Segment *s = [dataSegments objectAtIndex:(NSUInteger)i];
                        s.remainingSegment = (int)count - i -1;
                    }
                    data = NULL;
                }
                else /* we have pure data only */
                {
                    if(useXUDT)
                    {
                        e = [sccpLayer sendXUDTdata:data
                                            calling:src
                                             called:dst
                                              class:1
                                        maxHopCount:maxHopCount
                                      returnOnError:YES
                                                opc:xopc
                                                dpc:xdpc
                                        optionsData:optional_data
                                            options:options
                                           provider:sccpLayer.mtp3];
                    }
                    else
                    {
                        e = [sccpLayer sendUDT:data
                                       calling:src
                                        called:dst
                                         class:1
                                 returnOnError:YES
                                           opc:xopc
                                           dpc:xdpc
                                       options:options
                                      provider:sccpLayer.mtp3];
                        
                    }
                }
            }
            if(dataSegments)
            {
                NSUInteger count = dataSegments.count;
                for(int i=0;i<count;i++)
                {
                    UMSCCP_Segment *s = [dataSegments objectAtIndex:(NSUInteger)i];
                    s.remainingSegment = (int)count - i -1;
                    e = [sccpLayer sendXUDTsegment:s
                                           calling:src
                                            called:dst
                                             class:1
                                       maxHopCount:maxHopCount
                                     returnOnError:YES
                                               opc:xopc
                                               dpc:xdpc
                                       optionsData:optional_data
                                           options:options
                                          provider:sccpLayer.mtp3];
                    if(e != UMMTP3_no_error)
                    {
                        break;
                    }
                }
            }
        }
    }
    @catch(NSException *ex)
    {
        [sccpLayer.logFeed majorErrorText:[NSString stringWithFormat:@"Error: %@",ex]];
    }
}

- (void) route
{
    nextHop = sccpLayer.defaultNextHop;
}

- (void)sendNoRouteError
{
    
}

-(void)sendToL3
{
//    UMMTP3PointCode *opc = nextHop.opc;
//    UMMTP3PointCode *dpc = nextHop.dpc;

}

@end
