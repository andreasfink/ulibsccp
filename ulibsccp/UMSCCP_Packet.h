//
//  UMSCCP_Packet.h
//  ulibsccp
//
//  Created by Andreas Fink on 11.01.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibmtp3/ulibmtp3.h>
#import <ulibsccp/ulibgt.h>

#import <ulibsccp/UMSCCP_Defs.h>
#import <ulibsccp/UMSCCP_UserProtocol.h>

@class UMTCAP_itu_asn1_begin;
@class UMTCAP_itu_asn1_continue;
@class UMTCAP_itu_asn1_end;
@class UMTCAP_itu_asn1_abort;
@class UMTCAP_itu_asn1_unidirectional;
@class UMSMS;
@class UMSCCP_Segment;
@class UMSCCP_TcapSharingInstance;

@interface UMSCCP_Packet : UMASN1Sequence
{
    UMLayerSCCP                 *_sccp;
    
    /* timers */
    NSDate                      *_created;
    NSDate                      *_afterFilter1;
    NSDate                      *_reassembled;
    NSDate                      *_afterFilter2;
    NSDate                      *_routed;
    NSDate                      *_afterFilter3;
    NSDate                      *_segmented;
    NSDate                      *_afterFilter4;
    NSDate                      *_queuedForDelivery;
    
    NSString                    *_instance;     /* global instance name */
    NSString                    *_sccpInstance; /* should be _sccp.layerName */

    SCCP_State                  _state;
    UMSCCP_Segment              *_incomingSegment;

    /* tcap sharing */

    NSString                    *_incomingLinksetTcapSharingInsideName;
    NSString                    *_incomingLinksetTcapSharingOutsideName;
    NSNumber                    *_incomingLinksetTcapSharingPriority;

    id<UMSCCP_UserProtocol>     _incomingLocalUser;
    UMLayerMTP3                 *_incomingMtp3Layer;
    NSString                    *_incomingLinksetName;
    NSDictionary                *_incomingOptions;
    UMMTP3PointCode             *_incomingOpc;
    UMMTP3PointCode             *_incomingDpc;
    SCCP_ServiceClass           _incomingServiceClass;
    SCCP_ServiceType            _incomingServiceType;
    SCCP_Handling               _incomingHandling;
    int                         _incomingMaxHopCount;
    BOOL                        _incomingFromLocal;
    BOOL                        _incomingToLocal;
    SccpAddress                 *_incomingCallingPartyAddressBeforeTranslation;
    SccpAddress                 *_incomingCallingPartyAddress;
    NSString                    *_incomingCallingPartyCountry;
    SccpAddress                 *_incomingCalledPartyAddressBeforeTranslation;
    SccpAddress                 *_incomingCalledPartyAddress;
    NSString                    *_incomingCalledPartyCountry;
    NSData                      *_incomingMtp3Data;
    NSData                      *_incomingSccpData;
    NSData                      *_incomingOptionalData;
    SCCP_ReturnCause            _incomingReturnCause;

    id<UMSCCP_UserProtocol>     _outgoingLocalUser;
    UMLayerMTP3                 *_outgoingMtp3Layer;
    NSString                    *_outgoingLinksetName;
    NSDictionary                *_outgoingOptions;
    UMMTP3PointCode             *_outgoingOpc;
    UMMTP3PointCode             *_outgoingDpc;
    SCCP_ServiceClass           _outgoingServiceClass;
    SCCP_ServiceType            _outgoingServiceType;
    SCCP_Handling               _outgoingHandling;
    int                         _outgoingMaxHopCount;
    BOOL                        _outgoingFromLocal;
    BOOL                        _outgoingToLocal;

    SccpAddress                 *_outgoingCallingPartyAddressBeforeTranslation;
    SccpAddress                 *_outgoingCalledPartyAddressBeforeTranslation;
    SccpAddress                 *_outgoingCallingPartyAddress;
    SccpAddress                 *_outgoingCalledPartyAddress;
    NSData                      *_outgoingMtp3Data;
    NSData                      *_outgoingSccpData;
    UMSCCP_Segment              *_outgoingSegment;

    NSData                      *_outgoingOptionalData;
    SCCP_ReturnCause            _outgoingReturnCause;
    NSString                    *_outgoingDestination;
    
    /* this can be used by filters: */
    UMASN1Object                *_incomingTcapAsn1;

	UMTCAP_itu_asn1_begin		*_incomingTcapBegin;
	UMTCAP_itu_asn1_continue	*_incomingTcapContinue;
	UMTCAP_itu_asn1_end			*_incomingTcapEnd;
	UMTCAP_itu_asn1_abort		*_incomingTcapAbort;
    UMTCAP_itu_asn1_unidirectional *_incomingTcapUnidirectional;
    int                         _incomingTcapCommand; /* UMTCAP_Command */
    int                         _outgoingTcapCommand; /* UMTCAP_Command */
    NSString                    *_incomingApplicationContext;
    UMASN1Object                *_incomingGsmMapAsn1;
    NSArray                     *_incomingGsmMapOperations;
    int                         _incomingCategory;
    BOOL                        _canNotDecode;
    UMSynchronizedDictionary    *_tags;
    UMSynchronizedDictionary    *_vars;    
    SccpDestinationGroup        *_rerouteDestinationGroup;
    UMLogLevel                  _logLevel;
    NSString                    *_incoming_tcap_otid;
    NSString                    *_incoming_tcap_dtid;
    NSString                    *_outgoing_tcap_otid;
    NSString                    *_outgoing_tcap_dtid;
    NSString                    *_msisdn;
    NSString                    *_imsi;
    NSString                    *_smsc;
    NSString                    *_hlr;
    NSString                    *_msc;
    UMSMS                       *_sms;
    NSString                    *_partsInfo;
    NSString                    *_routingSelector;
    NSString                    *_forcedDestinationName;
    SccpDestinationGroup        *_forcedDestinationGroup;
    NSString                    *_forcedLinkset;
    UMMTP3PointCode             *_forcedDpc;
    id<UMSCCP_UserProtocol>     _forcedLocalUser;
    int                         _sls;

    SccpNumberTranslation       *_cga_number_translation_in;
    SccpNumberTranslation       *_cda_number_translation_in;
    SccpNumberTranslation       *_cga_number_translation_out;
    SccpNumberTranslation       *_cda_number_translation_out;
    UMSCCP_TcapSharingInstance  *_incomingLinksetTcapSharingInside;
    UMSCCP_TcapSharingInstance  *_incomingLinksetTcapSharingOutside;
    SCCP_ReturnCause            _errorCauseValue;
    BOOL                        _candidateForTcapSharing;
    UMLogLevel                  _tcapSharingTraceLevel;
    BOOL                        _routingTest;
    NSNumber                    *_routingTestTcapTransactionId;
    NSString                    *_routingTestApplicationContext;
    NSNumber                    *_routingTestMapOperation;
    NSMutableString             *_routingTestDebug;
}

@property(readwrite,strong,atomic)  NSString                    *instance;
@property(readwrite,strong,atomic)  NSString                    *sccpInstance;
@property(readwrite,strong,atomic)  UMLayerSCCP                 *sccp;
@property(readwrite,strong,atomic)  NSDate                      *created;
@property(readwrite,strong,atomic)  NSDate                      *reassembled;
@property(readwrite,strong,atomic)  NSDate                      *routed;
@property(readwrite,strong,atomic)  NSDate                      *segmented;
@property(readwrite,strong,atomic)  NSDate                      *queuedForDelivery;
@property(readwrite,strong,atomic)  NSDate                      *afterFilter1;
@property(readwrite,strong,atomic)  NSDate                      *afterFilter2;
@property(readwrite,strong,atomic)  NSDate                      *afterFilter3;
@property(readwrite,strong,atomic)  NSDate                      *afterFilter4;

@property(readwrite,assign,atomic)  SCCP_State                  state;

@property(readwrite,strong,atomic)  id<UMSCCP_UserProtocol>     incomingLocalUser;
@property(readwrite,strong,atomic)  UMLayerMTP3                 *incomingMtp3Layer;
@property(readwrite,strong,atomic)  NSString                    *incomingLinksetName;
@property(readwrite,strong,atomic)  NSString                    *incomingLinksetTcapSharingInsideName;
@property(readwrite,strong,atomic)  NSString                    *incomingLinksetTcapSharingOutsideName;
@property(readwrite,strong,atomic)  NSNumber                    *incomingLinksetTcapSharingPriority;

@property(readwrite,strong,atomic)  NSDictionary                *incomingOptions;
@property(readwrite,strong,atomic)  UMMTP3PointCode             *incomingOpc;
@property(readwrite,strong,atomic)  UMMTP3PointCode             *incomingDpc;
@property(readwrite,assign,atomic)  SCCP_ServiceClass           incomingServiceClass;
@property(readwrite,assign,atomic)  SCCP_ServiceType            incomingServiceType;
@property(readwrite,assign,atomic)  SCCP_Handling               incomingHandling;
@property(readwrite,assign,atomic)  int                         incomingMaxHopCount;
@property(readwrite,strong,atomic)  SccpAddress                 *incomingCallingPartyAddressBeforeTranslation;
@property(readwrite,strong,atomic)  SccpAddress                 *incomingCalledPartyAddressBeforeTranslation;
@property(readwrite,strong,atomic)  SccpAddress                 *incomingCallingPartyAddress;
@property(readwrite,strong,atomic)  NSString                    *incomingCallingPartyCountry;
@property(readwrite,strong,atomic)  SccpAddress                 *incomingCalledPartyAddress;
@property(readwrite,strong,atomic)  NSString                    *incomingCalledPartyCountry;
@property(readwrite,strong,atomic)  NSData                      *incomingMtp3Data;
@property(readwrite,strong,atomic)  NSData                      *incomingSccpData;
@property(readwrite,strong,atomic)  UMSCCP_Segment              *incomingSegment;
@property(readwrite,strong,atomic)  NSData                      *incomingOptionalData;
@property(readwrite,assign,atomic)  BOOL                        incomingFromLocal;
@property(readwrite,assign,atomic)  BOOL                        incomingToLocal;
@property(readwrite,assign,atomic)  SCCP_ReturnCause            incomingReturnCause;

@property(readwrite,strong,atomic)  id<UMSCCP_UserProtocol>     outgoingLocalUser;
@property(readwrite,strong,atomic)  UMLayerMTP3                 *outgoingMtp3Layer;
@property(readwrite,strong,atomic)  NSString                    *outgoingLinksetName;
@property(readwrite,strong,atomic)  NSDictionary                *outgoingOptions;
@property(readwrite,strong,atomic)  UMMTP3PointCode             *outgoingOpc;
@property(readwrite,strong,atomic)  UMMTP3PointCode             *outgoingDpc;
@property(readwrite,assign,atomic)  SCCP_ServiceClass           outgoingServiceClass;
@property(readwrite,assign,atomic)  SCCP_ServiceType            outgoingServiceType;
@property(readwrite,assign,atomic)  SCCP_Handling               outgoingHandling;
@property(readwrite,assign,atomic)  int                         outgoingMaxHopCount;
@property(readwrite,strong,atomic)  SccpAddress                 *outgoingCallingPartyAddress;
@property(readwrite,strong,atomic)  SccpAddress                 *outgoingCalledPartyAddress;
@property(readwrite,strong,atomic)  SccpAddress                 *outgoingCallingPartyAddressBeforeTranslation;
@property(readwrite,strong,atomic)  SccpAddress                 *outgoingCalledPartyAddressBeforeTranslation;

@property(readwrite,strong,atomic)  NSData                      *outgoingMtp3Data;
@property(readwrite,strong,atomic)  NSData                      *outgoingSccpData;
@property(readwrite,strong,atomic)  UMSCCP_Segment              *outgoingSegment;
@property(readwrite,strong,atomic)  NSData                      *outgoingOptionalData;
@property(readwrite,assign,atomic)  BOOL                        outgoingFromLocal;
@property(readwrite,assign,atomic)  BOOL                        outgoingToLocal;
@property(readwrite,assign,atomic)  SCCP_ReturnCause            outgoingReturnCause;
@property(readwrite,strong,atomic)  NSString                    *outgoingDestination;
@property(readwrite,assign,atomic)  SCCP_ReturnCause            errorCauseValue;

@property(readwrite,strong,atomic)  UMASN1Object           		*incomingTcapAsn1; /* this can be set by filters */
@property(readwrite,strong,atomic)  UMTCAP_itu_asn1_begin		*incomingTcapBegin;
@property(readwrite,strong,atomic)  UMTCAP_itu_asn1_continue	*incomingTcapContinue;
@property(readwrite,strong,atomic)  UMTCAP_itu_asn1_end			*incomingTcapEnd;
@property(readwrite,strong,atomic)  UMTCAP_itu_asn1_abort		*incomingTcapAbort;
@property(readwrite,strong,atomic)  UMTCAP_itu_asn1_unidirectional *incomingTcapUnidirectional;
@property(readwrite,assign,atomic)  int                         incomingTcapCommand; /* UMTCAP_Command */
@property(readwrite,assign,atomic)  int                         outgoingTcapCommand; /* UMTCAP_Command */

@property(readwrite,strong,atomic)  UMASN1Object                *incomingGsmMapAsn1;/* this can be set by filters */
@property(readwrite,strong,atomic)  NSString                    *incomingApplicationContext;
@property(readwrite,strong,atomic)  NSArray                     *incomingGsmMapOperations;
@property(readwrite,assign,atomic)  int                         incomingCategory;
@property(readwrite,assign,atomic)  BOOL                         canNotDecode;

@property(readwrite,strong,atomic)  UMSynchronizedDictionary    *tags;
@property(readwrite,strong,atomic)  UMSynchronizedDictionary    *vars;
@property(readwrite,strong,atomic)  SccpDestinationGroup        *rerouteDestinationGroup;
@property(readwrite,assign,atomic)  UMLogLevel                  logLevel;
@property(readwrite,strong,atomic)  NSString                    *msisdn;
@property(readwrite,strong,atomic)  NSString                    *imsi;
@property(readwrite,strong,atomic)  NSString                    *smsc;
@property(readwrite,strong,atomic)  NSString                    *hlr;
@property(readwrite,strong,atomic)  NSString                    *msc;

@property(readwrite,strong,atomic)  NSString                    *incoming_tcap_otid;
@property(readwrite,strong,atomic)  NSString                    *incoming_tcap_dtid;
@property(readwrite,strong,atomic)  NSString                    *outgoing_tcap_otid;
@property(readwrite,strong,atomic)  NSString                    *outgoing_tcap_dtid;
@property(readwrite,strong,atomic)  UMSMS                       *sms;
@property(readwrite,strong,atomic)  NSString                    *partsInfo;
@property(readwrite,strong,atomic)  NSString                    *routingSelector;
@property(readwrite,assign,atomic)  int                         sls;
@property(readwrite,strong,atomic)  SccpNumberTranslation       *cga_number_translation_in;
@property(readwrite,strong,atomic)  SccpNumberTranslation       *cda_number_translation_in;
@property(readwrite,strong,atomic)  SccpNumberTranslation       *cga_number_translation_out;
@property(readwrite,strong,atomic)  SccpNumberTranslation       *cda_number_translation_out;
@property(readwrite,strong,atomic)  UMSCCP_TcapSharingInstance  *incomingLinksetTcapSharingInside;
@property(readwrite,strong,atomic)  UMSCCP_TcapSharingInstance  *incomingLinksetTcapSharingOutside;
@property(readwrite,strong,atomic)  NSString                    *forcedDestinationName;
@property(readwrite,strong,atomic)  SccpDestinationGroup        *forcedDestinationGroup;
@property(readwrite,strong,atomic)  NSString                    *forcedLinkset;
@property(readwrite,strong,atomic)  id<UMSCCP_UserProtocol>     forcedLocalUser;
@property(readwrite,strong,atomic)  UMMTP3PointCode             *forcedDpc;
@property(readwrite,assign,atomic)  BOOL                        candidateForTcapSharing;
@property(readwrite,assign,atomic)  UMLogLevel                  tcapSharingTraceLevel;
@property(readwrite,assign,atomic) BOOL                         routingTest;
@property(readwrite,strong,atomic)  NSNumber                    *routingTestTcapTransactionId;
@property(readwrite,strong,atomic)  NSString                    *routingTestApplicationContext;
@property(readwrite,strong,atomic)  NSNumber                    *routingTestMapOperation;
@property(readwrite,strong,atomic)  NSMutableString             *routingTestDebug;


- (NSString *) incomingPacketType;
- (NSString *) outgoingPacketType;

- (void)copyIncomingToOutgoing;

- (void)addTag:(NSString *)tag;
- (void)clearTag:(NSString *)tag;
- (BOOL) hasTag:(NSString *)tag;
- (void)clearAllTags;

- (UMSynchronizedSortedDictionary *)dictionaryValue;
- (UMSynchronizedSortedDictionary *)dictionaryValueForwardSM;

- (void)applyIncomingNumberTranslation;
- (void)applyOutgoingNumberTranslation;

+ (NSString *)sccpServiceTypeToString:(SCCP_ServiceType)i;
+ (SCCP_ServiceType) stringToSccpServiceType:(NSString *)str;
+ (NSString *) sccpStateToString:(SCCP_State)state;
+ (SCCP_State) stringToSccpState:(NSString *)str;

+ (NSString *) sccpServiceClassToString:(SCCP_ServiceClass)serviceClass;
+ (SCCP_ServiceClass) stringToSccpServiceClass:(NSString *)str;

+ (NSString *) sccpReturnCauseString:(SCCP_ReturnCause)cause;
+ (SCCP_ReturnCause) stringToSccpReturnCauseString:(NSString *)str;


+ (NSString *) sccpHandlingToString:(SCCP_Handling)h;
+ (SCCP_Handling) stringToSccpHandling:(NSString *)str;


@end

