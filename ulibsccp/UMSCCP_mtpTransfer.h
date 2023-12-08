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

#import <ulibsccp/UMSCCP_Defs.h>
#import <ulibsccp/UMSCCP_StatisticSection.h>

@class UMLayerSCCP;
@class UMSCCP_Packet;

@interface UMSCCP_mtpTransfer : UMLayerTask
{
    NSData          *_data;
    int             _si;
    int             _ni;
    int             _sls;
    UMMTP3PointCode *_opc;
    UMMTP3PointCode *_dpc;
    NSMutableDictionary *_options;
    UMLayerSCCP     *_sccpLayer;
    UMLayerMTP3     *_mtp3Layer;
    SccpAddress     *_src;
    SccpAddress     *_dst;
    NSData          *_sccp_pdu;
    SCCP_ServiceClass   _m_protocol_class;
    SCCP_Handling       _m_handling;
    int                 _m_hopcounter;
    NSMutableDictionary *_optional_dict;
    int                 _importance;
    int                 _end_of_optional_parameters;
    int                 _m_return_cause;
    UMSynchronizedSortedDictionary *_decodedJson;
    NSData              *_decodedPdu;
    int _m_type;

    NSDate                  *_created;
    NSDate                  *_startOfProcessing;
    NSDate                  *_endOfProcessing;
    UMSCCP_StatisticSection _statsSection;
    UMSCCP_StatisticSection _statsSection2;
	UMSCCP_Packet		    *_packet;
    UMMTP3TranslationTableMap       *_map;
    UMMTP3CGATranslationTableMap *_cga_map;
    NSString                *_incomingLinksetName;
    SccpNumberTranslation *_cga_number_translation_in;
    SccpNumberTranslation *_cda_number_translation_in;
}

@property(readwrite,strong,atomic)  UMSynchronizedSortedDictionary *decodedJson;
@property(readwrite,strong,atomic)  SccpAddress *decodedCalling;
@property(readwrite,strong,atomic)  SccpAddress *decodedCalled;
@property(readwrite,strong,atomic)  NSData *decodedData;
@property(readwrite,strong,atomic)  UMSCCP_Packet *packet;
@property(readwrite,strong,atomic)  UMMTP3TranslationTableMap *map;
@property(readwrite,strong,atomic)  NSString *incomingLinksetName;

- (UMSCCP_mtpTransfer *)initForSccp:(UMLayerSCCP *)layer
                               mtp3:(UMLayerMTP3 *)mtp3
                                opc:(UMMTP3PointCode *)opc
                                dpc:(UMMTP3PointCode *)dpc
                                 si:(int)si
                                 ni:(int)ni
                                sls:(int)sls
                               data:(NSData *)data
                            options:(NSDictionary *)options
                                map:(UMMTP3TranslationTableMap *)map
                incomingLinksetName:(NSString *)linksetName;

- (UMSCCP_mtpTransfer *)initForSccp:(UMLayerSCCP *)layer
                               mtp3:(UMLayerMTP3 *)mtp3
                                opc:(UMMTP3PointCode *)xopc
                                dpc:(UMMTP3PointCode *)xdpc
                                 si:(int)xsi
                                 ni:(int)xni
                                sls:(int)sls
                               data:(NSData *)xdata
                            options:(NSDictionary *)xoptions
                                map:(UMMTP3TranslationTableMap *)ttmap
                incomingLinksetName:(NSString *)linksetName
                   cgaTranslationIn:(SccpNumberTranslation *)cga_number_translation_in
                   cdaTranslationIn:(SccpNumberTranslation *)cda_number_translation_in;


@end
