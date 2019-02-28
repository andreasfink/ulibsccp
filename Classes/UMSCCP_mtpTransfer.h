//
//  UMSCCP_mtpTransfer.h
//  ulibsccp
//
//  Created by Andreas Fink on 05.04.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibmtp3/ulibmtp3.h>
#import <ulibgt/ulibgt.h>

#import "UMSCCP_Defs.h"
#import "UMSCCP_StatisticSection.h"

@class UMLayerSCCP;
@class UMSCCP_Packet;

@interface UMSCCP_mtpTransfer : UMLayerTask
{
    NSData *data;
    int si;
    int ni;
    UMMTP3PointCode *opc;
    UMMTP3PointCode *dpc;
    NSMutableDictionary *options;
    
    UMLayerSCCP *sccpLayer;
    UMLayerMTP3 *mtp3Layer;

    SccpAddress     *src;
    SccpAddress     *dst;
    NSData          *sccp_pdu;
    NSData          *sccp_optional;
    SCCP_ServiceClass  m_protocol_class;
    int             m_handling;
    int             m_hopcounter;
    NSMutableDictionary *optional_dict;
    int             importance;
    int             end_of_optional_parameters;
    int             m_return_cause;
    UMSynchronizedSortedDictionary *_decodedJson;
    NSData *_decodedPdu;
    int m_type;

    NSDate                  *_created;
    NSDate                  *_startOfProcessing;
    NSDate                  *_endOfProcessing;
    UMSCCP_StatisticSection _statsSection;
    UMSCCP_StatisticSection _statsSection2;

	UMSCCP_Packet		*_packet;
}

@property(readwrite,strong,atomic)  UMSynchronizedSortedDictionary *decodedJson;
@property(readwrite,strong,atomic)  SccpAddress *decodedCalling;
@property(readwrite,strong,atomic)  SccpAddress *decodedCalled;
@property(readwrite,strong,atomic)  NSData *decodedData;

- (UMSCCP_mtpTransfer *)initForSccp:(UMLayerSCCP *)layer
                               mtp3:(UMLayerMTP3 *)mtp3
                                opc:(UMMTP3PointCode *)opc
                                dpc:(UMMTP3PointCode *)dpc
                                 si:(int)si
                                 ni:(int)ni
                               data:(NSData *)data
                            options:(NSDictionary *)options;


@end
