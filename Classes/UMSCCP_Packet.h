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

@interface UMSCCP_Packet : UMObject
{
	UMLayerSCCP				*_sccp;
	NSDate					*_created;
	NSDate					*_afterFilter1;
	NSDate					*_reassembled;
	NSDate					*_afterFilter2;
	NSDate					*_routed;
	NSDate					*_afterFilter3;
	NSDate					*_segmented;
	NSDate					*_afterFilter4;
	NSDate					*_queuedForDelivery;
	SCCP_State				_state;

	id<UMSCCP_UserProtocol>	_incomingLocalUser;
	UMLayerMTP3				*_incomingMtp3Layer;
	NSString				*_incomingLinkset;
	NSDictionary 			*_incomingOptions;
	UMMTP3PointCode			*_incomingOpc;
	UMMTP3PointCode 		*_incomingDpc;
    SCCP_ServiceClass        _incomingServiceClass;
    SCCP_ServiceType        _incomingServiceType;
    int                     _incomingHandling;
    int                     _incomingMaxHopCount;
    BOOL                    _incomingFromLocal;
    BOOL                    _incomingToLocal;

    SccpAddress             *_incomingCallingPartyAddress;
    SccpAddress             *_incomingCalledPartyAddress;
    NSData                    *_incomingData;
    NSData                    *_incomingOptionalData;

	id<UMSCCP_UserProtocol>	_outgoingLocalUser;
	UMLayerMTP3				*_outgoingMtp3Layer;
	NSString				*_outgoingLinkset;
	NSDictionary 			*_outgoingOptions;
	UMMTP3PointCode			*_outgoingOpc;
	UMMTP3PointCode 		*_outgoingDpc;
    SCCP_ServiceClass       _outgoingServiceClass;
    SCCP_ServiceType        _outgoingServiceType;
    int                     _outgoingHandling;
    SccpAddress             *_outgoingCallingPartyAddress;
    SccpAddress             *_outgoingCalledPartyAddress;
    NSData                    *_outgoingData;
    NSData                    *_outgoingOptionalData;
    int                     _outgoingMaxHopCount;
    BOOL                    _outgoingFromLocal;
    BOOL                    _outgoingToLocal;

}


@property(readwrite,strong,atomic)	UMLayerSCCP				*sccp;
@property(readwrite,strong,atomic)	NSDate					*created;
@property(readwrite,strong,atomic)	NSDate					*reassembled;
@property(readwrite,strong,atomic)	NSDate					*routed;
@property(readwrite,strong,atomic)	NSDate					*segmented;
@property(readwrite,strong,atomic)	NSDate					*queuedForDelivery;

@property(readwrite,assign,atomic)  SCCP_State              state;

@property(readwrite,strong,atomic)	id<UMSCCP_UserProtocol>	incomingLocalUser;
@property(readwrite,strong,atomic)	UMLayerMTP3				*incomingMtp3Layer;
@property(readwrite,strong,atomic)	NSString				*incomingLinkset;
@property(readwrite,strong,atomic)	NSDictionary 			*incomingOptions;
@property(readwrite,strong,atomic)	UMMTP3PointCode			*incomingOpc;
@property(readwrite,strong,atomic)	UMMTP3PointCode 		*incomingDpc;
@property(readwrite,assign,atomic)  SCCP_ServiceClass       incomingServiceClass;
@property(readwrite,assign,atomic)  SCCP_ServiceType        incomingServiceType;
@property(readwrite,assign,atomic)  int                     incomingHandling;
@property(readwrite,strong,atomic)  SccpAddress             *incomingCallingPartyAddress;
@property(readwrite,strong,atomic)  SccpAddress             *incomingCalledPartyAddress;
@property(readwrite,strong,atomic)    NSData                    *incomingData;
@property(readwrite,strong,atomic)    NSData                    *incomingOptionalData;
@property(readwrite,assign,atomic)  BOOL                    incomingFromLocal;
@property(readwrite,assign,atomic)  BOOL                    incomingToLocal;

@property(readwrite,strong,atomic)	id<UMSCCP_UserProtocol>	outgoingLocalUser;
@property(readwrite,strong,atomic)	UMLayerMTP3				*outgoingMtp3Layer;
@property(readwrite,strong,atomic)	NSString				*outgoingLinkset;
@property(readwrite,strong,atomic)	NSDictionary 			*outgoingOptions;
@property(readwrite,strong,atomic)	UMMTP3PointCode			*outgoingOpc;
@property(readwrite,strong,atomic)	UMMTP3PointCode 		*outgoingDpc;
@property(readwrite,assign,atomic)  SCCP_ServiceClass       outgoingServiceClass;
@property(readwrite,assign,atomic)  SCCP_ServiceType        outgoingServiceType;
@property(readwrite,assign,atomic)  int                     outgoingHandling;
@property(readwrite,strong,atomic)  SccpAddress             *outgoingCallingPartyAddress;
@property(readwrite,strong,atomic)  SccpAddress             *outgoingCalledPartyAddress;
@property(readwrite,strong,atomic)    NSData                    *outgoingData;
@property(readwrite,strong,atomic)    NSData                    *outgoingOptionalData;
@property(readwrite,assign,atomic)  BOOL                    outgoingFromLocal;
@property(readwrite,assign,atomic)  BOOL                    outgoingToLocal;

- (NSString *) incomingPacketType;
- (NSString *) outgoingPacketType;

- (void)copyIncomingToOutgoing;

@end

