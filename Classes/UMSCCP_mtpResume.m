//
//  UMSCCP_mtpResume.m
//  ulibsccp
//
//  Created by Andreas Fink on 05.04.16.
//  Copyright (c) 2016 Andreas Fink
//

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
    self = [super initWithName:@"UMSCCP_mtpResume" receiver:layer sender:mtp3 requiresSynchronisation:YES];
    if(self)
    {
        affectedPointCode = affPC;
        si = xsi;
        ni = xni;
        options = xoptions;
    }
    return self;
}

@end
