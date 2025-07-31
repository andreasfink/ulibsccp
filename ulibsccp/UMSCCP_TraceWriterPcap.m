//
//  UMSCCP_TraceWriterPcap.m
//  ulibsccp
//
//  Created by Andreas Fink on 30.07.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_TraceWriterPcap.h"
#import "UMSCCP_Packet.h"


@implementation UMSCCP_TraceWriterPcap

- (void)open
{
    _pcapFile           = [[UMPCAPFile alloc]init];
    _pcapFile.filename  = _filename;
    _pcapFile.mode      = UMPCAP_Mode_SCCP;
}

- (void)close
{
    [_pcapFile close];
}

- (void)logPacket:(UMSCCP_Packet *)packet
{
    NSDate *date = [NSDate date];
    double t1 = date.timeIntervalSince1970;
    struct timeval t;
    t.tv_sec = (int)t1;
    t.tv_usec = (t1 - t.tv_sec) *1000000;
    [_pcapFile writePdu:packet.incomingMtp3Data];
}
@end
