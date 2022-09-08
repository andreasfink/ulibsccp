//
//  UMSCCP_Statistics.h
//  ulibsccp
//
//  Created by Andreas Fink on 28.10.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import "UMSCCP_StatisticData.h"

#define UMSCCP_STATISTICS_TIMESPAN_5SEC_COUNT       12
#define UMSCCP_STATISTICS_TIMESPAN_ONEMIN_COUNT     10
#define UMSCCP_STATISTICS_TIMESPAN_TENMIN_COUNT     12
#define UMSCCP_STATISTICS_TIMESPAN_TWOHOURS_COUNT   12
#define UMSCCP_STATISTICS_TIMESPAN_DAY_COUNT        400

@interface UMSCCP_Statistics : UMObject
{
    UMMutex               *_statisticsLock;
    UMSCCP_StatisticData  *_fiveSeconds[UMSCCP_STATISTICS_TIMESPAN_5SEC_COUNT];
    UMSCCP_StatisticData  *_oneMinute[UMSCCP_STATISTICS_TIMESPAN_ONEMIN_COUNT];
    UMSCCP_StatisticData  *_tenMinutes[UMSCCP_STATISTICS_TIMESPAN_TENMIN_COUNT];
    UMSCCP_StatisticData  *_twoHours[UMSCCP_STATISTICS_TIMESPAN_TWOHOURS_COUNT];
    UMSCCP_StatisticData  *_oneDay[UMSCCP_STATISTICS_TIMESPAN_DAY_COUNT];
    NSDate                *_lastEvent;
    NSUInteger            _indexFiveSec;
    NSUInteger            _indexOneMin;
    NSUInteger            _indexTenMin;
    NSUInteger            _indexTwoHours;
    NSUInteger            _indexOneDay;
}

- (void) addWaitingDelay:(NSTimeInterval)waitingDelay processingDelay:(NSTimeInterval)processingDelay;
- (UMSynchronizedSortedDictionary *)getStatDict;

@end

