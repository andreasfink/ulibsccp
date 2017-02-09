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
#import "UMSCCP_Segment.h"

#define MAX_SEGMENTS 16

#define MAKE_SEGMENT_KEY(src,dst,ref)  [NSString stringWithFormat:@"%@:%@:%06lx", src.encoded.hexString, dst.encoded.hexString, ref]


@interface UMSCCP_ReceivedSegments : UMObject
{
    NSDate *created;
    SccpAddress *src;
    SccpAddress *dst;
    long          ref;
    UMSCCP_Segment *segments[MAX_SEGMENTS]; /* this is populated from the last to the first */
    int max;
    int current;
}

@property(readwrite,strong) SccpAddress *src;
@property(readwrite,strong) SccpAddress *dst;
@property(readwrite,assign) long          ref;

- (NSString *) key;
- (NSData *) reassembledData; /* returns NULL if not all segments have been received yet */
- (void) addSegment:(UMSCCP_Segment *)s;


@end
