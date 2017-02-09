//
//  UMSCCP_SegmentationHeader.m
//  ulibsccp
//
//  Created by Andreas Fink on 30.04.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMSCCP_Segment.h"

@implementation UMSCCP_Segment


@synthesize first;
@synthesize class1;
@synthesize remainingSegment;
@synthesize reference;
@synthesize data;

- (NSData *)segmentationHeader
{
    uint8_t bytes[4];
    
    bytes[0] = 0;
    if(first)
    {
        bytes[0] |= 0x80;
    }
    if(class1)
    {
        bytes[0] |= 0x40;
    }
    bytes[0] |= (remainingSegment & 0xF);
    bytes[1] = (reference >> 16) & 0xFF;
    bytes[2] = (reference >> 8)  & 0xFF;
    bytes[3] = (reference >> 0)  & 0xFF;
    return [NSData dataWithBytes:bytes length:4];
}

- (UMSCCP_Segment *)initWithData:(NSData *)d
{
    if(d.length !=4)
    {
        return NULL;
    }
    self = [super init];
    if(self)
    {
        const uint8_t *bytes = d.bytes;
        reference = bytes[3] | (bytes[2]<<8) | (bytes[1] << 16);
        remainingSegment = bytes[0] & 0x0F;
        first = (bytes[0] & 0x80) ? YES : NO;
        class1 = (bytes[0] & 0x40) ? YES : NO;
    }
    return self;
}
@end
