//
//  UMSCCP_Segment.h
//  ulibsccp
//
//  Created by Andreas Fink on 30.04.16.
//  Copyright © 2016 Andreas Fink. All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>

@interface UMSCCP_Segment : UMObject
{
    BOOL first;
    BOOL class1;
    int remainingSegment;
    long reference;
    
    NSData *data;
}

@property(readwrite,assign)    BOOL first;
@property(readwrite,assign)    BOOL class1;
@property(readwrite,assign)    int remainingSegment;
@property(readwrite,assign)    long reference;
@property(readwrite,strong)    NSData *data;

- (NSData *)segmentationHeader;
- (UMSCCP_Segment *)initWithData:(NSData *)d;

@end
