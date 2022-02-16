//
//  UMSCCP_ReceivedSegment.m
//  ulibsccp
//
//  Created by Andreas Fink on 16.02.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_ReceivedSegment.h"

@implementation UMSCCP_ReceivedSegment


- (NSString *)key
{
    return [[NSMutableString alloc]initWithFormat:@"%@->%@(%06X:%02x",_src,_dst,_reference,_sls];
}
@end

