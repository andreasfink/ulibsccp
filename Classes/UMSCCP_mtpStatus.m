//
//  UMSCCP_mtpStatus.m
//  ulibsccp
//
//  Created by Andreas Fink on 05.04.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMSCCP_mtpStatus.h"
#import "UMLayerSCCP.h"
#import "UMSCCP_MTP3Route.h"
@implementation UMSCCP_mtpStatus

- (UMSCCP_mtpStatus *)initForSccp:(UMLayerSCCP *)layer
                             mtp3:(UMLayerMTP3 *)mtp3
                affectedPointCode:(UMMTP3PointCode *)affPC
                           status:(int)s
                               si:(int)xsi
                               ni:(int)xni
                          options:(NSDictionary *)xoptions

{
    self = [super initWithName:@"UMSCCP_mtpStatus" receiver:layer sender:mtp3 requiresSynchronisation:NO];
    if(self)
    {
        affectedPointCode = affPC;
        status = s;
        si = xsi;
        ni = xni;
        options = xoptions;
        _sccp = layer;
    }
    return self;
}

- (void)main
{
    /* FIXME: update SCCP MTP3 routing table view
    UMSCCP_MTP3Route *r = [sccp.routingTable routeForPointCode:affPC];
    [r status:status];

     */
}

@end
