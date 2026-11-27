//
//  UMRpcMessage_InsertSCCPResponse.h
//  ulibsccp
//
//  Created by Andreas Fink on 27.11.2026.
//

#import <ulib/ulib.h>

typedef enum UMRpcMessage_InsertSCCPResponseTAG
{
    UMRpcMessage_InsertSCCPResponseTAG_REASON = 1,
} UMRpcMessage_InsertSCCPResponseTAG;

@interface UMRpcMessage_InsertSCCPResponse : UMRpcMessage
{
    NSString *_reason;
}

@property(readwrite,strong,atomic)  NSString *reason;

@end

