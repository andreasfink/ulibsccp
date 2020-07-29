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


- (NSData *)segmentationHeader
{
    uint8_t bytes[4];
    
    bytes[0] = 0;
    if(_first)
    {
        bytes[0] |= 0x80;
    }
    if(_class1)
    {
        bytes[0] |= 0x40;
    }
    bytes[0] |= (_remainingSegment & 0xF);
    bytes[1] = (_reference >> 16) & 0xFF;
    bytes[2] = (_reference >> 8)  & 0xFF;
    bytes[3] = (_reference >> 0)  & 0xFF;
    return [NSData dataWithBytes:bytes length:4];
}


- (UMSCCP_Segment *)initWithHeaderData:(NSData *)d
{
    if(d.length !=4)
    {
        return NULL;
    }
    self = [super init];
    if(self)
    {
        const uint8_t *bytes = d.bytes;
        _reference = bytes[3] | (bytes[2]<<8) | (bytes[1] << 16);
        _remainingSegment = bytes[0] & 0x0F;
        _first = (bytes[0] & 0x80) ? YES : NO;
        _class1 = (bytes[0] & 0x40) ? YES : NO;
    }
    return self;
}

- (NSString *)description
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"{ index:%d reference:%ld remainingSegment:%d first:%@ class1:%@ data:%@ }",
     _segmentIndex,_reference,_remainingSegment,(_first ? @"YES" :@"NO" ),(_class1 ? @"YES" :@"NO" ),
     _data.hexString];
    return s;
}

@end
