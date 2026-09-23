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

#import <ulibsccp/UMSCCP_ReceivedSegments.h>
#import <ulibsccp/UMSCCP_ReceivedSegment.h>

#define SEGMENTATION_DEBUG  1

@implementation UMSCCP_ReceivedSegments

- (UMSCCP_ReceivedSegments *) init
{
    self = [super init];
    if(self)
    {
        _created = [NSDate date];
        _max = -1;
        _segmentsLock = [[UMMutex alloc]initWithName:@"received-segments"];
    }
    return self;
}

- (NSString *)key
{
    return [NSString stringWithFormat:@"%@/%@/%u", _src.stringValueE164, _dst.stringValueE164,_reference];
}

- (NSData *)reassembledData
{
    ummutex_lock(_segmentsLock);
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
    ummutex_unlock(_segmentsLock);
    return d;
}

- (BOOL)processReceivedSegment:(UMSCCP_ReceivedSegment *)s
{
    if(s==NULL)
    {
        return YES;
    }
    ummutex_lock(_segmentsLock);
    BOOL failure = NO;
    int current = 0; /* value from 0...15 */
    if((s.segment.first == NO) && (_rxSegments[0]==NULL))
    {
        /* we receive a secondary segment before receiving the first */
        /* We put it into a temporary waiting queue */
        if(_preFirstSegments==NULL)
        {
            _preFirstSegments = [[NSMutableArray alloc]init];
            [_preFirstSegments addObject:s];
        }
    }
    else
    {
        if(s.segment.first == YES)
        {
            _firstPacket = [NSDate date];
            /* max is 1 ... 16 */
            s.max = s.segment.remainingSegment + 1;
            _max = s.max;
            _src = s.src;
            _dst = s.dst;
            _reference = s.reference;
            current = 0;
            _rxSegments[current] = s;
            if(_preFirstSegments)
            {
                ummutex_unlock(_segmentsLock);
                for( UMSCCP_ReceivedSegment *s1 in _preFirstSegments)
                {
                    [self processReceivedSegment:s1];
                }
                ummutex_lock(_segmentsLock);
                _preFirstSegments = NULL;
            }
        }
        
        else
        {
            s.max = _max;
            current = _max - s.segment.remainingSegment - 1;
            if((current < 0) || (current >15))
            {
                /* somethings out of bounds */
                failure = YES;
            }
            else
            {
                _rxSegments[current] = s;
            }
        }
    }
    ummutex_unlock(_segmentsLock);
    return failure;
}

- (BOOL) isComplete
{
    BOOL returnValue = YES;
    ummutex_lock(_segmentsLock);
    if(_max > 0)
    {
        for(int i=0;i<_max;i++)
        {
            if(_rxSegments[i] == NULL)
            {
                returnValue = NO;
                break;
            }
        }
    }
    else
    {
        returnValue = NO;
    }
    ummutex_unlock(_segmentsLock);
    return returnValue;
}


- (NSArray<UMSCCP_ReceivedSegment *> *)allSegments
{
    ummutex_lock(_segmentsLock);
    NSMutableArray *a = [[NSMutableArray alloc]init];
    for(int i=0;i<_max;i++)
    {
        [a addObject:_rxSegments[i]];
    }
    ummutex_unlock(_segmentsLock);
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
    r[@"key"] = self.key;
    return r;
}

@end
