//
//  UMSCCP_PendingSegmentsStorage.h
//  ulibsccp
//
//  Created by Andreas Fink on 16.02.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>

@class UMSCCP_ReceivedSegments;
@class UMSCCP_ReceivedSegment;

@interface UMSCCP_PendingSegmentsStorage : UMObject
{
    UMMutex                                             *_pendingSegmentsLock;
    NSMutableDictionary<NSString *,UMSCCP_ReceivedSegments *>    *_receivedSegmentsByKey;
}

- (NSArray <UMSCCP_ReceivedSegment *>*)processReceivedSegment:(UMSCCP_ReceivedSegment *)s;

- (void)purge;
- (UMSynchronizedSortedDictionary *)jsonObject;

@end

