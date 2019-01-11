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
	SccpAddress				*_callingAddress;
	SccpAddress				*_calledAddress;
	SCCP_ServiceClass		_serviceClass;
	SCCP_ServiceType		_serviceType;
	SCCP_State				_state;
	int						_handling;

	id<UMSCCP_UserProtocol>	_incomingLocalUser;
	UMLayerMTP3				*_incomingMtp3Layer;
	NSString				*_incomingLinkset;
	NSDictionary 			*_incomingOptions;
	UMMTP3PointCode			*_incomingOpc;
	UMMTP3PointCode 		*_incomingDpc;
	NSData					*_incomingData;

	id<UMSCCP_UserProtocol>	_outgoingLocalUser;
	UMLayerMTP3				*_outgoingMtp3Layer;
	NSString				*_outgoingLinkset;
	NSDictionary 			*_outgoingOptions;
	UMMTP3PointCode			*_outgoingOpc;
	UMMTP3PointCode 		*_outgoingDpc;
	NSData					*_outgoingData;

}


@property(readwrite,strong,atomic)	UMLayerSCCP				*sccp;
@property(readwrite,strong,atomic)	NSDate					*created;
@property(readwrite,strong,atomic)	NSDate					*reassembled;
@property(readwrite,strong,atomic)	NSDate					*routed;
@property(readwrite,strong,atomic)	NSDate					*segmented;
@property(readwrite,strong,atomic)	NSDate					*queuedForDelivery;

@property(readwrite,strong,atomic)	SccpAddress				*callingAddress;
@property(readwrite,strong,atomic)	SccpAddress				*calledAddress;
@property(readwrite,assign,atomic)	SCCP_ServiceClass		serviceClass;
@property(readwrite,assign,atomic)	SCCP_ServiceType		serviceType;
@property(readwrite,assign,atomic)	SCCP_State				state;
@property(readwrite,assign,atomic)	int						handling;

@property(readwrite,strong,atomic)	id<UMSCCP_UserProtocol>	incomingLocalUser;
@property(readwrite,strong,atomic)	UMLayerMTP3				*incomingMtp3Layer;
@property(readwrite,strong,atomic)	NSString				*incomingLinkset;
@property(readwrite,strong,atomic)	NSDictionary 			*incomingOptions;
@property(readwrite,strong,atomic)	UMMTP3PointCode			*incomingOpc;
@property(readwrite,strong,atomic)	UMMTP3PointCode 		*incomingDpc;
@property(readwrite,strong,atomic)	NSData					*incomingData;

@property(readwrite,strong,atomic)	id<UMSCCP_UserProtocol>	outgoingLocalUser;
@property(readwrite,strong,atomic)	UMLayerMTP3				*outgoingMtp3Layer;
@property(readwrite,strong,atomic)	NSString				*outgoingLinkset;
@property(readwrite,strong,atomic)	NSDictionary 			*outgoingOptions;
@property(readwrite,strong,atomic)	UMMTP3PointCode			*outgoingOpc;
@property(readwrite,strong,atomic)	UMMTP3PointCode 		*outgoingDpc;
@property(readwrite,strong,atomic)	NSData					*outgoingData;

@end

