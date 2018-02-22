//
//  UMSCCP_MTP3Route.m
//  ulibsccp
//
//  Created by Andreas Fink on 18.02.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_MTP3Route.h"

@implementation UMSCCP_MTP3Route


- (UMSCCP_MTP3Route *)init
{
    self = [super init];
    if(self)
    {
        _speedometer = [[UMThroughputCounter alloc]init];
    }
    return self;
}



UMMTP3PointCode             *_dpc;
UMMTP3RouteStatus           _status;
UMMTP3RouteCongestionLevel  _congestion;
UMThroughputCounter         *_speedometer;

- (void)pause
{
    _status = UMMTP3_ROUTE_PROHIBITED;
}

- (void)resume
{
    _status = UMMTP3_ROUTE_ALLOWED;

}

- (void)congestion:(UMMTP3RouteCongestionLevel)level
{
    _congestion =level;
    if(level == UMMTP3_CONGESTION_LEVEL_0)
    {
        _status = UMMTP3_ROUTE_ALLOWED;
    }
    else
    {
        _status = UMMTP3_ROUTE_RESTRICTED;
    }
}
@end
