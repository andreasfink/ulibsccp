//
//  UMSCCP_TcapSharingSession.m
//  ulibsccp
//
//  Created by Andreas Fink on 22.07.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_TcapSharingSession.h"

@implementation UMSCCP_TcapSharingSession

- (UMSCCP_TcapSharingSession *)init
{
    _timeoutValue = 90;
    return [self initWithTimeout:_timeoutValue];
}

- (UMSCCP_TcapSharingSession *)initWithTimeout:(NSTimeInterval)timeout
{
    self = [super init];
    if(self)
    {
        _timeoutValue = timeout;
        [self touch];
    }
    return self;
}

-(BOOL)isExpired
{
    if([_expiry isGreaterThan:[NSDate date]])
    {
        return NO;
    }
    return YES;
}

- (void)touch
{
    _expiry = [NSDate dateWithTimeIntervalSinceNow:_timeoutValue];
}

- (UMSynchronizedSortedDictionary *)objectValue
{
    UMSynchronizedSortedDictionary *d = [[UMSynchronizedSortedDictionary alloc]init];
 
    if(_expiry)
    {
        d[@"expiry"] = _expiry.stringValue;
    }
    if(_callingAddress)
    {
        d[@"calling-address"] = _callingAddress.stringValueE164;
    }
    if(_calledAddress)
    {
        d[@"called-address"] = _calledAddress.stringValueE164;
    }
    if(_insideLinkset)
    {
        d[@"inside-linset"] = _insideLinkset;
    }
    if(_outsideLinkset)
    {
        d[@"outside-linset"] = _outsideLinkset;
    }
    if(_insidePointcode)
    {
        d[@"inside-pointcode"] = _insidePointcode.stringValue;
    }
    if(_insideLocalUser)
    {
        d[@"inside-local-user"] = _insideLocalUser.name;
    }
    if(_insideLocalTcapTransactionId)
    {
        d[@"inside-local-tcap-id"] = _insideLocalTcapTransactionId;
    }
    if(_insideRemoteTcapTransactionId)
    {
        d[@"inside-remote-tcap-id"] = _insideRemoteTcapTransactionId;
    }

    if(_outsideLocalTcapTransactionId)
    {
        d[@"outside-local-tcap-id"] = _outsideLocalTcapTransactionId;
    }
    if(_outsideRemoteTcapTransactionId)
    {
        d[@"outside-remote-tcap-id"] = _outsideRemoteTcapTransactionId;
    }
    return d;
}

- (NSString *)description
{
    return [[self objectValue]jsonString];
}
@end
