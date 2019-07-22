//
//  UMSCCP_Packet.h
//  ulibsccp
//
//  Created by Andreas Fink on 11.01.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibgt/ulibgt.h>

#import "UMSCCP_Defs.h"
#import "UMSCCP_UserProtocol.h"

@class UMTCAP_itu_asn1_begin;
@class UMTCAP_itu_asn1_continue;
@class UMTCAP_itu_asn1_end;
@class UMTCAP_itu_asn1_abort;

@interface UMSCCP_Packet : UMObject
{
    UMLayerSCCP                *_sccp;
    NSDate                    *_created;
    NSDate                    *_afterFilter1;
    NSDate                    *_reassembled;
    NSDate                    *_afterFilter2;
    NSDate                    *_routed;
    NSDate                    *_afterFilter3;
    NSDate                    *_segmented;
    NSDate                    *_afterFilter4;
    NSDate                    *_queuedForDelivery;
    SCCP_State                _state;

    id<UMSCCP_UserProtocol>     _incomingLocalUser;
    UMLayerMTP3                 *_incomingMtp3Layer;
    NSString                    *_incomingLinkset;
    NSDictionary                *_incomingOptions;
    UMMTP3PointCode             *_incomingOpc;
    UMMTP3PointCode             *_incomingDpc;
    SCCP_ServiceClass           _incomingServiceClass;
    SCCP_ServiceType            _incomingServiceType;
    int                         _incomingHandling;
    int                         _incomingMaxHopCount;
    BOOL                        _incomingFromLocal;
    BOOL                        _incomingToLocal;
    SccpAddress                 *_incomingCallingPartyAddress;
    SccpAddress                 *_incomingCalledPartyAddress;
    NSData                      *_incomingMtp3Data;
    NSData                      *_incomingSccpData;
    NSData                      *_incomingOptionalData;
    SCCP_ReturnCause            _incomingReturnCause;

    id<UMSCCP_UserProtocol>     _outgoingLocalUser;
    UMLayerMTP3                 *_outgoingMtp3Layer;
    NSString                    *_outgoingLinkset;
    NSDictionary                *_outgoingOptions;
    UMMTP3PointCode             *_outgoingOpc;
    UMMTP3PointCode             *_outgoingDpc;
    SCCP_ServiceClass           _outgoingServiceClass;
    SCCP_ServiceType            _outgoingServiceType;
    int                         _outgoingHandling;
    SccpAddress                 *_outgoingCallingPartyAddress;
    SccpAddress                 *_outgoingCalledPartyAddress;
    NSData                      *_outgoingMtp3Data;
    NSData                      *_outgoingSccpData;
    NSData                      *_outgoingOptionalData;
    int                         _outgoingMaxHopCount;
    BOOL                        _outgoingFromLocal;
    BOOL                        _outgoingToLocal;
    SCCP_ReturnCause            _outgoingReturnCause;

    /* this can be used by filters: */
    UMASN1Object                *_incomingTcapAsn1;

	UMTCAP_itu_asn1_begin		*_incomingTcapBegin;
	UMTCAP_itu_asn1_continue	*_incomingTcapContinue;
	UMTCAP_itu_asn1_end			*_incomingTcapEnd;
	UMTCAP_itu_asn1_abort		*_incomingTcapAbort;

    int                         _incomingTcapCommand; /* UMTCAP_Command */
    NSString                    *_incomingApplicationContext;
    UMASN1Object                *_incomingGsmMapAsn1;
    int                         _incomingGsmMapOperation;
    int                         _incomingCategory;
    NSString                    *_incomingLocalTransactionId;
    NSString                    *_incomingRemoteTransactionId;
    BOOL                        _canNotDecode;
    UMSynchronizedDictionary    *_tags;
    NSString                    *_custom1;
    NSString                    *_custom2;
    NSString                    *_custom3;
    NSString                    *_custom4;
    NSString                    *_custom5;
    NSString                    *_custom6;
    NSString                    *_custom7;
    NSString                    *_custom8;
    NSString                    *_custom9;
    NSString                    *_custom10;
}


@property(readwrite,strong,atomic)    UMLayerSCCP                *sccp;
@property(readwrite,strong,atomic)    NSDate                    *created;
@property(readwrite,strong,atomic)    NSDate                    *reassembled;
@property(readwrite,strong,atomic)    NSDate                    *routed;
@property(readwrite,strong,atomic)    NSDate                    *segmented;
@property(readwrite,strong,atomic)    NSDate                    *queuedForDelivery;

@property(readwrite,assign,atomic)  SCCP_State              state;

@property(readwrite,strong,atomic)    id<UMSCCP_UserProtocol>    incomingLocalUser;
@property(readwrite,strong,atomic)    UMLayerMTP3                *incomingMtp3Layer;
@property(readwrite,strong,atomic)    NSString                *incomingLinkset;
@property(readwrite,strong,atomic)    NSDictionary             *incomingOptions;
@property(readwrite,strong,atomic)    UMMTP3PointCode            *incomingOpc;
@property(readwrite,strong,atomic)    UMMTP3PointCode         *incomingDpc;
@property(readwrite,assign,atomic)  SCCP_ServiceClass       incomingServiceClass;
@property(readwrite,assign,atomic)  SCCP_ServiceType        incomingServiceType;
@property(readwrite,assign,atomic)  int                     incomingHandling;
@property(readwrite,assign,atomic)  int                     incomingMaxHopCount;
@property(readwrite,strong,atomic)  SccpAddress             *incomingCallingPartyAddress;
@property(readwrite,strong,atomic)  SccpAddress             *incomingCalledPartyAddress;
@property(readwrite,strong,atomic)  NSData                  *incomingMtp3Data;
@property(readwrite,strong,atomic)  NSData                  *incomingSccpData;
@property(readwrite,strong,atomic)  NSData                  *incomingOptionalData;
@property(readwrite,assign,atomic)  BOOL                    incomingFromLocal;
@property(readwrite,assign,atomic)  BOOL                    incomingToLocal;
@property(readwrite,assign,atomic)  SCCP_ReturnCause        incomingReturnCause;

@property(readwrite,strong,atomic)    id<UMSCCP_UserProtocol>    outgoingLocalUser;
@property(readwrite,strong,atomic)    UMLayerMTP3                *outgoingMtp3Layer;
@property(readwrite,strong,atomic)    NSString                *outgoingLinkset;
@property(readwrite,strong,atomic)    NSDictionary             *outgoingOptions;
@property(readwrite,strong,atomic)    UMMTP3PointCode            *outgoingOpc;
@property(readwrite,strong,atomic)    UMMTP3PointCode         *outgoingDpc;
@property(readwrite,assign,atomic)  SCCP_ServiceClass       outgoingServiceClass;
@property(readwrite,assign,atomic)  SCCP_ServiceType        outgoingServiceType;
@property(readwrite,assign,atomic)  int                     outgoingHandling;
@property(readwrite,assign,atomic)  int                     outgoingMaxHopCount;
@property(readwrite,strong,atomic)  SccpAddress             *outgoingCallingPartyAddress;
@property(readwrite,strong,atomic)  SccpAddress             *outgoingCalledPartyAddress;
@property(readwrite,strong,atomic)  NSData                  *outgoingMtp3Data;
@property(readwrite,strong,atomic)  NSData                  *outgoingSccpData;
@property(readwrite,strong,atomic)  NSData                  *outgoingOptionalData;
@property(readwrite,assign,atomic)  BOOL                    outgoingFromLocal;
@property(readwrite,assign,atomic)  BOOL                    outgoingToLocal;
@property(readwrite,assign,atomic)  SCCP_ReturnCause        outgoingReturnCause;


@property(readwrite,strong,atomic)  UMASN1Object           		*incomingTcapAsn1; /* this can be set by filters */
@property(readwrite,strong,atomic)  UMTCAP_itu_asn1_begin		*incomingTcapBegin;
@property(readwrite,strong,atomic)  UMTCAP_itu_asn1_continue	*incomingTcapContinue;
@property(readwrite,strong,atomic)  UMTCAP_itu_asn1_end			*incomingTcapEnd;
@property(readwrite,strong,atomic)  UMTCAP_itu_asn1_abort		*incomingTcapAbort;
@property(readwrite,strong,atomic)  UMASN1Object            *incomingGsmMapAsn1;/* this can be set by filters */
@property(readwrite,assign,atomic)  int                     incomingTcapCommand; /* UMTCAP_Command */
@property(readwrite,strong,atomic)  NSString                *incomingApplicationContext;
@property(readwrite,assign,atomic)  int                     incomingGsmMapOperation;
@property(readwrite,assign,atomic)  int                     incomingCategory;
@property(readwrite,strong,atomic)  NSString                *incomingLocalTransactionId;
@property(readwrite,strong,atomic)  NSString                *incomingRemoteTransactionId;
@property(readwrite,assign,atomic) BOOL                     canNotDecode;

@property(readwrite,strong,atomic) UMSynchronizedDictionary    *tags;
@property(readwrite,strong,atomic) NSString                    *custom1;
@property(readwrite,strong,atomic) NSString                    *custom2;
@property(readwrite,strong,atomic) NSString                    *custom3;
@property(readwrite,strong,atomic) NSString                    *custom4;
@property(readwrite,strong,atomic) NSString                    *custom5;
@property(readwrite,strong,atomic) NSString                    *custom6;
@property(readwrite,strong,atomic) NSString                    *custom7;
@property(readwrite,strong,atomic) NSString                    *custom8;
@property(readwrite,strong,atomic) NSString                    *custom9;
@property(readwrite,strong,atomic) NSString                    *custom10;


- (NSString *) incomingPacketType;
- (NSString *) outgoingPacketType;

- (void)copyIncomingToOutgoing;

- (void)addTag:(NSString *)tag;
- (void)clearTag:(NSString *)tag;
- (BOOL) hasTag:(NSString *)tag;
- (void)clearAllTags;

@end

