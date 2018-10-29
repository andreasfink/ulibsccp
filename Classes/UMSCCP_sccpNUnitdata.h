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
    id<UMSCCP_UserProtocol> _sccpUser;
    UMLayerSCCP             *_sccpLayer;
    NSData                  *_data;
    NSMutableArray          *_dataSegments;
    SccpAddress             *_src;
    SccpAddress             *_dst;
    NSDictionary            *_options;
    int                     _qos;
    /* internal */
    SccpDestination         *_nextHop;
    NSMutableData           *_sccp_pdu;
    UMASN1Object            *_tcap_asn1;
    int                     _maxHopCount;
    BOOL                    _returnOnError;
    SCCP_ServiceClass       _protocolClass;
    int                     _handling;

    NSDate                  *_created;
    NSDate                  *_startOfProcessing;
    NSDate                  *_endOfProcessing;

    UMSynchronizedDictionary    *_processingStats;

    UMSCCP_StatisticSection _statisticsSection;
    UMSCCP_StatisticSection _statisticsSection2;

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
@property(readwrite,assign) SCCP_ServiceClass   protocolClass;
@property(readwrite,assign) int handling;



- (UMSCCP_sccpNUnitdata *)initForSccp:(UMLayerSCCP *)sccp
                                 user:(id<UMSCCP_UserProtocol>)xuser
                             userData:(NSData *)xdata
                              calling:(SccpAddress *)xsrc
                               called:(SccpAddress *)xdst
                     qualityOfService:(int)qos
                                class:(SCCP_ServiceClass)pclass
                             handling:(int)handling
                              options:(NSDictionary *)options;

- (UMSCCP_sccpNUnitdata *)initForSccp:(UMLayerSCCP *)sccp
                                 user:(id<UMSCCP_UserProtocol>)xuser
                     userDataSegments:(NSArray *)xdataSegments
                              calling:(SccpAddress *)xsrc
                               called:(SccpAddress *)xdst
                     qualityOfService:(int)qos
                                class:(SCCP_ServiceClass)pclass
                             handling:(int)handling
                              options:(NSDictionary *)options;

@end
