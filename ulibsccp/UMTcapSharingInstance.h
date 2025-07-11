//
//  UMTcapSharingInstance.h
//  ulibsccp
//
//  Created by Andreas Fink on 11.07.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>


@interface UMTcapSharingInstance : UMBackgrounder
{
    NSNumber *_timeout;
}
@property(readwrite,strong,atomic)  NSNumber *timeout;

- (UMTcapSharingInstance *)initWithConfig:(NSDictionary *)config;

@end

