//
//  UMSCCP_ReceivedSegment.h
//  ulibsccp
//
//  Created by Andreas Fink on 16.02.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibmtp3/ulibmtp3.h>
#import <ulibgt/ulibgt.h>
#import <ulibsccp/UMSCCP_Segment.h>
#import <ulibsccp/UMSCCP_Defs.h>
@class UMSCCP_Packet;

@interface UMSCCP_ReceivedSegment : UMObject
{
    SccpAddress         *_src;
    SccpAddress         *_dst;
    UMMTP3PointCode     *_opc;
    UMMTP3PointCode     *_dpc;
    UMSCCP_Segment      *_segment;
    int                 _reference;
    int                 _sls;
    int                 _max;
    SCCP_ServiceClass   _pclass;
    SCCP_Handling       _handling;
    int                 _hopCount;
    NSData              *_optionsData;
    NSDictionary        *_options;
    UMLayerMTP3         *_provider;
    UMSCCP_Packet       *_combinedPacket;
}

@property(readwrite,strong,atomic)  SccpAddress         *src;
@property(readwrite,strong,atomic)  SccpAddress         *dst;
@property(readwrite,strong,atomic)  UMMTP3PointCode     *opc;
@property(readwrite,strong,atomic)  UMMTP3PointCode     *dpc;
@property(readwrite,strong,atomic)  UMSCCP_Segment      *segment;
@property(readwrite,assign,atomic)  int                 reference;
@property(readwrite,assign,atomic)  int                 sls;
@property(readwrite,assign,atomic)  int                 max;
@property(readwrite,assign,atomic)  SCCP_ServiceClass   pclass;
@property(readwrite,assign,atomic)  SCCP_Handling       handling;
@property(readwrite,assign,atomic)  int                 hopCount;
@property(readwrite,strong,atomic)  NSData              *optionsData;
@property(readwrite,strong,atomic)  NSDictionary        *options;
@property(readwrite,strong,atomic)  UMLayerMTP3         *provider;
@property(readwrite,strong,atomic)  UMSCCP_Packet       *combinedPacket;

- (NSString *)key;

@end

