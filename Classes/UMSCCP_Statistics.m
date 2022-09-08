//
//  UMSCCP_Statistics.m
//  ulibsccp
//
//  Created by Andreas Fink on 28.10.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_Statistics.h"

@implementation UMSCCP_Statistics

- (UMSCCP_Statistics *)init
{
    self = [super init];
    if(self)
    {
        _statisticsLock = [[UMMutex alloc]initWithName:@"UMSCCP_Statistics"];

        for(NSUInteger i=0;i< UMSCCP_STATISTICS_TIMESPAN_5SEC_COUNT;i++)
        {
            _fiveSeconds[i] = [[UMSCCP_StatisticData alloc]init];
        }
        for(NSUInteger i=0;i< UMSCCP_STATISTICS_TIMESPAN_ONEMIN_COUNT;i++)
        {
            _oneMinute[i] = [[UMSCCP_StatisticData alloc]init];
        }
        for(NSUInteger i=0;i< UMSCCP_STATISTICS_TIMESPAN_TENMIN_COUNT;i++)
        {
            _tenMinutes[i] = [[UMSCCP_StatisticData alloc]init];
        }
        for(NSUInteger i=0;i< UMSCCP_STATISTICS_TIMESPAN_TWOHOURS_COUNT;i++)
        {
            _twoHours[i] = [[UMSCCP_StatisticData alloc]init];
        }
        for(NSUInteger i=0;i< UMSCCP_STATISTICS_TIMESPAN_DAY_COUNT;i++)
        {
            _oneDay[i] = [[UMSCCP_StatisticData alloc]init];
        }
        _lastEvent = [NSDate date];

    }
    return self;
}


- (void)timeShiftToDate:(NSDate *)date
{
    NSTimeInterval _interval = [[NSDate date]timeIntervalSinceDate:_lastEvent];

    NSUInteger indexFiveSecNow     = (long long)_interval / 5;
    NSUInteger indexOneMinNow      = (long long)_interval / 60;
    NSUInteger indexTenMinNow      = (long long)_interval / (60*10);
    NSUInteger indexTwoHoursNow    = (long long)_interval / (60*60*2);
    NSUInteger indexOneDayNow      = (long long)_interval / (60*60*24);

    int count = 0;
    while((_indexFiveSec < indexFiveSecNow) && (count++ < UMSCCP_STATISTICS_TIMESPAN_5SEC_COUNT))
    {
        _indexFiveSec++;
        _fiveSeconds[_indexFiveSec % UMSCCP_STATISTICS_TIMESPAN_5SEC_COUNT] = [[UMSCCP_StatisticData alloc]init];
    }
    count=0;
    while((_indexOneMin < indexOneMinNow) && (count++ < UMSCCP_STATISTICS_TIMESPAN_ONEMIN_COUNT))
    {
        _indexOneMin++;
        _oneMinute[_indexOneMin % UMSCCP_STATISTICS_TIMESPAN_ONEMIN_COUNT] = [[UMSCCP_StatisticData alloc]init];
    }
    count=0;
    while((_indexTenMin < indexTenMinNow ) && (count++ < UMSCCP_STATISTICS_TIMESPAN_TENMIN_COUNT))
    {
        _indexTenMin++;
        _tenMinutes[_indexTenMin % UMSCCP_STATISTICS_TIMESPAN_TENMIN_COUNT] = [[UMSCCP_StatisticData alloc]init];
    }
    count=0;
    while((_indexTwoHours < indexTwoHoursNow) && (count++ < UMSCCP_STATISTICS_TIMESPAN_TWOHOURS_COUNT))
    {
        _indexTwoHours++;
        _twoHours[_indexTwoHours % UMSCCP_STATISTICS_TIMESPAN_TWOHOURS_COUNT] = [[UMSCCP_StatisticData alloc]init];
    }
    count=0;
    while((_indexOneDay < indexOneDayNow) && (count++ < UMSCCP_STATISTICS_TIMESPAN_DAY_COUNT))
    {
        _indexOneDay++;
        _oneDay[_indexOneDay % UMSCCP_STATISTICS_TIMESPAN_DAY_COUNT] = [[UMSCCP_StatisticData alloc]init];
    }
}

- (void) addWaitingDelay:(NSTimeInterval)waitingDelay processingDelay:(NSTimeInterval)processingDelay
{
    [_statisticsLock lock];
    [self timeShiftToDate:[NSDate date]];
    [_fiveSeconds[_indexFiveSec % UMSCCP_STATISTICS_TIMESPAN_5SEC_COUNT] addWaitingDelay:waitingDelay processingDelay:processingDelay];
    [_oneMinute[_indexOneMin % UMSCCP_STATISTICS_TIMESPAN_ONEMIN_COUNT] addWaitingDelay:waitingDelay processingDelay:processingDelay];
    [_tenMinutes[_indexTenMin % UMSCCP_STATISTICS_TIMESPAN_TENMIN_COUNT] addWaitingDelay:waitingDelay processingDelay:processingDelay];
    [_twoHours[_indexTwoHours % UMSCCP_STATISTICS_TIMESPAN_TWOHOURS_COUNT] addWaitingDelay:waitingDelay processingDelay:processingDelay];
    [_oneDay[_indexOneDay % UMSCCP_STATISTICS_TIMESPAN_DAY_COUNT] addWaitingDelay:waitingDelay processingDelay:processingDelay];
    [_statisticsLock unlock];
}

- (UMSynchronizedSortedDictionary *)getStatDict
{
    [_statisticsLock lock];
    [self timeShiftToDate:[NSDate date]];

    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *dict5sec = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *dict1min = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *dict10min = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *dict2h = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *dict1d = [[UMSynchronizedSortedDictionary alloc]init];

    for(int i=0;i< UMSCCP_STATISTICS_TIMESPAN_5SEC_COUNT;i++)
    {
        UMSCCP_StatisticData *sd = _fiveSeconds[(_indexFiveSec + 1 + i) % UMSCCP_STATISTICS_TIMESPAN_5SEC_COUNT]; /* the current entry comes last */
        NSString *is = [NSString stringWithFormat:@"%d",i];
        dict5sec[is] = [sd getStatDict];
    }
    for(int i=0;i< UMSCCP_STATISTICS_TIMESPAN_ONEMIN_COUNT;i++)
    {
        UMSCCP_StatisticData *sd = _oneMinute[(_indexOneMin + i +1 ) % UMSCCP_STATISTICS_TIMESPAN_ONEMIN_COUNT];
        NSString *is = [NSString stringWithFormat:@"%d",i];
        dict1min[is] = [sd getStatDict];

    }
    for(int i=0;i< UMSCCP_STATISTICS_TIMESPAN_TENMIN_COUNT;i++)
    {
        UMSCCP_StatisticData *sd = _tenMinutes[(_indexTenMin + i + 1 ) % UMSCCP_STATISTICS_TIMESPAN_TENMIN_COUNT];
        NSString *is = [NSString stringWithFormat:@"%d",i];
        dict10min[is] = [sd getStatDict];

    }
    for(int i=0;i< UMSCCP_STATISTICS_TIMESPAN_TWOHOURS_COUNT;i++)
    {
        UMSCCP_StatisticData *sd = _twoHours[(_indexTwoHours+ i + 1 ) % UMSCCP_STATISTICS_TIMESPAN_TWOHOURS_COUNT];
        NSString *is = [NSString stringWithFormat:@"%d",i];
        dict2h[is] = [sd getStatDict];

    }
    for(int i=0;i< UMSCCP_STATISTICS_TIMESPAN_DAY_COUNT;i++)
    {
        UMSCCP_StatisticData *sd = _oneDay[(_indexOneDay+ i + 1 ) % UMSCCP_STATISTICS_TIMESPAN_DAY_COUNT];
        NSString *is = [NSString stringWithFormat:@"%d",i];
        dict1d[is] = [sd getStatDict];

    }
    [_statisticsLock unlock];
    dict[@"5s"] = dict5sec;
    dict[@"1m"] = dict1min;
    dict[@"10m"] = dict10min;
    dict[@"2h"] = dict2h;
    dict[@"1d"] = dict1d;
    return dict;
}

@end

