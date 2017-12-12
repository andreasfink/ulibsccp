//
//  UMSCCP_ReceivedSegments.m
//  ulibsccp
//
//  Created by Andreas Fink on 30.04.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMSCCP_ReceivedSegments.h"

@implementation UMSCCP_ReceivedSegments


@synthesize src;
@synthesize dst;
@synthesize ref;

- (UMSCCP_ReceivedSegments *) init
{
    self = [super init];
    if(self)
    {
        created = [NSDate new];
    }
    return self;
}

- (NSString *)key
{
    return MAKE_SEGMENT_KEY(src,dst,ref);
}


- (NSData *)reassembledData
{
    NSMutableData *d = [[NSMutableData alloc]init];
    int i = MAX_SEGMENTS;
    while(i>0)
    {
        i--;
        UMSCCP_Segment *s = segments[i];
        if(s==NULL)
        {
            return NULL;
        }
        NSMutableData *d2 = [s.data mutableCopy];
        [d2 appendData:d];
        d = d2;
        if(s.first)
        {
            return d;
        }
    }
    return NULL;
}

- (void)addSegment:(UMSCCP_Segment *)s
{
    int index = MAX_SEGMENTS - s.remainingSegment -1;
    if(index>=0)
    {
        segments[index] = s;
    }
}

@end
