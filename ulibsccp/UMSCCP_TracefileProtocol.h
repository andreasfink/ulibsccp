//
//  UMSCCP_TracefileProtocol.h
//  ulibsccp
//
//  Created by Andreas Fink on 26.07.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//


@class UMSCCP_Packet;

@protocol UMSCCP_TracefileProtocol


- (void)traceSentPdu:(NSData *)mtp3pdu          options:(NSDictionary *)dict;
- (void)traceReceivedPdu:(NSData *)mtp3pdu      options:(NSDictionary *)dict;
- (void)traceDroppedPdu:(NSData *)mtp3pdu       options:(NSDictionary *)dict;
- (void)traceUnroutablePdu:(NSData *)mtp3pdu    options:(NSDictionary *)dict;
- (void)traceProblematicPdu:(NSData *)mtp3pdu   options:(NSDictionary *)dict;
- (void)open;
- (void)close;
- (void)rotate;

@end

