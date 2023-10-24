//
//  UMSCCP_PrometheusData.h
//  ulibsccp
//
//  Created by Andreas Fink on 24.06.21.
//  Copyright © 2021 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>

#import <ulibsccp/UMSCCP_StatisticSection.h>

@interface UMSCCP_PrometheusData : UMObject
{
    UMMutex                       *_prometheusLock;;
    UMPrometheus                  *_prometheus;
    /* generic */
    UMPrometheusMetric            *_rxCounter;
    UMPrometheusMetric            *_txCounter;
    UMPrometheusMetric            *_transitCounter;

    UMPrometheusMetric            *_udtRxCounter;
    UMPrometheusMetric            *_udtTxCounter;
    UMPrometheusMetric            *_udtTransitCounter;

    UMPrometheusMetric            *_udtsRxCounter;
    UMPrometheusMetric            *_udtsTxCounter;
    UMPrometheusMetric            *_udtsTransitCounter;

    UMPrometheusMetric            *_xudtRxCounter;
    UMPrometheusMetric            *_xudtTxCounter;
    UMPrometheusMetric            *_xudtTransitCounter;

    UMPrometheusMetric            *_xudtsRxCounter;
    UMPrometheusMetric            *_xudtsTxCounter;
    UMPrometheusMetric            *_xudtsTransitCounter;
    UMPrometheusMetric            *_transitCounterPerMapOperation[256];
    UMPrometheusMetric            *_rxCounterPerMapOperation[256];
    UMPrometheusMetric            *_txCounterPerMapOperation[256];
    UMPrometheusThroughputMetric  *_throughput;
}

@property(readwrite,strong) UMPrometheus                  *prometheus;

@property(readwrite,strong) UMPrometheusMetric            *rxCounter;
@property(readwrite,strong) UMPrometheusMetric            *txCounter;
@property(readwrite,strong) UMPrometheusMetric            *transitCounter;
@property(readwrite,strong) UMPrometheusMetric            *udtRxCounter;
@property(readwrite,strong) UMPrometheusMetric            *udtTxCounter;
@property(readwrite,strong) UMPrometheusMetric            *udtTransitCounter;
@property(readwrite,strong) UMPrometheusMetric            *udtsRxCounter;
@property(readwrite,strong) UMPrometheusMetric            *udtsTxCounter;
@property(readwrite,strong) UMPrometheusMetric            *udtsTransitCounter;
@property(readwrite,strong) UMPrometheusMetric            *xudtRxCounter;
@property(readwrite,strong) UMPrometheusMetric            *xudtTxCounter;
@property(readwrite,strong) UMPrometheusMetric            *xudtTransitCounter;
@property(readwrite,strong) UMPrometheusMetric            *xudtsRxCounter;
@property(readwrite,strong) UMPrometheusMetric            *xudtsTxCounter;
@property(readwrite,strong) UMPrometheusMetric            *xudtsTransitCounter;
@property(readwrite,strong) UMPrometheusThroughputMetric  *throughput;


- (UMSCCP_PrometheusData *)initWithPrometheus:(UMPrometheus *)prometheus;
- (void)setSubname1:(NSString *)a value:(NSString *)b;
- (void)registerMetrics;
- (void)unregisterMetrics;
- (void)increaseMapCounter:(UMSCCP_StatisticSection)section operations:(NSArray <NSNumber *> *)ops;


@end

