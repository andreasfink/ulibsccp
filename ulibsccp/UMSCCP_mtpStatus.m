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

@implementation UMSCCP_mtpStatus

- (UMSCCP_mtpStatus *)initForSccp:(UMLayerSCCP *)layer
                             mtp3:(UMLayerMTP3 *)mtp3
                affectedPointCode:(UMMTP3PointCode *)affPC
                           status:(int)s
                               si:(int)xsi
                               ni:(int)xni
                              sls:(int)xsls
                          options:(NSDictionary *)xoptions

{
    self = [super initWithName:@"UMSCCP_mtpStatus" receiver:layer sender:mtp3 requiresSynchronisation:NO];
    if(self)
    {
        _affectedPointCode = affPC;
        _status = s;
        _si = xsi;
        _ni = xni;
        _sls = xsls;
        _options = xoptions;
        _sccp = layer;
        _mtp3 = mtp3;
    }
    return self;
}

- (void)main
{
    @autoreleasepool
    {
        if(_sccp.logLevel <= UMLOG_DEBUG)
        {
            NSString *s =  [NSString stringWithFormat:@"mtpStatus AffectedPointCode: %@",_affectedPointCode];
            [_sccp logDebug:s];
        }
        NSLog(@"mtpStatus: AffectedPointCode: %@ is now restricted",_affectedPointCode);
        [_mtp3.routingUpdateDb logInboundLinkset:@"sccp"
                                 outboundLinkset:@""
                                             dpc:_affectedPointCode
                                          status:@"restricted"
                                          reason:@"mtpStatus"];
        [_sccp.sccpL3RoutingTable setStatus:SccpL3RouteStatus_restricted
                             forPointCode:_affectedPointCode];
    }
}

@end
