//
//  UMSCCP_PrometheusData.m
//  ulibsccp
//
//  Created by Andreas Fink on 24.06.21.
//  Copyright © 2021 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_PrometheusData.h"
#import "UMSCCP_StatisticSection.h"

@implementation UMSCCP_PrometheusData


- (UMSCCP_PrometheusData *)initWithPrometheus:(UMPrometheus *)prometheus
{
    self = [super init];
    if(self)
    {
        _prometheus = prometheus;
        _lock = [[UMMutex alloc]initWithName:@"UMSCCP_PrometheusData"];
        
        _rxCounter = [[UMPrometheusMetric alloc]initWithMetricName:@"sccp_rx"
                                                            subname1:NULL
                                                           subvalue1:NULL
                                                                type:UMPrometheusMetricType_counter];
        _txCounter = [[UMPrometheusMetric alloc]initWithMetricName:@"sccp_tx"
                                                            subname1:NULL
                                                           subvalue1:NULL
                                                                type:UMPrometheusMetricType_counter];
        _transitCounter = [[UMPrometheusMetric alloc]initWithMetricName:@"sccp_transit"
                                                            subname1:NULL
                                                           subvalue1:NULL
                                                                type:UMPrometheusMetricType_counter];

        /* UDT */
        _udtRxCounter = [[UMPrometheusMetric alloc]initWithMetricName:@"sccp_rx_udt"
                                                            subname1:NULL
                                                           subvalue1:NULL
                                                                type:UMPrometheusMetricType_counter];
        _udtRxCounter.help = @"count of received UDT packets";

        _udtTxCounter = [[UMPrometheusMetric alloc]initWithMetricName:@"sccp_tx_udt"
                                                            subname1:NULL
                                                           subvalue1:NULL
                                                                type:UMPrometheusMetricType_counter];
        _udtTxCounter.help = @"count of sent UDT packets";
        
        _udtTransitCounter = [[UMPrometheusMetric alloc]initWithMetricName:@"sccp_transit_udt"
                                                            subname1:NULL
                                                           subvalue1:NULL
                                                                type:UMPrometheusMetricType_counter];
        _udtTransitCounter.help = @"count of transited UDT packets";

        /* UDTS */

        _udtsRxCounter = [[UMPrometheusMetric alloc]initWithMetricName:@"sccp_rx_udts"
                                                            subname1:NULL
                                                           subvalue1:NULL
                                                                type:UMPrometheusMetricType_counter];
        _udtsRxCounter.help = @"count of received UDT packets";

        _udtsTxCounter = [[UMPrometheusMetric alloc]initWithMetricName:@"sccp_tx_udts"
                                                            subname1:NULL
                                                           subvalue1:NULL
                                                                type:UMPrometheusMetricType_counter];
        _udtsTxCounter.help = @"count of sent UDT packets";
        
        _udtsTransitCounter = [[UMPrometheusMetric alloc]initWithMetricName:@"sccp_transit_udts"
                                                            subname1:NULL
                                                           subvalue1:NULL
                                                                type:UMPrometheusMetricType_counter];
        _udtsTransitCounter.help = @"count of transited UDT packets";

        /* XUDTS */

        _xudtRxCounter = [[UMPrometheusMetric alloc]initWithMetricName:@"sccp_rx_xudt"
                                                            subname1:NULL
                                                           subvalue1:NULL
                                                                type:UMPrometheusMetricType_counter];
        _xudtRxCounter.help = @"count of received UDT packets";

        _xudtTxCounter = [[UMPrometheusMetric alloc]initWithMetricName:@"sccp_tx_xudt"
                                                            subname1:NULL
                                                           subvalue1:NULL
                                                                type:UMPrometheusMetricType_counter];
        _xudtTxCounter.help = @"count of sent UDT packets";
        
        _xudtTransitCounter = [[UMPrometheusMetric alloc]initWithMetricName:@"sccp_transit_xudt"
                                                            subname1:NULL
                                                           subvalue1:NULL
                                                                type:UMPrometheusMetricType_counter];
        _xudtTransitCounter.help = @"count of transited UDT packets";

        /* XUDTS */

        _xudtsRxCounter = [[UMPrometheusMetric alloc]initWithMetricName:@"sccp_rx_xudts"
                                                            subname1:NULL
                                                           subvalue1:NULL
                                                                type:UMPrometheusMetricType_counter];
        _xudtsRxCounter.help = @"count of received UDT packets";

        _xudtsTxCounter = [[UMPrometheusMetric alloc]initWithMetricName:@"sccp_tx_xudts"
                                                            subname1:NULL
                                                           subvalue1:NULL
                                                                type:UMPrometheusMetricType_counter];
        _xudtsTxCounter.help = @"count of sent UDT packets";
        
        _xudtsTransitCounter = [[UMPrometheusMetric alloc]initWithMetricName:@"sccp_transit_xudts"
                                                            subname1:NULL
                                                           subvalue1:NULL
                                                                type:UMPrometheusMetricType_counter];
        _xudtsTransitCounter.help = @"count of transited UDT packets";


        _throughput = [[UMPrometheusThroughputMetric alloc]initWithResolutionInSeconds:0.1
                                                                        reportDuration:10.0
                                                                                  name:@"sccp_throughput"
                                                                              subname1:NULL
                                                                             subvalue1:NULL];
        for(int i=0;i<256;i++)
        {
            NSString *s = @"sccp_transit_gsm";
            UMPrometheusMetric *m =  [[UMPrometheusMetric alloc]initWithMetricName:s subname1:NULL subvalue1:NULL type:UMPrometheusMetricType_counter];
            m.subname2 = @"mapop";
            m.subvalue2 = [NSString stringWithFormat:@"%d",i];
            m.help = @"counter of GSM_MAP operations transiting the system";
            _transitCounterPerMapOperation[i] = m;
            
            s = @"sccp_rx_gsmp";
            m =  [[UMPrometheusMetric alloc]initWithMetricName:s subname1:NULL subvalue1:NULL type:UMPrometheusMetricType_counter];
            m.subname2 = @"mapop";
            m.subvalue2 = [NSString stringWithFormat:@"%d",i];
            m.help = @"counter of GSM_MAP operations received on the system";
            _rxCounterPerMapOperation[i] = m;


            s = @"sccp_tx_gsm";
            m =  [[UMPrometheusMetric alloc]initWithMetricName:s subname1:NULL subvalue1:NULL type:UMPrometheusMetricType_counter];
            m.subname2 = @"mapop";
            m.subvalue2 = [NSString stringWithFormat:@"%d",i];
            m.help = @"counter of GSM_MAP operations transiting the system";
            _txCounterPerMapOperation[i] = m;
        }

    }
    return self;
}

_ (void)setSubname1:(NSString *)a value:(NSString *)b
{
    [_rxCounter setSubname1:a value:b];
    [_txCounter setSubname1:a value:b];
    [_transitCounter setSubname1:a value:b];
    [_udtRxCounter setSubname1:a value:b];
    [_udtTxCounter setSubname1:a value:b];
    [_udtTransitCounter setSubname1:a value:b];
    [_udtsRxCounter setSubname1:a value:b];
    [_udtsTxCounter setSubname1:a value:b];
    [_udtsTransitCounter setSubname1:a value:b];
    [_xudtRxCounter setSubname1:a value:b];
    [_xudtTxCounter setSubname1:a value:b];
    [_xudtTransitCounter setSubname1:a value:b];
    [_xudtsRxCounter setSubname1:a value:b];
    [_xudtsTxCounter setSubname1:a value:b];
    [_xudtsTransitCounter setSubname1:a value:b];
    [_transitCounter setSubname1:a value:b];
    for(int i=0;i<256;i++)
    {
        [_transitCounterPerMapOperation[i]  setSubname1:a value:b];
        [_rxCounterPerMapOperation[i]  setSubname1:a value:b];
        [_txCounterPerMapOperation[i] setSubname1:a value:b];
    }
}

- (void)registerMetrics
{
    [_prometheus addObject:_rxCounter forKey:_rxCounter.key];
    [_prometheus addObject:_txCounter forKey:_txCounter.key];
    [_prometheus addObject:_transitCounter forKey:_transitCounter.key];
    [_prometheus addObject:_udtRxCounter forKey:_udtRxCounter.key];
    [_prometheus addObject:_udtTxCounter forKey:_udtTxCounter.key];
    [_prometheus addObject:_udtTransitCounter forKey:_udtTransitCounter.key];
    [_prometheus addObject:_udtsRxCounter forKey:_udtsRxCounter.key];
    [_prometheus addObject:_udtsTxCounter forKey:_udtsTxCounter.key];
    [_prometheus addObject:_udtsTransitCounter forKey:_udtsTransitCounter.key];
    [_prometheus addObject:_xudtRxCounter forKey:_xudtRxCounter.key];
    [_prometheus addObject:_xudtTxCounter forKey:_xudtTxCounter.key];
    [_prometheus addObject:_xudtTransitCounter forKey:_xudtTransitCounter.key];
    [_prometheus addObject:_xudtsRxCounter forKey:_xudtsRxCounter.key];
    [_prometheus addObject:_xudtsTxCounter forKey:_xudtsTxCounter.key];
    [_prometheus addObject:_xudtsTransitCounter forKey:_xudtsTransitCounter.key];
    [_prometheus addObject:_transitCounter forKey:_transitCounter.key];
    for(int i=0;i<256;i++)
    {
        [_prometheus addObject:_transitCounterPerMapOperation[i] forKey:_transitCounterPerMapOperation[i].key];
        [_prometheus addObject:_rxCounterPerMapOperation[i] forKey:_rxCounterPerMapOperation[i].key];
        [_prometheus addObject:_txCounterPerMapOperation[i] forKey:_txCounterPerMapOperation[i].key];
    }
}

- (void)unregisterMetrics
{
    [_prometheus removeObjectForKey:_rxCounter.key];
    [_prometheus removeObjectForKey:_txCounter.key];
    [_prometheus removeObjectForKey:_transitCounter.key];
    [_prometheus removeObjectForKey:_udtRxCounter.key];
    [_prometheus removeObjectForKey:_udtTxCounter.key];
    [_prometheus removeObjectForKey:_udtTransitCounter.key];
    [_prometheus removeObjectForKey:_udtsRxCounter.key];
    [_prometheus removeObjectForKey:_udtsTxCounter.key];
    [_prometheus removeObjectForKey:_udtsTransitCounter.key];
    [_prometheus removeObjectForKey:_xudtRxCounter.key];
    [_prometheus removeObjectForKey:_xudtTxCounter.key];
    [_prometheus removeObjectForKey:_xudtTransitCounter.key];
    [_prometheus removeObjectForKey:_xudtsRxCounter.key];
    [_prometheus removeObjectForKey:_xudtsTxCounter.key];
    [_prometheus removeObjectForKey:_xudtsTransitCounter.key];
    [_prometheus removeObjectForKey:_transitCounter.key];
    for(int i=0;i<256;i++)
    {
        [_prometheus removeObjectForKey:_transitCounterPerMapOperation[i].key];
        [_prometheus removeObjectForKey:_rxCounterPerMapOperation[i].key];
        [_prometheus removeObjectForKey:_txCounterPerMapOperation[i].key];
    }
}

- (void)increaseMapCounter:(UMSCCP_StatisticSection)section operations:(NSArray <NSNumber *> *)ops
{
    for(NSNumber *n in ops)
    {
        int i = [n intValue];
        if((i>0) && (i<256))
        {
            switch(section)
            {
                case UMSCCP_StatisticSection_RX:
                    [_rxCounterPerMapOperation[i]  increaseBy:1];
                    break;
                case UMSCCP_StatisticSection_TX:
                    [_txCounterPerMapOperation[i]  increaseBy:1];
                    break;
                case UMSCCP_StatisticSection_TRANSIT:
                    [_transitCounterPerMapOperation[i]  increaseBy:1];
                    break;
                default:
                    break;
            }
        }
    }
}

@end
