//
//  UMSCCP_TraceWriterPcap.h
//  ulibsccp
//
//  Created by Andreas Fink on 30.07.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibsccp/UMSCCP_TracefileProtocol.h>
#import <ulibpcap/ulibpcap.h>

@interface UMSCCP_TraceWriterPcap : UMObject<UMSCCP_TracefileProtocol>
{
    NSString *_filename;
    UMPCAPFile *_pcapFile;
}

@property(readwrite,strong,atomic)  NSString *filename;

- (void)logPacket:(UMSCCP_Packet *)packet;
- (void)open;
- (void)close;

@end

