//
//  UMSCCP_MTP3RoutingTable.m
//  ulibsccp
//
//  Created by Andreas Fink on 18.02.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_MTP3RoutingTable.h"
#import "UMSCCP_MTP3Route.h"

@implementation UMSCCP_MTP3RoutingTable


- (UMSCCP_MTP3RoutingTable *)init
{
    self = [super init];
    if(self)
    {
        _lock = [[UMMutex alloc]initWithName:@"mtp3-routing-table-lock"];
        _routes = [[NSMutableDictionary alloc]init];
    }
    return self;
}


- (UMSCCP_MTP3Route *)routeForPointCode:(UMMTP3PointCode *)pc
{
    NSString *key = [pc stringValue];
    [_lock lock];
    UMSCCP_MTP3Route *r = _routes[key];
    if(r==0)
    {
        r =  [[UMSCCP_MTP3Route alloc]init];
        r.dpc = pc;
        r.status = UMMTP3_ROUTE_UNKNOWN;
        r.congestion = UMMTP3_CONGESTION_LEVEL_0;
        _routes[key] = r;
    }
    [_lock unlock];
    return r;
}



@end
