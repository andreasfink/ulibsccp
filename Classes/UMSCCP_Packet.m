//
//  UMSCCP_Packet.m
//  ulibsccp
//
//  Created by Andreas Fink on 11.01.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_Packet.h"
#import "UMLayerSCCP.h"
#import "UMSCCP_Segment.h"

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


#define DICT_SET_STRING(dict,name,str)  \
    { \
        if(str) \
        { \
            id ptr = str; \
            NSString *s; \
            if([ptr isKindOfClass:[NSString class]]) \
            { \
                s = (NSString *)ptr; \
            } \
            else if([ptr isKindOfClass:[NSDate class]]) \
            { \
                s = [ptr stringValue]; \
            } \
            else if([ptr isKindOfClass:[NSNumber class]]) \
            { \
                s = [ptr stringValue]; \
            } \
            else \
            { \
                NSLog(@"Can  not convert field %@ (type=%@) to string",name,[ptr class]); \
            } \
            if(s.length> 0) \
            { \
                dict[name] = s; \
            } \
            else \
            { \
                dict[name] = @""; \
            } \
        } \
        else \
        { \
            dict[name] = @""; \
        } \
    }

#define DICT_SET_INTEGER(dict,name,i)    dict[name] = [NSString stringWithFormat:@"%d",i];
#define DICT_SET_BOOL(dict,name,b)       dict[name] =  b ? @"1" : @"0";

@implementation UMSCCP_Packet

- (UMSCCP_Packet *)init
{
	self = [super init];
	if(self)
	{
		_created = [NSDate date];
        _tags = [[UMSynchronizedDictionary alloc]init];
        _incomingReturnCause = SCCP_ReturnCause_not_set;
        _outgoingReturnCause = SCCP_ReturnCause_not_set;

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
    _outgoingSegment                = _incomingSegment;
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

- (UMSynchronizedSortedDictionary *)dictionaryValue
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];

    NSString *s = [_created stringValue];
    DICT_SET_STRING(dict, @"timestamp",s);
    DICT_SET_STRING(dict, @"msisdn",_msisdn);
    DICT_SET_STRING(dict, @"imsi",_imsi);
    dict[@"transparent"] = @"1";
    DICT_SET_STRING(dict, @"mtp_inbound_instance",[_incomingMtp3Layer layerName]);
    DICT_SET_STRING(dict, @"mtp_inbound_linkset",_incomingLinkset);
    DICT_SET_STRING(dict, @"mtp_inbound_localuser",[_incomingLocalUser layerName]);
    DICT_SET_INTEGER(dict,@"mtp_srism_opc",_incomingOpc.integerValue);
    DICT_SET_INTEGER(dict,@"mtp_srism_dpc",_incomingDpc.integerValue);
    DICT_SET_INTEGER(dict,@"mtp_forwardsm_opc",_incomingOpc.integerValue);
    DICT_SET_INTEGER(dict,@"mtp_forwardsm_dpc",_incomingDpc.integerValue);
    DICT_SET_STRING(dict, @"mtp_inbound_raw_packet",[_incomingMtp3Data hexString]);

    DICT_SET_INTEGER(dict,@"mtp_inbound_opc",_incomingOpc.integerValue);
    DICT_SET_INTEGER(dict,@"mtp_inbound_dpc",_incomingDpc.integerValue);
    DICT_SET_INTEGER(dict,@"mtp_inbound_si",3); /* we are in SCCP so there's nothing else possible */

    DICT_SET_STRING(dict, @"mtp_outbound_instance",[_outgoingMtp3Layer layerName]);
    DICT_SET_STRING(dict, @"mtp_outbound_linkset",_outgoingLinkset);
    DICT_SET_STRING(dict, @"mtp_outound_localuser",[_outgoingLocalUser layerName]);
    DICT_SET_STRING(dict, @"mtp_outbound_linkset",_outgoingLinkset);
    DICT_SET_INTEGER(dict,@"mtp_outbound_opc",_outgoingOpc.integerValue);
    DICT_SET_INTEGER(dict,@"mtp_outbound_dpc",_outgoingDpc.integerValue);
    DICT_SET_INTEGER(dict,@"mtp_outbound_si",3); /* we are in SCCP so there's nothing else possible */

    /* we skip 'mtp_debug' */

    DICT_SET_INTEGER(dict,@"sccp_inbound_calling_nai",_incomingCallingPartyAddress.nai.nai);
    DICT_SET_INTEGER(dict,@"sccp_inbound_calling_npi",_incomingCallingPartyAddress.npi.npi);
    DICT_SET_STRING(dict,@"sccp_inbound_calling_address",_incomingCallingPartyAddress.address);
    DICT_SET_STRING(dict,@"sccp_inbound_calling_country",_incomingCallingPartyAddress.country);
    DICT_SET_INTEGER(dict,@"sccp_inbound_calling_ssn",_incomingCallingPartyAddress.ssn.ssn);
    DICT_SET_INTEGER(dict,@"sccp_inbound_calling_tt",_incomingCallingPartyAddress.tt.tt);

    DICT_SET_INTEGER(dict,@"sccp_inbound_called_nai",_incomingCalledPartyAddress.nai.nai);
    DICT_SET_INTEGER(dict,@"sccp_inbound_called_npi",_incomingCalledPartyAddress.npi.npi);
    DICT_SET_STRING(dict,@"sccp_inbound_called_address",_incomingCalledPartyAddress.address);
    DICT_SET_STRING(dict,@"sccp_inbound_called_country",_incomingCalledPartyAddress.country);
    DICT_SET_INTEGER(dict,@"sccp_inbound_called_ssn",_incomingCalledPartyAddress.ssn.ssn);
    DICT_SET_INTEGER(dict,@"sccp_inbound_called_tt",_incomingCalledPartyAddress.tt.tt);


    DICT_SET_INTEGER(dict,@"sccp_outbound_calling_nai",_outgoingCallingPartyAddress.nai.nai);
    DICT_SET_INTEGER(dict,@"sccp_outbound_calling_npi",_outgoingCallingPartyAddress.npi.npi);
    DICT_SET_STRING(dict,@"sccp_outbound_calling_address",_outgoingCallingPartyAddress.address);
    DICT_SET_STRING(dict,@"sccp_outbound_calling_country",_outgoingCallingPartyAddress.country);
    DICT_SET_INTEGER(dict,@"sccp_outbound_calling_ssn",_outgoingCallingPartyAddress.ssn.ssn);
    DICT_SET_INTEGER(dict,@"sccp_outbound_calling_tt",_outgoingCallingPartyAddress.tt.tt);

    DICT_SET_INTEGER(dict,@"sccp_outbound_called_nai",_outgoingCalledPartyAddress.nai.nai);
    DICT_SET_INTEGER(dict,@"sccp_outbound_called_npi",_outgoingCalledPartyAddress.npi.npi);
    DICT_SET_STRING(dict,@"sccp_outbound_called_address",_outgoingCalledPartyAddress.address);
    DICT_SET_STRING(dict,@"sccp_outbound_called_country",_outgoingCalledPartyAddress.country);
    DICT_SET_INTEGER(dict,@"sccp_outbound_called_ssn",_outgoingCalledPartyAddress.ssn.ssn);
    DICT_SET_INTEGER(dict,@"sccp_outbound_called_tt",_outgoingCalledPartyAddress.tt.tt);

    UMSynchronizedSortedDictionary *dict2 = [[UMSynchronizedSortedDictionary alloc]init];
    DICT_SET_STRING(dict2,@"created",[_created stringValue]);
    DICT_SET_STRING(dict2,@"afterFilter1",[_afterFilter1 stringValue]);
    DICT_SET_STRING(dict2,@"reassembled",[_reassembled stringValue]);
    DICT_SET_STRING(dict,@"afterFilter2",[_afterFilter2 stringValue]);
    DICT_SET_STRING(dict2,@"routed",[_routed stringValue]);
    DICT_SET_STRING(dict2,@"afterFilter3",[_afterFilter3 stringValue]);
    DICT_SET_STRING(dict2,@"segmented",[_segmented stringValue]);
    DICT_SET_STRING(dict2,@"queuedForDelivery",[_queuedForDelivery stringValue]);
    DICT_SET_STRING(dict,@"sccp_debug",[dict2 jsonCompactString]);

    switch(_state)
    {
        case SCCP_STATE_IDLE:
            dict[@"sccp_state"] = @"IDLE";
            break;

        case SCCP_STATE_DATA_TRANSFER:
            dict[@"sccp_state"] = @"DATA_TRANSFER";
            break;

        case SCCP_STATE_INCOMING_CONNECTION_PENDING:
            dict[@"sccp_state"] = @"INCOMING_CONNECTION_PENDING";
            break;

        case SCCP_STATE_PROVIDER_INITIATED_RESET_PENDING:
            dict[@"sccp_state"] = @"PROVIDER_INITIATED_RESET_PENDING";
            break;

        case SCCP_STATE_OUTGOING_CONNECTION_PENDING:
            dict[@"sccp_state"] = @"OUTGOING_CONNECTION_PENDING";
            break;

        case SCCP_STATE_USER_REQUEST_RESET_PENDING:
            dict[@"sccp_state"] = @"USER_REQUEST_RESET_PENDING";
            break;
        default:
            dict[@"sccp_state"] = @"USER_REQUEST_RESET_PENDING";

    }


    switch(_incomingServiceClass)
    {
        case SCCP_CLASS_UNDEFINED:
            dict[@"sccp_service_class"] = @"UNDEFINED";
            break;
        case SCCP_CLASS_BASIC:
            dict[@"sccp_service_class"] = @"BASIC";
            break;
        case SCCP_CLASS_INSEQ_CL:
            dict[@"sccp_service_class"] = @"INSEQ_CL";
            break;
        case SCCP_CLASS_BASIC_CO:
            dict[@"sccp_service_class"] = @"BASIC_CO";
            break;
        case SCCP_CLASS_FLOW_CONTROL_CO:
            dict[@"sccp_service_class"] = @"FLOW_CONTROL_CO";
            break;
        default:
            dict[@"sccp_service_class"] = @"";
    }
    BOOL hasCause = NO;
    switch(_incomingServiceType)
    {
        case    SCCP_UDT:
            dict[@"sccp_service_type"] = @"UDT";
            break;
        case    SCCP_UDTS:
            dict[@"sccp_service_type"] = @"UDTS";
            hasCause = YES;

            break;
        case    SCCP_XUDT:
            dict[@"sccp_service_type"] = @"XUDT";
            break;
        case    SCCP_XUDTS:
            dict[@"sccp_service_type"] = @"XUDTS";
            hasCause = YES;
            break;
        case    SCCP_LUDT:
            dict[@"sccp_service_type"] = @"LUDT";
            break;
        case    SCCP_LUDTS:
            dict[@"sccp_service_type"] = @"LUDTS";
            hasCause = YES;
            break;
        default:
            dict[@"sccp_service_type"] = @"";
            break;
    }
    DICT_SET_INTEGER(dict,@"sccp_handling",_incomingHandling);
    DICT_SET_INTEGER(dict,@"sccp_hopcount",_incomingMaxHopCount);
    if(hasCause)
    {
        switch(_incomingReturnCause)
        {
            case SCCP_ReturnCause_NoTranslationForAnAddressOfSuchNature:
                dict[@"sccp_return_cause"] = @"0: NOTRANS NOA";
                break;
            case SCCP_ReturnCause_NoTranslationForThisSpecificAddress:
                dict[@"sccp_return_cause"] = @"1: NOTRANS ADDR";
                break;
            case SCCP_ReturnCause_SubsystemCongestion:
                dict[@"sccp_return_cause"] = @"2: CONGESTION";
                break;
            case SCCP_ReturnCause_SubsystemFailure:
                dict[@"sccp_return_cause"] = @"3: SSFAIL";
                break;
            case SCCP_ReturnCause_Unequipped:
                dict[@"sccp_return_cause"] = @"4: UNEQUIPPED";
                break;
            case SCCP_ReturnCause_MTPFailure:
                dict[@"sccp_return_cause"] = @"5: MTPFAIL";
                break;
            case SCCP_ReturnCause_NetworkCongestion:
                dict[@"sccp_return_cause"] = @"6: NETCONGEST";
                break;
            case SCCP_ReturnCause_Unqualified:
                dict[@"sccp_return_cause"] = @"7: UNQUALIFIED";
                break;
            case SCCP_ReturnCause_ErrorInMessageTransport:
                dict[@"sccp_return_cause"] = @"8: ERROR IN MSGTRANS";
                break;
            case SCCP_ReturnCause_ErrorInLocalProcessing:
                dict[@"sccp_return_cause"] = @"9: ERROR LOCAL PROC";
                break;
            case SCCP_ReturnCause_DestinationCannotPerformReassembly:
                dict[@"sccp_return_cause"] = @"10: REASSEMBLY NOT SUPP";
                break;
            case SCCP_ReturnCause_SCCPFailure:
                dict[@"sccp_return_cause"] = @"11: SCCPFAILURE";
                break;
            case SCCP_ReturnCause_HopCounterViolation:
                dict[@"sccp_return_cause"] = @"12: HOPCOUNT";
                break;
            case SCCP_ReturnCause_SegmentationNotSupported:
                dict[@"sccp_return_cause"] = @"13: SEGMENTATION NOTSUPP";
                break;
            case SCCP_ReturnCause_SegmentationFailure:
                dict[@"sccp_return_cause"] = @"14: SEGMENTATION FAILURE";
                break;
            case SCCP_ReturnCause_not_set:
            default:
                    dict[@"sccp_return_cause"] = @"";
                    break;
        }
    }
    return dict;
}

/* this is for SMS filters Other fields are appended in the filters */
- (UMSynchronizedSortedDictionary *)dictionaryValueForwardSM
{
    UMSynchronizedSortedDictionary *dict = [self dictionaryValue];
    DICT_SET_STRING(dict,@"msisdn",_msisdn);
    dict[@"transparent"] = @"1";
    dict[@"date_srism"] = @"";
    dict[@"date_srism_resp"] =@"";
    dict[@"date_forwardsm"] = @"";
    dict[@"date_forwardsm_resp"] = @"";

    DICT_SET_INTEGER(dict,@"sccp_inbound_calling_forwardsm_nai",_incomingCallingPartyAddress.nai.nai);
    DICT_SET_INTEGER(dict,@"sccp_inbound_calling_forwardsm_npi",_incomingCallingPartyAddress.npi.npi);
    DICT_SET_INTEGER(dict,@"sccp_inbound_calling_forwardsm_ssn",_incomingCallingPartyAddress.ssn.ssn);
    DICT_SET_INTEGER(dict,@"sccp_inbound_calling_forwardsm_tt", _incomingCallingPartyAddress.tt.tt);
    DICT_SET_STRING(dict,@"sccp_inbound_calling_forwardsm_address",_incomingCallingPartyAddress.address);
    DICT_SET_STRING(dict,@"sccp_inbound_calling_forwardsm_country",_incomingCallingPartyAddress.country); /* NEW */

    DICT_SET_INTEGER(dict,@"sccp_inbound_called_forwardsm_nai",_incomingCalledPartyAddress.nai.nai);
    DICT_SET_INTEGER(dict,@"sccp_inbound_called_forwardsm_npi",_incomingCalledPartyAddress.npi.npi);
    DICT_SET_INTEGER(dict,@"sccp_inbound_called_forwardsm_ssn",_incomingCalledPartyAddress.ssn.ssn);
    DICT_SET_INTEGER(dict,@"sccp_inbound_called_forwardsm_tt", _incomingCalledPartyAddress.tt.tt);
    DICT_SET_STRING(dict,@"sccp_inbound_called_forwardsm_address",_incomingCalledPartyAddress.address);
    DICT_SET_STRING(dict,@"sccp_inbound_called_forwardsm_country",_incomingCalledPartyAddress.country); /* NEW */

    return dict;
}
@end
