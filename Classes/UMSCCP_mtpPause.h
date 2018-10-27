//
//  UMSCCP_mtpPause.h
//  ulibsccp
//
//  Created by Andreas Fink on 05.04.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibmtp3/ulibmtp3.h>

@class UMLayerSCCP;

@interface UMSCCP_mtpPause : UMLayerTask
{
    UMMTP3PointCode *_affectedPointCode;
    int _si;
    int _ni;
    NSDictionary *_options;
    UMLayerSCCP *_sccp;
}

- (UMSCCP_mtpPause *)initForSccp:(UMLayerSCCP *)layer
                            mtp3:(UMLayerMTP3 *)mtp3
               affectedPointCode:(UMMTP3PointCode *)affPC
                              si:(int)si
                              ni:(int)ni
                         options:(NSDictionary *)options;

@end
