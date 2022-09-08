//
//  UMSCCP_StatisticData.h
//  ulibsccp
//
//  Created by Andreas Fink on 28.10.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>


@interface UMSCCP_StatisticData : UMObject
{
    NSUInteger      _count;
    NSTimeInterval  _sumOfWaitingDelays;
    NSTimeInterval  _sumOfProcessingDelays;

    NSTimeInterval  _maxWaiting;
    NSTimeInterval  _maxProcessing;
    NSTimeInterval  _minWaiting;
    NSTimeInterval  _minProcessing;
    UMMutex         *_sccpStatisticsDataLock;
}

@property(readwrite,assign,atomic)   NSUInteger      count;
@property(readwrite,assign,atomic)   NSTimeInterval  sumOfWaitingDelays;
@property(readwrite,assign,atomic)   NSTimeInterval  sumOfProcessingDelays;


- (void) addWaitingDelay:(NSTimeInterval)waitingDelay processingDelay:(NSTimeInterval)processingDelay;
- (UMSynchronizedSortedDictionary *)getStatDict;

@end

