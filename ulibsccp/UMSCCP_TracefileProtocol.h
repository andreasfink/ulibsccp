//
//  UMSCCP_TracefileProtocol.h
//  ulibsccp
//
//  Created by Andreas Fink on 26.07.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//


@class UMSCCP_Packet;

@protocol UMSCCP_TracefileProtocol

- (void)logPacket:(UMSCCP_Packet *)packet;
- (void)open;
- (void)close;
- (void)rotate;

@end

