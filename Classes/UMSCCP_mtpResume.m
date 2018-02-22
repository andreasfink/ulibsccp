//
//  UMSCCP_mtpResume.m
//  ulibsccp
//
//  Created by Andreas Fink on 05.04.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMSCCP_mtpResume.h"
#import "UMLayerSCCP.h"

@implementation UMSCCP_mtpResume

- (UMSCCP_mtpResume *)initForSccp:(UMLayerSCCP *)layer
                             mtp3:(UMLayerMTP3 *)mtp3
                affectedPointCode:(UMMTP3PointCode *)affPC
                               si:(int)xsi
                               ni:(int)xni
                          options:(NSDictionary *)xoptions
{
    self = [super initWithName:@"UMSCCP_mtpResume" receiver:layer sender:mtp3 requiresSynchronisation:NO];
    if(self)
    {
        affectedPointCode = affPC;
        si = xsi;
        ni = xni;
        options = xoptions;
    }
    return self;
}

- (void)main
{
    /*
    UMSCCP_MTP3Route *r = [layer.routingTable routeForPointCode:affPC];
    [r resume];
     */
}

@end
