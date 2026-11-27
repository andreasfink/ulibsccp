//
//  UMRpcMessage_InsertSCCPRequest.h
//  ulibsccp
//
//  Created by Andreas Fink on 27.11.2026.
//

#import <ulib/ulib.h>
#import <ulibsccp/UMSCCP_TracePacket.h>

typedef enum UMRpcMessage_InsertSCCPRequestTAG
{
    UMRpcMessage_InsertSCCPRequestTAG_PACKET = 1,
}UMRpcMessage_InsertSCCPRequestTAG;

@interface UMRpcMessage_InsertSCCPRequest : UMRpcMessage
{
    UMSCCP_TracePacket *_packet;
}

@property(readwrite,strong,atomic)     UMSCCP_TracePacket *packet;

@end

