//
//  UMSCCP_MTP3RoutingTable.h
//  ulibsccp
//
//  Created by Andreas Fink on 18.02.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibmtp3/ulibmtp3.h>

@class UMSCCP_MTP3Route;

@interface UMSCCP_MTP3RoutingTable : UMObject
{
    NSMutableDictionary *_routes; /* key is [pointcode stringValue] */
    UMMutex *_lock;
}

- (UMSCCP_MTP3Route *)routeForPointCode:(UMMTP3PointCode *)pc;

@end
