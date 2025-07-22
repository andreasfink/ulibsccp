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

@end
