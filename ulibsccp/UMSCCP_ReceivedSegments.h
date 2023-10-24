//
//  UMSCCP_ReceivedSegments.h
//  ulibsccp
//
//  Created by Andreas Fink on 30.04.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibmtp3/ulibmtp3.h>
#import <ulibgt/ulibgt.h>
#import <ulibsccp/UMSCCP_Segment.h>

#define MAX_SEGMENTS 16 /* the first + 0...15 remaining ones */

#define MAKE_SEGMENT_KEY(src,dst,ref)  [NSString stringWithFormat:@"src=%@ dst=%@ ref=%06lx", src.stringValueE164, dst.stringValueE164,ref]

@class UMSCCP_ReceivedSegment;

@interface UMSCCP_ReceivedSegments : UMObject
{
    NSDate                  *_created;
    SccpAddress             *_src;
    SccpAddress             *_dst;
    int                     _reference;
    UMSCCP_ReceivedSegment  *_rxSegments[MAX_SEGMENTS];
    int                     _max;
    int                     _current;
    NSDate                  *_firstPacket;
    UMMutex                 *_segmentsLock;
    NSString                *_key;
}

@property(readwrite,strong) NSDate      *create;
@property(readwrite,strong) SccpAddress *src;
@property(readwrite,strong) SccpAddress *dst;
@property(readwrite,assign) int         reference;
@property(readwrite,assign) int         max;
@property(readwrite,strong) NSDate      *firstPacket;

- (NSString *)key;
- (NSData *) reassembledData; /* returns NULL if not all segments have been received yet */
- (BOOL)processReceivedSegment:(UMSCCP_ReceivedSegment *)s; /* returns YES in case of segmentation error */
- (NSArray<UMSCCP_ReceivedSegment *> *)allSegments;
- (BOOL)isComplete;
- (UMSynchronizedSortedDictionary *)jsonObject;

@end
