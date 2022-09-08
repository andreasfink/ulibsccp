//
//  UMSCCP_StatisticData.m
//  ulibsccp
//
//  Created by Andreas Fink on 28.10.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_StatisticData.h"

@implementation UMSCCP_StatisticData


- (UMSCCP_StatisticData *)init
{
    self = [super init];
    if(self)
    {
        _sccpStatisticsDataLock = [[UMMutex alloc]initWithName:@"UMSCCP_StatisticData"];
    }
    return self;
}

- (void) addWaitingDelay:(NSTimeInterval)waitingDelay processingDelay:(NSTimeInterval)processingDelay
{
    [_sccpStatisticsDataLock lock];
    _count++;
    _sumOfWaitingDelays     += waitingDelay;
    _sumOfProcessingDelays  += processingDelay;

    if(waitingDelay >_maxWaiting)
    {
        _maxWaiting = waitingDelay;
    }
    if(processingDelay >_maxProcessing)
    {
        _maxProcessing = processingDelay;
    }
    if((_minWaiting==0) || (_minWaiting > waitingDelay))
    {
        _minWaiting = waitingDelay;
    }
    if((_minProcessing==0) || (_minProcessing > processingDelay))
    {
        _minProcessing = processingDelay;
    }
    [_sccpStatisticsDataLock unlock];
}


- (UMSynchronizedSortedDictionary *)getStatDict
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"min-processing"] = @(_minProcessing);
    dict[@"min-waiting"] = @(_minWaiting);
    dict[@"max-processing"] = @(_maxProcessing);
    dict[@"max-waiting"] = @(_maxWaiting);
    dict[@"average-waiting"] = @ ( _count ? (_sumOfWaitingDelays/_count) : 0);
    dict[@"average-processing"] = @ ( _count ? (_sumOfProcessingDelays/_count) : 0);
    return dict;
}

@end
