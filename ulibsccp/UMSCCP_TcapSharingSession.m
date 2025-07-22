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
    return [self initWithTimeout:90];
}

- (UMSCCP_TcapSharingSession *)initWithTimeout:(NSTimeInterval)timeout
{
    self = [super init];
    if(self)
    {
        _expiry = [NSDate dateWithTimeIntervalSinceNow:timeout];
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

@end
