//
//  UMSCCP_sccpNUnitdata.h
//  ulibsccp
//
//  Created by Andreas Fink on 31.03.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibgt/ulibgt.h>
#import "UMSCCP_UserProtocol.h"
#import "UMLayerSCCP.h"

@interface UMSCCP_sccpNUnitdata : UMLayerTask
{
    id<UMSCCP_UserProtocol> sccpUser;
    UMLayerSCCP             *sccpLayer;
    NSData                  *data;
    NSMutableArray          *dataSegments;
    SccpAddress             *src;
    SccpAddress             *dst;
    NSDictionary            *options;
    int                     qos;
    /* internal */
    SccpDestination         *nextHop;
    NSMutableData           *sccp_pdu;
    UMASN1Object            *tcap_asn1;
    int                     maxHopCount;
    BOOL                    returnOnError;
}

@property(readwrite,strong) id<UMSCCP_UserProtocol> sccpUser;
@property(readwrite,strong) UMLayerSCCP *sccpLayer;
@property(readwrite,strong) NSData      *data;
@property(readwrite,strong) SccpAddress *src;
@property(readwrite,strong) SccpAddress *dst;
@property(readwrite,strong) NSDictionary *options;
@property(readwrite,assign) int qos;
@property(readwrite,strong) SccpDestination *nextHop;
@property(readwrite,strong) UMASN1Object *tcap_asn1;
@property(readwrite,assign) int maxHopCount;



- (UMSCCP_sccpNUnitdata *)initForSccp:(UMLayerSCCP *)sccp
                                 user:(id<UMSCCP_UserProtocol>)xuser
                             userData:(NSData *)xdata
                              calling:(SccpAddress *)xsrc
                               called:(SccpAddress *)xdst
                     qualityOfService:(int)qos
                              options:(NSDictionary *)options;

- (UMSCCP_sccpNUnitdata *)initForSccp:(UMLayerSCCP *)sccp
                                 user:(id<UMSCCP_UserProtocol>)xuser
                     userDataSegments:(NSArray *)xdataSegments
                              calling:(SccpAddress *)xsrc
                               called:(SccpAddress *)xdst
                     qualityOfService:(int)qos
                              options:(NSDictionary *)options;

@end
