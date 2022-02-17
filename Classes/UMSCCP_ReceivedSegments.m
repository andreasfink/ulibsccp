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
#import "UMSCCP_ReceivedSegment.h"

@implementation UMSCCP_ReceivedSegments

- (UMSCCP_ReceivedSegments *) init
{
    self = [super init];
    if(self)
    {
        _created = [NSDate date];
        _max = -1;
        _lock = [[UMMutex alloc]initWithName:@"received-segments"];
        _key = NULL;
    }
    return self;
}

- (NSString *)key
{
    return MAKE_SEGMENT_KEY(_src,_dst,_reference);
}

- (NSData *)reassembledData
{
    UMMUTEX_LOCK(_lock);
    NSMutableData *d = [[NSMutableData alloc]init];
    int i = MAX_SEGMENTS;
    while(i>0)
    {
        i--;
        UMSCCP_Segment *s = _segments[i];
        if(s==NULL)
        {
            return NULL;
        }
        NSMutableData *d2 = [s.data mutableCopy];
        [d2 appendData:d];
        d = d2;
        if(s.first)
        {
            UMMUTEX_UNLOCK(_lock);
            return d;
        }
    }
    UMMUTEX_UNLOCK(_lock);
    return NULL;
}

- (void)addSegment:(UMSCCP_Segment *)s
{
    UMMUTEX_LOCK(_lock);
    int index = MAX_SEGMENTS - s.remainingSegment -1;
    if(index>=0)
    {
        _segments[index] = s;
    }
    UMMUTEX_UNLOCK(_lock);
}

- (BOOL)processReceivedSegment:(UMSCCP_ReceivedSegment *)s
{
    UMMUTEX_LOCK(_lock);
    int current = 0; /* value from 0...15 */
    if(s.segment.first)
    {
        _firstPacket = [NSDate date];
        /* max is 1 ... 16 */
        s.max = s.segment.remainingSegment + 1;
        _max = s.max;
        _src = s.src;
        _dst = s.dst;
        _reference = s.reference;
    }
    else
    {
        current = s.max - 1 - s.segment.remainingSegment;
        if((current < 0) || (current >15))
        {
            /* somethings odd here */
            UMMUTEX_UNLOCK(_lock);
            return YES;
        }
    }
    _rxSegments[current] = s;
    _segments[current] = s.segment;
    UMMUTEX_UNLOCK(_lock);
    return NO;
}

- (BOOL) isComplete
{
    if(_max < 0)
    {
        return NO;
    }
    for(int i=0;i<_max;i++)
    {
        if(_rxSegments[i] == NULL)
        {
            return NO;
        }
    }
    return YES;
}


- (NSArray<UMSCCP_ReceivedSegment *> *)allSegments
{
    UMMUTEX_LOCK(_lock);
    NSMutableArray *a = [[NSMutableArray alloc]init];
    for(int i=0;i<_max;i++)
    {
        [a addObject:_rxSegments[i]];
    }
    UMMUTEX_UNLOCK(_lock);
    return a;
}

- (UMSynchronizedSortedDictionary *)jsonObject
{
    
    UMSynchronizedSortedDictionary *r = [[UMSynchronizedSortedDictionary alloc]init];
    if(_created)
    {
        r[@"created"] = _created;
    }
    if(_src)
    {
        r[@"src"] = _src;
    }
   if(_dst)
    {
        r[@"dst"] = _dst;
    }
    r[@"reference"] = @(_reference);
    r[@"max"] = @(_max);
    r[@"is-complete"] = @(_isComplete);
    if(_firstPacket)
    {
        r[@"first-packet"] = _firstPacket;
    }
    if(_key)
    {
        r[@"key"] = _key;
    }
    return r;
}

@end
