//
//  UMRpcMessage_InsertSCCPRequest.m
//  ulibsccp
//
//  Created by Andreas Fink on 27.11.2026.
//

#import "UMRpcMessage_InsertSCCPRequest.h"
#import <ulibsccp/UMSCCP_TracePacket.h>
#import <ulib/UMRpcMacros.h>
#import <ulibsccp/UMSCCP_RpcMessageTypes.h>

@implementation UMRpcMessage_InsertSCCPRequest

- (UMRpcMessage_InsertSCCPRequest *)init
{
    self = [super init];
    if(self)
    {
        _command = @(UMRpcMessageType_INSERT_SCCP_REQUEST);
        _flags = @(0);
    }
    return self;
}

- (NSString *) objectName
{
    return @"UMRpcMessage_InsertSCCPRequest";
}

- (id)objectValue
{
    UMSynchronizedSortedDictionary *dict = [super objectValue];
    UMSynchronizedSortedDictionary *pdict = [[UMSynchronizedSortedDictionary alloc]init];
    DAPPEND_STRING(@"packet",_packet,pdict)
    dict[@"payload"] = pdict;
    return dict;
}

- (void) processBeforeEncode
{
    NSMutableArray *a = [[NSMutableArray alloc]init];
    APPEND_OBJECT(UMRpcMessage_InsertSCCPRequestTAG_PACKET,_packet,a)
    _payload = [[UMASN1Sequence alloc]initWithValues:a];
    [super processBeforeEncode];
}

- (UMRpcMessage_InsertSCCPRequest *) processAfterDecodeWithContext:(id)context
{
    [super processAfterDecodeWithContext:context];
    
    int pos = 0;
    UMASN1Object *payload = [[UMASN1Sequence alloc]initWithASN1Object:_payload context:context];
    UMASN1Object *o = [payload getObjectAtPosition:pos++];
    while(o)
    {
        CHECK_OBJECT(UMRpcMessage_InsertSCCPRequestTAG_PACKET,_packet, o,UMSCCP_TracePacket)
        o = [payload getObjectAtPosition:pos++];
    }
    return self;
}


@end

