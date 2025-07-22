//
//  UMSCCP_TcapSharingSession.h
//  ulibsccp
//
//  Created by Andreas Fink on 22.07.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibgt/ulibgt.h>

@interface UMSCCP_TcapSharingSession : UMObject
{
    NSDate          *_expiry;
    SccpAddress     *_callingAddress;
    SccpAddress     *_calledAddres;
    NSString        *_incomingLinkset;
    NSString        *_outgoingLinkset;
    NSNumber        *_incomingOriginatingTcapTransactionId;
    NSNumber        *_outgoingOriginatingTcapTransactionId;
    NSNumber        *_incomingDestinationTcapTransactionId;
    NSNumber        *_outgoingDestinationTcapTransactionId;
}

@property(readwrite,strong,atomic)  NSDate          *expiry;
@property(readwrite,strong,atomic)  SccpAddress     *callingAddress;
@property(readwrite,strong,atomic)  SccpAddress     *calledAddres;
@property(readwrite,strong,atomic)  NSString        *incomingLinkset;
@property(readwrite,strong,atomic)  NSString        *outgoingLinkset;
@property(readwrite,strong,atomic)  NSNumber        *incomingOriginatingTcapTransactionId;
@property(readwrite,strong,atomic)  NSNumber        *outgoingOriginatingTcapTransactionId;
@property(readwrite,strong,atomic)  NSNumber        *incomingDestinationTcapTransactionId;
@property(readwrite,strong,atomic)  NSNumber        *outgoingDestinationTcapTransactionId;

-(BOOL)isExpired;

@end
