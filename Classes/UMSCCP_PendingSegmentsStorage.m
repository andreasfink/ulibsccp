//
//  UMSCCP_PendingSegmentsStorage.m
//  ulibsccp
//
//  Created by Andreas Fink on 16.02.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_PendingSegmentsStorage.h"
#import "UMSCCP_ReceivedSegments.h"
#import "UMSCCP_ReceivedSegment.h"


//#define PENDING_SEGMENTS_DEBUG   1

@implementation UMSCCP_PendingSegmentsStorage

- (UMSCCP_PendingSegmentsStorage *)init
{
    self = [super init];
    if(self)
    {
        _lock = [[UMMutex alloc]initWithName:@"pending-segments-storage"];
        _receivedSegmentsByKey = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (NSArray <UMSCCP_ReceivedSegment *> *)processReceivedSegment:(UMSCCP_ReceivedSegment *)s
{
    UMMUTEX_LOCK(_lock);
    NSString *key = [s key];
#ifdef  PENDING_SEGMENTS_DEBUG
    NSLog(@"Key: %@",key);
#endif

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
#ifdef  PENDING_SEGMENTS_DEBUG
    NSLog(@"complete = NO");
#endif

        segments = [segs allSegments];
#ifdef  PENDING_SEGMENTS_DEBUG
        NSLog(@"removing key=%@",key);
#endif
        [_receivedSegmentsByKey removeObjectForKey:key];
    }
    else
    {
#ifdef  PENDING_SEGMENTS_DEBUG
        NSLog(@"complete = YES");
#endif
    }
    UMMUTEX_UNLOCK(_lock);
    return segments;
}

- (void)purge
{
    NSDate *now = [NSDate date];
    UMMUTEX_LOCK(_lock);
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
        NSLog(@"SCCP Multipart Keys to delete: %@",keysToDelete);
        for(NSString *key in keysToDelete)
        {
            [_receivedSegmentsByKey removeObjectForKey:key];
        }
    }
    UMMUTEX_UNLOCK(_lock);
}


- (UMSynchronizedSortedDictionary *)jsonObject
{
    UMSynchronizedSortedDictionary *r = [[UMSynchronizedSortedDictionary alloc]init];
    UMMUTEX_LOCK(_lock);
    for(NSString *key in [_receivedSegmentsByKey allKeys])
    {
        UMSCCP_ReceivedSegments *seg = _receivedSegmentsByKey[key];
        r[key] = [seg jsonObject];
    }
    UMMUTEX_UNLOCK(_lock);
    return r;
}

@end
