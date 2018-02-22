//
//  UMSCCP_MTP3Route.h
//  ulibsccp
//
//  Created by Andreas Fink on 18.02.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibmtp3/ulibmtp3.h>

@class UMSCCP_MTP3Provider;

@interface UMSCCP_MTP3Route : UMObject
{
    UMMTP3PointCode             *_dpc;
    UMMTP3RouteStatus           _status;
    UMMTP3RouteCongestionLevel  _congestion;
    UMThroughputCounter         *_speedometer;
}

@property(readwrite,strong,atomic)  UMMTP3PointCode             *dpc;
@property(readwrite,assign,atomic)  UMMTP3RouteStatus           status;
@property(readwrite,assign,atomic)  UMMTP3RouteCongestionLevel  congestion;
@property(readwrite,strong,atomic)  UMThroughputCounter         *speedometer;

- (void)pause;
- (void)resume;
- (void)congestion:(UMMTP3RouteCongestionLevel)level;

@end
