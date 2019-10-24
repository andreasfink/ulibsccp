//
//  UMSCCP_Packet.m
//  ulibsccp
//
//  Created by Andreas Fink on 11.01.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_Packet.h"
#import "UMLayerSCCP.h"

#if !defined(UMTCAP_Command)
typedef enum UMTCAP_Command
{
    TCAP_TAG_UNDEFINED                      = -1,
    /* ANSI commands are 1000 + tag number to avoid enum duplicates */
    TCAP_TAG_ANSI_UNIDIRECTIONAL            = 1001,
    TCAP_TAG_ANSI_QUERY_WITH_PERM           = 1002,
    TCAP_TAG_ANSI_QUERY_WITHOUT_PERM        = 1003,
    TCAP_TAG_ANSI_RESPONSE                  = 1004,
    TCAP_TAG_ANSI_CONVERSATION_WITH_PERM    = 1005,
    TCAP_TAG_ANSI_CONVERSATION_WITHOUT_PERM = 1006,
    TCAP_TAG_ANSI_ABORT                     = 1022,

    /* ITU commands are equal to asn1.tag number */
    TCAP_TAG_ITU_UNIDIRECTIONAL             = 1,
    TCAP_TAG_ITU_BEGIN                      = 2,
    TCAP_TAG_ITU_END                        = 4,
    TCAP_TAG_ITU_CONTINUE                   = 5,
    TCAP_TAG_ITU_ABORT                      = 7,
} UMTCAP_Command;
#endif

@implementation UMSCCP_Packet

- (UMSCCP_Packet *)init
{
	self = [super init];
	if(self)
	{
		_created = [NSDate date];
        _tags = [[UMSynchronizedDictionary alloc]init];
	}
	return self;
}


- (NSString *)incomingPacketType
{
    switch(_incomingServiceType)
    {
        case SCCP_UDT:
            return @"udt";
        case SCCP_UDTS:
            return @"udts";
        case SCCP_XUDT:
            return @"xudt";
        case SCCP_XUDTS:
            return @"xudts";
        case SCCP_LUDT:
            return @"ludt";
        case SCCP_LUDTS:
            return @"ludts";
        default:
            return [NSString stringWithFormat:@"%d",_incomingServiceType];
    }
}

- (NSString *)outgoingPacketType
{
    switch(_outgoingServiceType)
    {
        case SCCP_UDT:
            return @"udt";
        case SCCP_UDTS:
            return @"udts";
        case SCCP_XUDT:
            return @"xudt";
        case SCCP_XUDTS:
            return @"xudts";
        case SCCP_LUDT:
            return @"ludt";
        case SCCP_LUDTS:
            return @"ludts";
        default:
            return [NSString stringWithFormat:@"%d",_outgoingServiceType];
    }
}

- (void)copyIncomingToOutgoing
{
    _outgoingLocalUser              = _incomingLocalUser;
    _outgoingMtp3Layer              = _incomingMtp3Layer;
    _outgoingLinkset                = _incomingLinkset;
    _outgoingOptions                = _incomingOptions;
    _outgoingOpc                    = _incomingOpc;
    _outgoingDpc                    = _incomingDpc;
    _outgoingServiceClass           = _incomingServiceClass;
    _outgoingServiceType            = _incomingServiceType;
    _outgoingReturnCause            = _incomingReturnCause;
    _outgoingHandling               = _incomingHandling;
    _outgoingMaxHopCount            = _incomingMaxHopCount - 1;
    _outgoingFromLocal              = _incomingFromLocal;
    _outgoingToLocal                = _incomingToLocal;
    _outgoingCallingPartyAddress    = _incomingCallingPartyAddress;
    _outgoingCalledPartyAddress     = _incomingCalledPartyAddress;
    _outgoingMtp3Data               = _incomingMtp3Data;
    _outgoingSccpData               = _incomingSccpData;
    _outgoingOptionalData           = _incomingOptionalData;
    _outgoingReturnCause            = _incomingReturnCause;
}


- (void)addTag:(NSString *)tag
{
    _tags[tag]=tag;
}

- (void)clearTag:(NSString *)tag
{
    [_tags removeObjectForKey:tag];
}

- (BOOL) hasTag:(NSString *)tag
{
    if(_tags[tag])
    {
        return YES;
    }
    return NO;
}

- (void)clearAllTags
{
    _tags = [[UMSynchronizedDictionary alloc] init];
}


- (NSString *)description
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendString:[super description]];
    [s appendString:@"\n{\n\t"];
    [s appendFormat:@"\t_sccp: %@\n", _sccp ? _sccp.layerName : @"NULL"];
    [s appendFormat:@"\t_created: %@\n", _created ? _created : @"NULL"];
    [s appendFormat:@"\t_afterFilter1: %@\n", _afterFilter1 ? _afterFilter1 : @"NULL"];
    [s appendFormat:@"\t_reassembled: %@\n", _reassembled ? _reassembled : @"NULL"];
    [s appendFormat:@"\t_afterFilter2: %@\n", _afterFilter2 ? _afterFilter2 : @"NULL"];
    [s appendFormat:@"\t_routed: %@\n", _routed ? _routed : @"NULL"];
    [s appendFormat:@"\t_afterFilter3: %@\n", _afterFilter3 ? _afterFilter3 : @"NULL"];
    [s appendFormat:@"\t_segmented: %@\n", _segmented ? _segmented : @"NULL"];
    [s appendFormat:@"\t_afterFilter4: %@\n", _afterFilter4 ? _afterFilter4 : @"NULL"];
    [s appendFormat:@"\t_queuedForDelivery: %@\n", _queuedForDelivery ? _queuedForDelivery : @"NULL"];
    switch(_state)
    {
        case       SCCP_STATE_IDLE:
            [s appendFormat:@"\t_state: SCCP_STATE_IDLE\n"];
            break;
        case       SCCP_STATE_DATA_TRANSFER:
            [s appendFormat:@"\t_state: SCCP_STATE_DATA_TRANSFER\n"];
            break;
        case       SCCP_STATE_INCOMING_CONNECTION_PENDING:
            [s appendFormat:@"\t_state: SCCP_STATE_INCOMING_CONNECTION_PENDING\n"];
            break;
        case       SCCP_STATE_PROVIDER_INITIATED_RESET_PENDING:
            [s appendFormat:@"\t_state: SCCP_STATE_PROVIDER_INITIATED_RESET_PENDING\n"];
            break;
        case       SCCP_STATE_OUTGOING_CONNECTION_PENDING:
            [s appendFormat:@"\t_state: SCCP_STATE_OUTGOING_CONNECTION_PENDING\n"];
            break;
        case       SCCP_STATE_USER_REQUEST_RESET_PENDING:
            [s appendFormat:@"\t_state: SCCP_STATE_USER_REQUEST_RESET_PENDING\n"];
            break;
        default:
            [s appendFormat:@"\t_state: unknown(%d)\n",(int)_state];
            break;
    }
    [s appendFormat:@"\t_incomingLocalUser: %@\n", _incomingLocalUser ? _incomingLocalUser.layerName : @"NULL"];
    [s appendFormat:@"\t_incomingMtp3Layer: %@\n", _incomingMtp3Layer ? _incomingMtp3Layer.layerName : @"NULL"];
    [s appendFormat:@"\t_incomingOptions: %@\n", _incomingOptions ? _incomingOptions : @"NULL"];
    [s appendFormat:@"\t_incomingOpc: %@\n", _incomingOpc ? _incomingOpc : @"NULL"];
    [s appendFormat:@"\t_incomingOptions: %@\n", _incomingDpc ? _incomingDpc : @"NULL"];
    switch(_incomingServiceClass)
    {
        case SCCP_CLASS_UNDEFINED:
            [s appendFormat:@"\t_incomingServiceClass: SCCP_CLASS_UNDEFINED\n"];
            break;
        case SCCP_CLASS_BASIC:
            [s appendFormat:@"\t_incomingServiceClass: SCCP_CLASS_BASIC\n"];
            break;
        case SCCP_CLASS_INSEQ_CL:
            [s appendFormat:@"\t_incomingServiceClass: SCCP_CLASS_INSEQ_CL\n"];
            break;
        case SCCP_CLASS_BASIC_CO:
            [s appendFormat:@"\t_incomingServiceClass: SCCP_CLASS_BASIC_CO\n"];
            break;
        case SCCP_CLASS_FLOW_CONTROL_CO:
            [s appendFormat:@"\t_incomingServiceClass: SCCP_CLASS_FLOW_CONTROL_CO\n"];
            break;
        default:
            [s appendFormat:@"\t_incomingServiceClass: undefined(%d)\n",_incomingServiceClass];
            break;
    }
    switch(_incomingServiceType)
    {
        case SCCP_UDT:
            [s appendFormat:@"\t_incomingServiceType: SCCP_UDT\n"];
            break;
        case SCCP_UDTS:
            [s appendFormat:@"\t_incomingServiceType: SCCP_UDTS\n"];
            break;
        case SCCP_XUDT:
            [s appendFormat:@"\t_incomingServiceType: SCCP_XUDT\n"];
            break;
        case SCCP_XUDTS:
            [s appendFormat:@"\t_incomingServiceType: SCCP_XUDTS\n"];
            break;
        case SCCP_LUDT:
            [s appendFormat:@"\t_incomingServiceType: SCCP_LUDT\n"];
            break;
        case SCCP_LUDTS:
            [s appendFormat:@"\t_incomingServiceType: SCCP_LUDTS\n"];
            break;
        default:
            [s appendFormat:@"\t_incomingServiceType: unknown(%d)\n",_incomingServiceType];
            break;
    }
    [s appendFormat:@"\t_incomingHandling: %d\n",_incomingHandling];
    [s appendFormat:@"\t_incomingMaxHopCount: %d\n",_incomingMaxHopCount];
    [s appendFormat:@"\t_incomingFromLocal: %@\n",_incomingFromLocal ? @"YES" : @"NO"];
    [s appendFormat:@"\t_incomingToLocal: %@\n",_incomingToLocal ? @"YES" : @"NO"];
    [s appendFormat:@"\t_incomingCallingPartyAddress: %@\n",_incomingCallingPartyAddress.description];
    [s appendFormat:@"\t_incomingCalledPartyAddress: %@\n",_incomingCalledPartyAddress.description];
    [s appendFormat:@"\t_incomingMtp3Data: %@\n",_incomingMtp3Data.hexString];
    [s appendFormat:@"\t_incomingSccpData: %@\n",_incomingSccpData.hexString];
    [s appendFormat:@"\t_incomingOptionalData: %@\n",_incomingOptionalData.hexString];

    switch(_incomingReturnCause)
    {
        case SCCP_ReturnCause_not_set:
            break;
        case SCCP_ReturnCause_NoTranslationForAnAddressOfSuchNature:
            [s appendFormat:@"\t_incomingReturnCause: NoTranslationForAnAddressOfSuchNature\n"];
            break;
        case    SCCP_ReturnCause_NoTranslationForThisSpecificAddress :
            [s appendFormat:@"\t_incomingReturnCause: NoTranslationForThisSpecificAddress\n"];
            break;
        case    SCCP_ReturnCause_SubsystemCongestion:
            [s appendFormat:@"\t_incomingReturnCause: SubsystemCongestion\n"];
            break;
        case    SCCP_ReturnCause_SubsystemFailure:
            [s appendFormat:@"\t_incomingReturnCause: SubsystemFailure\n"];
            break;
        case    SCCP_ReturnCause_Unequipped:
            [s appendFormat:@"\t_incomingReturnCause: Unequipped\n"];
            break;
        case   SCCP_ReturnCause_MTPFailure:
            [s appendFormat:@"\t_incomingReturnCause: MTPFailure\n"];
            break;
        case   SCCP_ReturnCause_NetworkCongestion:
            [s appendFormat:@"\t_incomingReturnCause: NetworkCongestion\n"];
            break;
        case   SCCP_ReturnCause_Unqualified:
            [s appendFormat:@"\t_incomingReturnCause: Unqualified\n"];
            break;
        case    SCCP_ReturnCause_ErrorInMessageTransport:
            [s appendFormat:@"\t_incomingReturnCause: ErrorInMessageTransport\n"];
            break;
        case   SCCP_ReturnCause_ErrorInLocalProcessing:
            [s appendFormat:@"\t_incomingReturnCause: ErrorInLocalProcessing\n"];
            break;
        case    SCCP_ReturnCause_DestinationCannotPerformReassembly:
            [s appendFormat:@"\t_incomingReturnCause: DestinationCannotPerformReassembly\n"];
            break;
        case    SCCP_ReturnCause_SCCPFailure:
            [s appendFormat:@"\t_incomingReturnCause: SCCPFailure\n"];
            break;
        case    SCCP_ReturnCause_HopCounterViolation:
            [s appendFormat:@"\t_incomingReturnCause: HopCounterViolation\n"];
            break;
        case   SCCP_ReturnCause_SegmentationNotSupported:
            [s appendFormat:@"\t_incomingReturnCause: SegmentationNotSupported\n"];
            break;
        case    SCCP_ReturnCause_SegmentationFailure:
            [s appendFormat:@"\t_incomingReturnCause: SegmentationFailure\n"];
            break;
        default:
            [s appendFormat:@"\t_incomingReturnCause: %d\n",_incomingReturnCause];
            break;
    }
    switch(_incomingTcapCommand)
    {
        case 1:
            [s appendFormat:@"\t_incomingTcapCommand: UNIDIRECTIONAL\n"];
            break;
        case 2:
            [s appendFormat:@"\t_incomingTcapCommand: BEGIN\n"];
            break;
        case 4:
            [s appendFormat:@"\t_incomingTcapCommand: END\n"];
            break;
        case 5:
            [s appendFormat:@"\t_incomingTcapCommand: CONTINUE\n"];
            break;
        case 7:
            [s appendFormat:@"\t_incomingTcapCommand: ABORT\n"];
            break;

        case 1001:
            [s appendFormat:@"\t_incomingTcapCommand: ANSI-UNIDIRECTIONAL\n"];
            break;
        case 1002:
            [s appendFormat:@"\t_incomingTcapCommand: ANSI-QUERY-WITH-PERM\n"];
            break;
        case 1003:
            [s appendFormat:@"\t_incomingTcapCommand: ANSI-QUERY-WITHOUT-PERM \n"];
            break;
        case 1004:
            [s appendFormat:@"\t_incomingTcapCommand: ANSI-RESPONSE\n"];
            break;
        case 1005:
            [s appendFormat:@"\t_incomingTcapCommand: ANSI-CONVERSATION-WITH-PERM\n"];
            break;
        case 1006:
            [s appendFormat:@"\t_incomingTcapCommand: ANSI-CONVERSATION-WITHOUT-PERM\n"];
            break;
        case 1022:
            [s appendFormat:@"\t_incomingTcapCommand: ANSI-ABORT\n"];
            break;
        default:
            [s appendFormat:@"\t_incomingTcapCommand: %d\n",_incomingTcapCommand];
            break;
    }
    if(_incomingTcapAsn1)
    {
        UMSynchronizedSortedDictionary *o = _incomingTcapAsn1.objectValue;
        NSString *s1 = [o jsonString];
        [s appendFormat:@"\t_incomingTcapAsn1: %@\n",s1];
    }
    else
    {
        [s appendFormat:@"\t_incomingTcapAsn1: NULL\n"];
    }

    if(_incomingTcapBegin)
    {
        UMSynchronizedSortedDictionary *o = [(UMASN1Object *)_incomingTcapBegin objectValue];
        NSString *s1 = [o jsonString];
        [s appendFormat:@"\t_incomingTcapBegin: %@\n",s1];
    }
    else
    {
        [s appendFormat:@"\t_incomingTcapBegin: NULL\n"];
    }

    if(_incomingTcapContinue)
    {
        UMSynchronizedSortedDictionary *o = [(UMASN1Object *)_incomingTcapContinue objectValue];
        NSString *s1 = [o jsonString];
        [s appendFormat:@"\t_incomingTcapContinue: %@\n",s1];
    }
    else
    {
        [s appendFormat:@"\t_incomingTcapContinue: NULL\n"];
    }

    if(_incomingTcapEnd)
    {
        UMSynchronizedSortedDictionary *o = [(UMASN1Object *)_incomingTcapEnd objectValue];
        NSString *s1 = [o jsonString];
        [s appendFormat:@"\t_incomingTcapEnd: %@\n",s1];
    }
    else
    {
        [s appendFormat:@"\t_incomingTcapEnd: NULL\n"];
    }

    if(_incomingTcapAbort)
    {
        UMSynchronizedSortedDictionary *o = [(UMASN1Object *)_incomingTcapAbort objectValue];
        NSString *s1 = [o jsonString];
        [s appendFormat:@"\t_incomingTcapAbort: %@\n",s1];
    }
    else
    {
        [s appendFormat:@"\t_incomingTcapAbort: NULL\n"];
    }

    [s appendFormat:@"\t_incomingApplicationContext: %@\n",_incomingApplicationContext ? _incomingApplicationContext : @"NULL"];

    if(_incomingGsmMapAsn1)
    {
        UMSynchronizedSortedDictionary *o = [(UMASN1Object *)_incomingGsmMapAsn1 objectValue];
        NSString *s1 = [o jsonString];
        [s appendFormat:@"\t_incomingGsmMapAsn1: %@\n",s1];
    }
    else
    {
        [s appendFormat:@"\t_incomingGsmMapAsn1: NULL\n"];
    }
    [s appendFormat:@"\t_incomingGsmMapOperation: %d\n",_incomingGsmMapOperation];
    [s appendFormat:@"\t_incomingCategory: %d\n",_incomingCategory];

    [s appendFormat:@"\t_incomingLocalTransactionId: %@\n",_incomingLocalTransactionId ? _incomingLocalTransactionId : @"NULL"];
    [s appendFormat:@"\t_incomingRemoteTransactionId: %@\n",_incomingRemoteTransactionId ? _incomingRemoteTransactionId : @"NULL"];
    [s appendFormat:@"\t_canNotDecode: %@\n",_canNotDecode ? @"YES" : @"NO"];
    [s appendFormat:@"\t_tags:\n"];
    NSArray *a = [_tags allKeys];
    for(NSString *tag in a)
    {
        [s appendFormat:@"\t\t%@\n",tag];
    }
    a = [_vars allKeys];
    for(NSString *var in a)
    {
        [s appendFormat:@"\t\t%@=%@\n",var,_vars[var]];
    }
    [s appendFormat:@"\t_rerouteDestinationGroup: %@\n", _rerouteDestinationGroup ? _rerouteDestinationGroup.name : @"NULL"];
    return s;
}

- (NSDictionary *)dictionaryValue
{
#define DICT_SET_STRING(dict,name,str)  \
    { \
        NSString *s = str; \
        if(s) \
        { \
            dict[name] = s; \
        } \
        else \
        { \
            dict[name] = @""; \
        } \
    }

#define DICT_SET_INTEGER(dict,name,i)    dict[name] = [NSString stringWithFormat:@"%d",i];
#define DICT_SET_BOOL(dict,name,b)    dict[name] =  b ? @"1" : @"0";

    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];

    DICT_SET_STRING(dict,@"created",[_created stringValue]);
    DICT_SET_STRING(dict,@"afterFilter1",[_afterFilter1 stringValue]);
    DICT_SET_STRING(dict,@"reassembled",[_reassembled stringValue]);
    DICT_SET_STRING(dict,@"afterFilter2",[_afterFilter2 stringValue]);
    DICT_SET_STRING(dict,@"routed",[_routed stringValue]);
    DICT_SET_STRING(dict,@"afterFilter3",[_afterFilter3 stringValue]);
    DICT_SET_STRING(dict,@"segmented",[_segmented stringValue]);
    DICT_SET_STRING(dict,@"queuedForDelivery",[_queuedForDelivery stringValue]);
    switch(_state)
    {
        case SCCP_STATE_IDLE:
            dict[@"state"] = @"IDLE";
            break;

        case SCCP_STATE_DATA_TRANSFER:
            dict[@"state"] = @"DATA_TRANSFER";
            break;

        case SCCP_STATE_INCOMING_CONNECTION_PENDING:
            dict[@"state"] = @"INCOMING_CONNECTION_PENDING";
            break;

        case SCCP_STATE_PROVIDER_INITIATED_RESET_PENDING:
            dict[@"state"] = @"PROVIDER_INITIATED_RESET_PENDING";
            break;

        case SCCP_STATE_OUTGOING_CONNECTION_PENDING:
            dict[@"state"] = @"OUTGOING_CONNECTION_PENDING";
            break;

        case SCCP_STATE_USER_REQUEST_RESET_PENDING:
            dict[@"state"] = @"USER_REQUEST_RESET_PENDING";
            break;
        default:
            dict[@"state"] = @"USER_REQUEST_RESET_PENDING";

    }
    DICT_SET_STRING(dict,@"incomingLocalUser",[_incomingLocalUser layerName]);
    DICT_SET_STRING(dict,@"incomingMtp3Layer",[_incomingMtp3Layer layerName]);
    DICT_SET_STRING(dict,@"incomingLinkset",_incomingLinkset);
    DICT_SET_STRING(dict,@"incomingOptions",_incomingOptions.jsonCompactString);
    DICT_SET_INTEGER(dict,@"incomingOpc",_incomingOpc.integerValue);
    DICT_SET_STRING(dict,@"incomingOpcString",_incomingOpc.stringValue);
    DICT_SET_INTEGER(dict,@"incomingDpc",_incomingDpc.integerValue);
    DICT_SET_STRING(dict,@"incomingDpcString",_incomingDpc.stringValue);

    switch(_incomingServiceClass)
    {
        case SCCP_CLASS_UNDEFINED:
            dict[@"incomingServiceClass"] = @"UNDEFINED";
            break;
        case SCCP_CLASS_BASIC:
            dict[@"incomingServiceClass"] = @"BASIC";
            break;
        case SCCP_CLASS_INSEQ_CL:
            dict[@"incomingServiceClass"] = @"INSEQ_CL";
            break;
        case SCCP_CLASS_BASIC_CO:
            dict[@"incomingServiceClass"] = @"BASIC_CO";
            break;
        case SCCP_CLASS_FLOW_CONTROL_CO:
            dict[@"incomingServiceClass"] = @"FLOW_CONTROL_CO";
            break;
        default:
            dict[@"incomingServiceClass"] = @"";
    }
    switch(_incomingServiceType)
    {
        case    SCCP_UDT:
            dict[@"incomingServiceType"] = @"UDT";
            break;
        case    SCCP_UDTS:
            dict[@"incomingServiceType"] = @"UDTS";
            break;
        case    SCCP_XUDT:
            dict[@"incomingServiceType"] = @"XUDT";
            break;
        case    SCCP_XUDTS:
            dict[@"incomingServiceType"] = @"XUDTS";
            break;
        case    SCCP_LUDT:
            dict[@"incomingServiceType"] = @"LUDT";
            break;
        case    SCCP_LUDTS:
            dict[@"incomingServiceType"] = @"LUDTS";
            break;
        default:
            dict[@"incomingServiceType"] = @"";
            break;
    }
    DICT_SET_INTEGER(dict,@"incomingHandling",_incomingHandling);
    DICT_SET_INTEGER(dict,@"incomingMaxHopCount",_incomingMaxHopCount);
    DICT_SET_INTEGER(dict,@"incomingFromLocal",_incomingFromLocal);
    DICT_SET_INTEGER(dict,@"incomingToLocal",_incomingToLocal);
    DICT_SET_STRING(dict,@"incomingCallingPartyAddress",_incomingCallingPartyAddress.stringValueE164);
    DICT_SET_STRING(dict,@"incomingCallingPartyCountry",_incomingCallingPartyCountry);
    DICT_SET_STRING(dict,@"incomingCalledPartyAddress",_incomingCalledPartyAddress.stringValueE164);
    DICT_SET_STRING(dict,@"incomingCalledPartyCountry",_incomingCalledPartyCountry);
    DICT_SET_STRING(dict,@"incomingMtp3Data",_incomingMtp3Data.hexString);
    DICT_SET_STRING(dict,@"incomingSccpData",_incomingSccpData.hexString);
    DICT_SET_STRING(dict,@"incomingOptionalData",_incomingOptionalData.hexString);
    switch(_incomingReturnCause)
    {
        case SCCP_ReturnCause_NoTranslationForAnAddressOfSuchNature:
            dict[@"incomingReturnCause"] = @"NoTranslationForAnAddressOfSuchNature";
            break;
        case SCCP_ReturnCause_NoTranslationForThisSpecificAddress:
            dict[@"incomingReturnCause"] = @"NoTranslationForThisSpecificAddress";
            break;
        case SCCP_ReturnCause_SubsystemCongestion:
            dict[@"incomingReturnCause"] = @"SubsystemCongestion";
            break;
        case SCCP_ReturnCause_SubsystemFailure:
            dict[@"incomingReturnCause"] = @"SubsystemFailure";
            break;
        case SCCP_ReturnCause_Unequipped:
            dict[@"incomingReturnCause"] = @"Unequipped";
            break;
        case SCCP_ReturnCause_MTPFailure:
            dict[@"incomingReturnCause"] = @"MTPFailure";
            break;
        case SCCP_ReturnCause_NetworkCongestion:
            dict[@"incomingReturnCause"] = @"NetworkCongestion";
            break;
        case SCCP_ReturnCause_Unqualified:
            dict[@"incomingReturnCause"] = @"Unqualified";
            break;
        case SCCP_ReturnCause_ErrorInMessageTransport:
            dict[@"incomingReturnCause"] = @"ErrorInMessageTransport";
            break;
        case SCCP_ReturnCause_ErrorInLocalProcessing:
            dict[@"incomingReturnCause"] = @"ErrorInLocalProcessing";
            break;
        case SCCP_ReturnCause_DestinationCannotPerformReassembly:
            dict[@"incomingReturnCause"] = @"DestinationCannotPerformReassembly";
            break;
        case SCCP_ReturnCause_SCCPFailure:
            dict[@"incomingReturnCause"] = @"SCCPFailure";
            break;
        case SCCP_ReturnCause_HopCounterViolation:
            dict[@"incomingReturnCause"] = @"HopCounterViolation";
            break;
        case SCCP_ReturnCause_SegmentationNotSupported:
            dict[@"incomingReturnCause"] = @"SegmentationNotSupported";
            break;
        case SCCP_ReturnCause_SegmentationFailure:
            dict[@"incomingReturnCause"] = @"SegmentationFailure";
            break;
        case SCCP_ReturnCause_not_set:
        default:
                dict[@"incomingServiceType"] = @"";
                break;
    }
    DICT_SET_STRING(dict,@"outgoingLocalUser",_outgoingLocalUser.layerName);
    DICT_SET_STRING(dict,@"outgoingMtp3Layer",_outgoingMtp3Layer.layerName);
    DICT_SET_STRING(dict,@"outgoingOptions",_outgoingOptions.jsonCompactString);
    DICT_SET_INTEGER(dict,@"outgoingOpc",_outgoingOpc.integerValue);
    DICT_SET_STRING(dict,@"outgoingOpcString",_outgoingOpc.stringValue);
    DICT_SET_INTEGER(dict,@"outgoingDpc",_outgoingDpc.integerValue);
    DICT_SET_STRING(dict,@"outgoingDpcString",_outgoingDpc.stringValue);

    switch(_outgoingServiceClass)
    {
        case SCCP_CLASS_UNDEFINED:
            dict[@"outgoingServiceClass"] = @"UNDEFINED";
            break;
        case SCCP_CLASS_BASIC:
            dict[@"outgoingServiceClass"] = @"BASIC";
            break;
        case SCCP_CLASS_INSEQ_CL:
            dict[@"outgoingServiceClass"] = @"INSEQ_CL";
            break;
        case SCCP_CLASS_BASIC_CO:
            dict[@"outgoingServiceClass"] = @"BASIC_CO";
            break;
        case SCCP_CLASS_FLOW_CONTROL_CO:
            dict[@"outgoingServiceClass"] = @"FLOW_CONTROL_CO";
            break;
        default:
            dict[@"outgoingServiceClass"] = @"";
    }
    switch(_outgoingServiceType)
    {
        case    SCCP_UDT:
            dict[@"outgoingServiceType"] = @"UDT";
            break;
        case    SCCP_UDTS:
            dict[@"outgoingServiceType"] = @"UDTS";
            break;
        case    SCCP_XUDT:
            dict[@"outgoingServiceType"] = @"XUDT";
            break;
        case    SCCP_XUDTS:
            dict[@"outgoingServiceType"] = @"XUDTS";
            break;
        case    SCCP_LUDT:
            dict[@"outgoingServiceType"] = @"LUDT";
            break;
        case    SCCP_LUDTS:
            dict[@"outgoingServiceType"] = @"LUDTS";
            break;
        default:
            dict[@"outgoingServiceType"] = @"";
            break;
    }

    DICT_SET_STRING(dict,@"outgoingCallingPartyAddress",_outgoingCallingPartyAddress.stringValueE164);
    DICT_SET_STRING(dict,@"outgoingCallingPartyCountry",[_outgoingCallingPartyAddress country]);
    DICT_SET_STRING(dict,@"outgoingCalledPartyAddress",_outgoingCalledPartyAddress.stringValueE164);
    DICT_SET_STRING(dict,@"outgoingCalledPartyCountry",[_outgoingCalledPartyAddress country]);
    DICT_SET_STRING(dict,@"outgoingMtp3Data",_outgoingMtp3Data.hexString);
    DICT_SET_STRING(dict,@"outgoingSccpData",_outgoingSccpData.hexString);
    DICT_SET_STRING(dict,@"outgoingOptionalData",_outgoingOptionalData.hexString);
    DICT_SET_INTEGER(dict,@"outgoingMaxHopCount",_outgoingMaxHopCount);
    DICT_SET_BOOL(dict,@"outgoingFromLocal",_outgoingFromLocal);
    DICT_SET_BOOL(dict,@"outgoingToLocal",_outgoingToLocal);
    switch(_outgoingReturnCause)
    {
        case SCCP_ReturnCause_NoTranslationForAnAddressOfSuchNature:
            dict[@"outgoingReturnCause"] = @"NoTranslationForAnAddressOfSuchNature";
            break;
        case SCCP_ReturnCause_NoTranslationForThisSpecificAddress:
            dict[@"outgoingReturnCause"] = @"NoTranslationForThisSpecificAddress";
            break;
        case SCCP_ReturnCause_SubsystemCongestion:
            dict[@"outgoingReturnCause"] = @"SubsystemCongestion";
            break;
        case SCCP_ReturnCause_SubsystemFailure:
            dict[@"outgoingReturnCause"] = @"SubsystemFailure";
            break;
        case SCCP_ReturnCause_Unequipped:
            dict[@"outgoingReturnCause"] = @"Unequipped";
            break;
        case SCCP_ReturnCause_MTPFailure:
            dict[@"outgoingReturnCause"] = @"MTPFailure";
            break;
        case SCCP_ReturnCause_NetworkCongestion:
            dict[@"outgoingReturnCause"] = @"NetworkCongestion";
            break;
        case SCCP_ReturnCause_Unqualified:
            dict[@"outgoingReturnCause"] = @"Unqualified";
            break;
        case SCCP_ReturnCause_ErrorInMessageTransport:
            dict[@"outgoingReturnCause"] = @"ErrorInMessageTransport";
            break;
        case SCCP_ReturnCause_ErrorInLocalProcessing:
            dict[@"outgoingReturnCause"] = @"ErrorInLocalProcessing";
            break;
        case SCCP_ReturnCause_DestinationCannotPerformReassembly:
            dict[@"outgoingReturnCause"] = @"DestinationCannotPerformReassembly";
            break;
        case SCCP_ReturnCause_SCCPFailure:
            dict[@"outgoingReturnCause"] = @"SCCPFailure";
            break;
        case SCCP_ReturnCause_HopCounterViolation:
            dict[@"outgoingReturnCause"] = @"HopCounterViolation";
            break;
        case SCCP_ReturnCause_SegmentationNotSupported:
            dict[@"outgoingReturnCause"] = @"SegmentationNotSupported";
            break;
        case SCCP_ReturnCause_SegmentationFailure:
            dict[@"outgoingReturnCause"] = @"SegmentationFailure";
            break;
        case SCCP_ReturnCause_not_set:
        default:
                dict[@"outgoingReturnCause"] = @"";
                break;

    }
    DICT_SET_STRING(dict,@"incomingTcapAsn1",[((UMASN1Object *)_incomingTcapAsn1) jsonCompactString ]);
    DICT_SET_STRING(dict,@"incomingTcapBegin",[((UMASN1Object *)_incomingTcapBegin) jsonCompactString ]);
    DICT_SET_STRING(dict,@"incomingTcapContinue",[((UMASN1Object *)_incomingTcapContinue) jsonCompactString ]);
    DICT_SET_STRING(dict,@"incomingTcapEnd",[((UMASN1Object *)_incomingTcapEnd) jsonCompactString ]);
    DICT_SET_STRING(dict,@"incomingTcapAbort",[((UMASN1Object *)_incomingTcapAbort) jsonCompactString ]);
    DICT_SET_STRING(dict,@"incomingTcapUnidirectional",[((UMASN1Object *)_incomingTcapUnidirectional) jsonCompactString]);
    switch(_incomingTcapCommand)
    {
        case TCAP_TAG_ANSI_UNIDIRECTIONAL:
            dict[@"incomingTcapCommand"] = @"ANSI_UNIDIRECTIONAL";
            break;
        case TCAP_TAG_ANSI_QUERY_WITH_PERM:
            dict[@"incomingTcapCommand"] = @"ANSI_QUERY_WITH_PERM:";
            break;
        case TCAP_TAG_ANSI_QUERY_WITHOUT_PERM:
            dict[@"incomingTcapCommand"] = @"ANSI_QUERY_WITHOUT_PERM";
            break;
        case TCAP_TAG_ANSI_RESPONSE:
            dict[@"incomingTcapCommand"] = @"ANSI_RESPONSE";
            break;
        case TCAP_TAG_ANSI_CONVERSATION_WITH_PERM:
            dict[@"incomingTcapCommand"] = @"CONVERSATION_WITH_PERM";
            break;
        case TCAP_TAG_ANSI_CONVERSATION_WITHOUT_PERM:
            dict[@"incomingTcapCommand"] = @"ANSI_CONVERSATION_WITHOUT_PERM";
            break;

        case TCAP_TAG_ANSI_ABORT:
            dict[@"incomingTcapCommand"] = @"ANSI_ABORT";
            break;
                /* ITU commands are equal to asn1.tag number */
        case TCAP_TAG_ITU_UNIDIRECTIONAL:
            dict[@"incomingTcapCommand"] = @"UNIDIRECTIONAL";
            break;
        case TCAP_TAG_ITU_BEGIN:
            dict[@"incomingTcapCommand"] = @"BEGIN";
            break;
        case TCAP_TAG_ITU_END:
            dict[@"incomingTcapCommand"] = @"END";
            break;
        case TCAP_TAG_ITU_CONTINUE:
            dict[@"incomingTcapCommand"] = @"CONTINUE";
            break;
        case TCAP_TAG_ITU_ABORT:
            dict[@"incomingTcapCommand"] = @"ABORT";
            break;
        default:
            dict[@"incomingTcapCommand"] = @"";
            break;
    }

    DICT_SET_STRING(dict,@"incomingApplicationContext",_incomingApplicationContext);
    DICT_SET_STRING(dict,@"incomingGsmMapAsn1",[_incomingGsmMapAsn1 jsonCompactString]);
    DICT_SET_INTEGER(dict,@"incomingGsmMapOperation",_incomingGsmMapOperation);
    DICT_SET_INTEGER(dict,@"incomingCategory",_incomingCategory);
    DICT_SET_STRING(dict,@"incomingLocalTransactionId",_incomingLocalTransactionId);
    DICT_SET_STRING(dict,@"incomingRemoteTransactionId",_incomingRemoteTransactionId);
    DICT_SET_BOOL(dict,@"canNotDecode",_canNotDecode);
    DICT_SET_STRING(dict,@"incomingRemoteTransactionId",_incomingRemoteTransactionId);

    UMSynchronizedDictionary    *_tags;
        UMSynchronizedDictionary    *_vars;
        SccpDestinationGroup        *_rerouteDestinationGroup;
        UMLogLevel                  _logLevel;
    }
}
@end
