//
//  UMSCCP_TcapSharingSession.h
//  ulibsccp
//
//  Created by Andreas Fink on 22.07.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibgt/ulibgt.h>
#import <ulibsccp/UMSCCP_UserProtocol.h>

@interface UMSCCP_TcapSharingSession : UMObject
{
    NSDate          *_expiry;
    SccpAddress     *_callingAddress;
    SccpAddress     *_calledAddress;
    NSString        *_insideLinkset;
    NSString        *_outsideLinkset;
    UMMTP3PointCode *_insidePointcode;
    id<UMSCCP_UserProtocol> _insideLocalUser;

    NSString        *_insideLocalTcapTransactionId;
    NSString        *_insideRemoteTcapTransactionId;
    NSString        *_outsideLocalTcapTransactionId;
    NSString        *_outsideRemoteTcapTransactionId;
    NSTimeInterval  _timeoutValue;
}

@property(readwrite,strong,atomic)  NSDate          *expiry;
@property(readwrite,strong,atomic)  SccpAddress     *callingAddress;
@property(readwrite,strong,atomic)  SccpAddress     *calledAddress;
@property(readwrite,strong,atomic)  NSString        *insideLinkset;
@property(readwrite,strong,atomic)  UMMTP3PointCode *insidePointcode;
@property(readwrite,strong,atomic)  id<UMSCCP_UserProtocol> insideLocalUser;

@property(readwrite,strong,atomic)  NSString        *outsideLinkset;
@property(readwrite,strong,atomic)  NSString        *insideLocalTcapTransactionId;
@property(readwrite,strong,atomic)  NSString        *insideRemoteTcapTransactionId;
@property(readwrite,strong,atomic)  NSString        *outsideLocalTcapTransactionId;
@property(readwrite,strong,atomic)  NSString        *outsideRemoteTcapTransactionId;

- (UMSCCP_TcapSharingSession *)initWithTimeout:(NSTimeInterval)timeout;
-(BOOL)isExpired;
- (void)touch;

- (UMSynchronizedSortedDictionary *)objectValue;
@end
