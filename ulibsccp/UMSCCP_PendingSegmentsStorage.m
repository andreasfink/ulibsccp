//
//  UMSCCP_PendingSegmentsStorage.m
//  ulibsccp
//
//  Created by Andreas Fink on 16.02.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibsccp/UMSCCP_PendingSegmentsStorage.h>
#import <ulibsccp/UMSCCP_ReceivedSegments.h>
#import <ulibsccp/UMSCCP_ReceivedSegment.h>


//#define PENDING_SEGMENTS_DEBUG   1

@implementation UMSCCP_PendingSegmentsStorage

- (UMSCCP_PendingSegmentsStorage *)init
{
    self = [super init];
    if(self)
    {
        _pendingSegmentsLock = [[UMMutex alloc]initWithName:@"pending-segments-storage"];
        _receivedSegmentsByKey = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (NSArray <UMSCCP_ReceivedSegment *> *)processReceivedSegment:(UMSCCP_ReceivedSegment *)s
{
    ummutex_lock(_pendingSegmentsLock);
    NSString *key = [s key];
    UMSCCP_ReceivedSegments *segs =  _receivedSegmentsByKey[key];
    if(segs == NULL)
    {
        segs = [[UMSCCP_ReceivedSegments alloc]init];
        _receivedSegmentsByKey[key] = segs;
    }
    [segs processReceivedSegment:s];
    _receivedSegmentsByKey[key] = segs;
    
    NSArray<UMSCCP_ReceivedSegment *> *segments = NULL;
    if([segs isComplete])
    {
        segments = [segs allSegments];
        [_receivedSegmentsByKey removeObjectForKey:key];
    }
    ummutex_unlock(_pendingSegmentsLock);
    return segments;
}

- (void)purge
{
    NSDate *now = [NSDate date];
    ummutex_lock(_pendingSegmentsLock);
    NSMutableArray *keysToDelete = [[NSMutableArray alloc]init];
    NSArray *allKeys = [_receivedSegmentsByKey allKeys];
    for(NSString *key in allKeys)
    {
        UMSCCP_ReceivedSegments *seg = _receivedSegmentsByKey[key];
        NSDate *start = seg.create;
        if(start)
        {
            NSTimeInterval delay = [now timeIntervalSinceDate:start];
            if(fabs(delay) > 30.0)
            {
                [keysToDelete addObject:key];
            }
        }
        else
        {
            seg.create = now;
        }
    }
    if(keysToDelete.count > 0)
    {
        for(NSString *key in keysToDelete)
        {
            [_receivedSegmentsByKey removeObjectForKey:key];
        }
    }
    ummutex_unlock(_pendingSegmentsLock);
}


- (UMSynchronizedSortedDictionary *)jsonObject
{
    UMSynchronizedSortedDictionary *r = [[UMSynchronizedSortedDictionary alloc]init];
    ummutex_lock(_pendingSegmentsLock);
    for(NSString *key in [_receivedSegmentsByKey allKeys])
    {
        UMSCCP_ReceivedSegments *seg = _receivedSegmentsByKey[key];
        r[key] = [seg jsonObject];
    }
    ummutex_unlock(_pendingSegmentsLock);
    return r;
}

@end
