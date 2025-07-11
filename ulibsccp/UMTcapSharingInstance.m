//
//  UMTcapSharingInstance.m
//  ulibsccp
//
//  Created by Andreas Fink on 11.07.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMTcapSharingInstance.h"

@implementation UMTcapSharingInstance


- (UMTcapSharingInstance *)initWithConfig:(NSDictionary *)config
{
    NSString *name = config[@"name"];
    
    self = [super initWithName:name];
    if(self)
    {
        _timeout = config[@"timeout"];
    }
    return self;
}
@end
