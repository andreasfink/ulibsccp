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

//#define SEGMENTATION_DEBUG  1

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
    return [NSString stringWithFormat:@"%@/%@/%06lx", src.stringValueE164, dst.stringValueE164,ref];
}

- (NSData *)reassembledData
{
    UMMUTEX_LOCK(_lock);
    NSMutableData *d = [[NSMutableData alloc]init];
    for(int i=0;i<_max;i++)
    {
        NSMutableData *d2 = [_rxSegments[i].segment.data mutableCopy];
        if(d2==NULL)
        {
            return NULL;
        }
        [d appendData:d2];
    }
    UMMUTEX_UNLOCK(_lock);
    return d;
}

/*
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
*/

- (BOOL)processReceivedSegment:(UMSCCP_ReceivedSegment *)s
{
    UMMUTEX_LOCK(_lock);
    int current = 0; /* value from 0...15 */

#ifdef SEGMENTATION_DEBUG
    if(s.segment == NULL)
    {
        NSLog(@"s.segment = NULL");
    }
#endif

    if(s.segment.first == YES)
    {
#ifdef SEGMENTATION_DEBUG
        NSLog(@"first packet = YES");
#endif
        _firstPacket = [NSDate date];
        /* max is 1 ... 16 */
        s.max = s.segment.remainingSegment + 1;
        _max = s.max;
        _src = s.src;
        _dst = s.dst;
        _reference = s.reference;
        current = 0;
        _rxSegments[current] = s;
        
        NSLog(@"s.segment.remainingSegment = %d",s.segment.remainingSegment);
        NSLog(@"current = %d,s.max=%d, _max=%d",current,s.max,_max);

    }
    else
    {
#ifdef SEGMENTATION_DEBUG
        NSLog(@"first packet = NO");
#endif
        s.max = _max;
        current = _max - s.segment.remainingSegment - 1;

#ifdef SEGMENTATION_DEBUG
        NSLog(@"s.segment.remainingSegment = %d",s.segment.remainingSegment);
        NSLog(@"current = %d,s.max=%d, _max=%d",current,s.max,_max);
#endif
        if((current < 0) || (current >15))
        {
#ifdef SEGMENTATION_DEBUG
            NSLog(@"current is out of bounds");
#endif
            /* somethings odd here */
            UMMUTEX_UNLOCK(_lock);
            return YES;
        }
    }
    _rxSegments[current] = s;
//    _segments[current] = s.segment;
    UMMUTEX_UNLOCK(_lock);
    return NO;
}

- (BOOL) isComplete
{
    
#ifdef SEGMENTATION_DEBUG
    NSLog(@"isComplete is called. max = %d",_max);
    for(int i=0;i<16;i++)
    {
        NSLog(@" _rxSegments[%d] = %@",i,_rxSegments[i]);
    }
#endif
    
    if(_max < 0)
    {
#ifdef SEGMENTATION_DEBUG
        NSLog(@" returning NO (max<0)");
#endif
        return NO;
    }
    for(int i=0;i<_max;i++)
    {

        if(_rxSegments[i] == NULL)
        {
#ifdef SEGMENTATION_DEBUG
            NSLog(@" returning NO");
#endif
            return NO;
        }
    }
#ifdef SEGMENTATION_DEBUG
    NSLog(@" returning YES");
#endif
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
    r[@"is-complete"] = @(self.isComplete);
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
