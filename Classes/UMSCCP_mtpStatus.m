//
//  UMSCCP_mtpStatus.m
//  ulibsccp
//
//  Created by Andreas Fink on 05.04.16.
//  Copyright (c) 2016 Andreas Fink
//

#import "UMSCCP_mtpStatus.h"
#import "UMLayerSCCP.h"

@implementation UMSCCP_mtpStatus

- (UMSCCP_mtpStatus *)initForSccp:(UMLayerSCCP *)layer
                             mtp3:(UMLayerMTP3 *)mtp3
                affectedPointCode:(UMMTP3PointCode *)affPC
                           status:(int)s
                               si:(int)xsi
                               ni:(int)xni
                          options:(NSDictionary *)xoptions

{
    self = [super initWithName:@"UMSCCP_mtpStatus" receiver:layer sender:mtp3 requiresSynchronisation:YES];
    if(self)
    {
        affectedPointCode = affPC;
        status = s;
        si = xsi;
        ni = xni;
        options = xoptions;
    }
    return self;
}

@end
