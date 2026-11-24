//
//  UMSCCPPacketTracerProtocol.h
//  ulibsccp
//
//  Created by Andreas Fink on 24.11.2026.
//


#import <ulib/ulib.h>

@class UMSCCP_Packet;

@protocol UMSCCPPacketTracerProtocol<NSObject>
- (void)tracePacket:(UMSCCP_Packet *)p;
@end
