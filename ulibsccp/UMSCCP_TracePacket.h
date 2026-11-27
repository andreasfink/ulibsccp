//
//  UMSCCP_TracePacket.h
//  ulibsccp
//
//  Created by Andreas Fink on 25.11.2026.
//

#import <ulib/ulib.h>
@class SccpAddress;

typedef enum UMSCCP_TracePacket_Tag_enum
{
    UMSCCP_TracePacket_Tag_instanceName                             = 1,
    UMSCCP_TracePacket_Tag_sccpInstanceName                         = 2,
    UMSCCP_TracePacket_Tag_mtp3InstanceName                         = 3,
    UMSCCP_TracePacket_Tag_created                                  = 4,
    UMSCCP_TracePacket_Tag_linksetName                              = 5,
    UMSCCP_TracePacket_Tag_variant                                  = 6,
    UMSCCP_TracePacket_Tag_networkIndicator                         = 7,
    UMSCCP_TracePacket_Tag_opc                                      = 8,
    UMSCCP_TracePacket_Tag_dpc                                      = 9,
    UMSCCP_TracePacket_Tag_serviceClass                             = 10,
    UMSCCP_TracePacket_Tag_serviceType                              = 11,
    UMSCCP_TracePacket_Tag_handling                                 = 12,
    UMSCCP_TracePacket_Tag_maxHopCount                              = 13,
    UMSCCP_TracePacket_Tag_callingPartyAddressBeforeTranslation     = 14,
    UMSCCP_TracePacket_Tag_callingPartyAddress                      = 15,
    UMSCCP_TracePacket_Tag_callingPartyCountry                      = 16,
    UMSCCP_TracePacket_Tag_callingPartyPrefix                       = 17,
    UMSCCP_TracePacket_Tag_calledPartyAddressBeforeTranslation      = 18,
    UMSCCP_TracePacket_Tag_calledPartyAddress                       = 19,
    UMSCCP_TracePacket_Tag_calledPartyCountry                       = 20,
    UMSCCP_TracePacket_Tag_calledPartyPrefix                        = 21,
    UMSCCP_TracePacket_Tag_mtp3Data                                 = 22,
    UMSCCP_TracePacket_Tag_sccpData                                 = 23,
    UMSCCP_TracePacket_Tag_optionalData                             = 24,
    UMSCCP_TracePacket_Tag_returnCause                              = 25,
    UMSCCP_TracePacket_Tag_tcapType                                 = 26,
    UMSCCP_TracePacket_Tag_applicationContext                       = 27,
    UMSCCP_TracePacket_Tag_mapOperations                            = 28,
    UMSCCP_TracePacket_Tag_tcap_oid                                 = 29,
    UMSCCP_TracePacket_Tag_tcap_did                                 = 30,
    UMSCCP_TracePacket_Tag_msisdn                                   = 31,
    UMSCCP_TracePacket_Tag_imsi                                     = 32,
    UMSCCP_TracePacket_Tag_smsc                                     = 33,
    UMSCCP_TracePacket_Tag_hlr                                      = 34,
    UMSCCP_TracePacket_Tag_msc                                      = 35,
    UMSCCP_TracePacket_Tag_partsInfo                                = 36,
    UMSCCP_TracePacket_Tag_routingSelector                          = 37,
    UMSCCP_TracePacket_Tag_error                                    = 38,

    UMSCCP_TracePacket_Tag_dropped                                  = 51,
    UMSCCP_TracePacket_Tag_fromLocal                                = 52,
    UMSCCP_TracePacket_Tag_toLocal                                  = 53,
    UMSCCP_TracePacket_Tag_canNotDecode                             = 54,
    UMSCCP_TracePacket_Tag_routingTest                              = 55,
    UMSCCP_TracePacket_Tag_isIncoming                               = 56,

    
    UMSCCP_TracePacket_Tag_custom0                                  = 100,
    UMSCCP_TracePacket_Tag_custom1                                  = 101,
    UMSCCP_TracePacket_Tag_custom2                                  = 102,
    UMSCCP_TracePacket_Tag_custom3                                  = 103,
    UMSCCP_TracePacket_Tag_custom4                                  = 104,
    UMSCCP_TracePacket_Tag_custom5                                  = 105,
    UMSCCP_TracePacket_Tag_custom6                                  = 106,
    UMSCCP_TracePacket_Tag_custom7                                  = 107,
    UMSCCP_TracePacket_Tag_custom8                                  = 108,
    UMSCCP_TracePacket_Tag_custom9                                  = 109,
    

    UMSCCP_TracePacket_Tag_data0                                    = 110,
    UMSCCP_TracePacket_Tag_data1                                    = 111,
    UMSCCP_TracePacket_Tag_data2                                    = 112,
    UMSCCP_TracePacket_Tag_data3                                    = 113,
    UMSCCP_TracePacket_Tag_data4                                    = 114,
    UMSCCP_TracePacket_Tag_data5                                    = 115,
    UMSCCP_TracePacket_Tag_data6                                    = 116,
    UMSCCP_TracePacket_Tag_data7                                    = 117,
    UMSCCP_TracePacket_Tag_data8                                    = 118,
    UMSCCP_TracePacket_Tag_data9                                    = 119,

} UMSCCP_TracePacket_Tag_enum;

@interface UMSCCP_TracePacket : UMASN1Sequence
{
    NSString        *_instanceName;
    NSString        *_sccpInstanceName;
    NSString        *_mtp3InstanceName;
    NSDate          *_created;
    NSString        *_linksetName;
    NSString        *_variant;
    NSNumber        *_networkIndicator;
    NSNumber        *_opc;
    NSNumber        *_dpc;
    NSString        *_serviceClass;
    NSString        *_serviceType;
    NSString        *_handling;
    NSNumber        *_maxHopCount;
    SccpAddress     *_callingPartyAddressBeforeTranslation;
    SccpAddress     *_callingPartyAddress;
    NSString        *_callingPartyCountry;
    NSString        *_callingPartyPrefix;
    SccpAddress     *_calledPartyAddressBeforeTranslation;
    SccpAddress     *_calledPartyAddress;
    NSString        *_calledPartyCountry;
    NSString        *_calledPartyPrefix;
    NSData          *_mtp3Data;
    NSData          *_sccpData;
    NSData          *_optionalData;
    NSString        *_returnCause;
    NSString        *_tcapType;
    NSString        *_applicationContext;
    NSString        *_mapOperations;
    NSString        *_tcap_oid;
    NSString        *_tcap_did;
    NSString        *_msisdn;
    NSString        *_imsi;
    NSString        *_smsc;
    NSString        *_hlr;
    NSString        *_msc;
    NSString        *_partsInfo;
    NSString        *_routingSelector;
    NSString        *_error;
    BOOL            _dropped;
    BOOL            _fromLocal;
    BOOL            _toLocal;
    BOOL            _canNotDecode;
    BOOL            _routingTest;
    BOOL            _isIncoming;
    NSString        *_custom0;
    NSString        *_custom1;
    NSString        *_custom2;
    NSString        *_custom3;
    NSString        *_custom4;
    NSString        *_custom5;
    NSString        *_custom6;
    NSString        *_custom7;
    NSString        *_custom8;
    NSString        *_custom9;
    NSData          *_data0;
    NSData          *_data1;
    NSData          *_data2;
    NSData          *_data3;
    NSData          *_data4;
    NSData          *_data5;
    NSData          *_data6;
    NSData          *_data7;
    NSData          *_data8;
    NSData          *_data9;
}

@property(readwrite,strong,atomic)  NSString        *instanceName;
@property(readwrite,strong,atomic)  NSString        *sccpInstanceName;
@property(readwrite,strong,atomic)  NSString        *mtp3InstanceName;
@property(readwrite,strong,atomic)  NSDate          *created;
@property(readwrite,strong,atomic)  NSString        *linksetName;
@property(readwrite,strong,atomic)  NSString        *variant;
@property(readwrite,strong,atomic)  NSNumber        *networkIndicator;
@property(readwrite,strong,atomic)  NSNumber        *opc;
@property(readwrite,strong,atomic)  NSNumber        *dpc;
@property(readwrite,strong,atomic)  NSString        *serviceClass;
@property(readwrite,strong,atomic)  NSString        *serviceType;
@property(readwrite,strong,atomic)  NSString        *handling;
@property(readwrite,strong,atomic)  NSNumber        *maxHopCount;
@property(readwrite,strong,atomic)  SccpAddress     *callingPartyAddressBeforeTranslation;
@property(readwrite,strong,atomic)  SccpAddress     *callingPartyAddress;
@property(readwrite,strong,atomic)  NSString        *callingPartyCountry;
@property(readwrite,strong,atomic)  NSString        *callingPartyPrefix;
@property(readwrite,strong,atomic)  SccpAddress     *calledPartyAddressBeforeTranslation;
@property(readwrite,strong,atomic)  SccpAddress     *calledPartyAddress;
@property(readwrite,strong,atomic)  NSString        *calledPartyCountry;
@property(readwrite,strong,atomic)  NSString        *calledPartyPrefix;
@property(readwrite,strong,atomic)  NSData          *mtp3Data;
@property(readwrite,strong,atomic)  NSData          *sccpData;
@property(readwrite,strong,atomic)  NSData          *optionalData;
@property(readwrite,strong,atomic)  NSString        *returnCause;
@property(readwrite,strong,atomic)  NSString        *tcapType;
@property(readwrite,strong,atomic)  NSString        *applicationContext;
@property(readwrite,strong,atomic)  NSString        *mapOperations;
@property(readwrite,strong,atomic)  NSString        *tcap_oid;
@property(readwrite,strong,atomic)  NSString        *tcap_did;
@property(readwrite,strong,atomic)  NSString        *msisdn;
@property(readwrite,strong,atomic)  NSString        *imsi;
@property(readwrite,strong,atomic)  NSString        *smsc;
@property(readwrite,strong,atomic)  NSString        *hlr;
@property(readwrite,strong,atomic)  NSString        *msc;
@property(readwrite,strong,atomic)  NSString        *partsInfo;
@property(readwrite,strong,atomic)  NSString        *routingSelector;
@property(readwrite,strong,atomic)  NSString        *error;

@property(readwrite,assign,atomic)  BOOL            dropped;
@property(readwrite,assign,atomic)  BOOL            fromLocal;
@property(readwrite,assign,atomic)  BOOL            toLocal;
@property(readwrite,assign,atomic)  BOOL            canNotDecode;
@property(readwrite,assign,atomic)  BOOL            routingTest;
@property(readwrite,assign,atomic)  BOOL            isIncoming;

@property(readwrite,strong,atomic)  NSString        *custom0;
@property(readwrite,strong,atomic)  NSString        *custom1;
@property(readwrite,strong,atomic)  NSString        *custom2;
@property(readwrite,strong,atomic)  NSString        *custom3;
@property(readwrite,strong,atomic)  NSString        *custom4;
@property(readwrite,strong,atomic)  NSString        *custom5;
@property(readwrite,strong,atomic)  NSString        *custom6;
@property(readwrite,strong,atomic)  NSString        *custom7;
@property(readwrite,strong,atomic)  NSString        *custom8;
@property(readwrite,strong,atomic)  NSString        *custom9;

@property(readwrite,strong,atomic)  NSData          *data0;
@property(readwrite,strong,atomic)  NSData          *data1;
@property(readwrite,strong,atomic)  NSData          *data2;
@property(readwrite,strong,atomic)  NSData          *data3;
@property(readwrite,strong,atomic)  NSData          *data4;
@property(readwrite,strong,atomic)  NSData          *data5;
@property(readwrite,strong,atomic)  NSData          *data6;
@property(readwrite,strong,atomic)  NSData          *data7;
@property(readwrite,strong,atomic)  NSData          *data8;
@property(readwrite,strong,atomic)  NSData          *data9;

@end

