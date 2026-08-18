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
        _tcapSharingTraceLevel = UMLOG_MINOR;
	}
	return self;
}


- (NSString *)incomingPacketType
{
    return [UMSCCP_Packet sccpServiceTypeToString:_incomingServiceType];
}

- (NSString *)outgoingPacketType
{
    return [UMSCCP_Packet sccpServiceTypeToString:_outgoingServiceType];
}

- (void)copyIncomingToOutgoing
{
    _outgoingLocalUser              = _incomingLocalUser;
    _outgoingMtp3Layer              = _incomingMtp3Layer;
//  _outgoingLinksetName            = _incomingLinksetName;
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
    _outgoingCallingPartyAddress    = [_incomingCallingPartyAddress copy];
    _outgoingCalledPartyAddress     = [_incomingCalledPartyAddress copy];
    _outgoingMtp3Data               = _incomingMtp3Data;
    _outgoingSccpData               = _incomingSccpData;
    _outgoingOptionalData           = _incomingOptionalData;
    _outgoingSegment                = _incomingSegment;
    _outgoingTcapCommand            = _incomingTcapCommand;
    _outgoing_tcap_otid             = _incoming_tcap_otid;
    _outgoing_tcap_dtid             = _incoming_tcap_dtid;
}

- (UMSCCP_Packet *)copyWithZone:(NSZone *)zone
{
    UMSCCP_Packet *cpy = [[UMSCCP_Packet alloc]init];
    cpy.instance = _instance;
    cpy.sccp = _sccp;
    cpy.created = _created;
    cpy.afterFilter1 = _afterFilter1;
    cpy.afterFilter2 = _afterFilter2;
    cpy.afterFilter3 = _afterFilter3;
    cpy.afterFilter4 = _afterFilter4;
    cpy.reassembled = _reassembled;
    cpy.routed = _routed;
    cpy.segmented = _segmented;
    cpy.queuedForDelivery = _queuedForDelivery;
    cpy.state = _state;
    cpy.incomingSegment = [_incomingSegment copy];
    cpy.incomingLocalUser = _incomingLocalUser;
    cpy.incomingMtp3Layer = _incomingMtp3Layer;
    cpy.incomingLinksetName = _incomingLinksetName;
    cpy.incomingOptions = _incomingOptions;
    cpy.incomingOpc = _incomingOpc;
    cpy.incomingDpc = _incomingDpc;
    cpy.incomingServiceClass = _incomingServiceClass;
    cpy.incomingServiceType = _incomingServiceType;
    cpy.incomingHandling = _incomingHandling;
    cpy.incomingMaxHopCount = _incomingMaxHopCount;
    cpy.incomingFromLocal = _incomingFromLocal;
    cpy.incomingToLocal = _incomingToLocal;
    cpy.incomingCallingPartyAddressBeforeTranslation = [_incomingCallingPartyAddressBeforeTranslation copy];
    cpy.incomingCalledPartyAddressBeforeTranslation = [_incomingCalledPartyAddressBeforeTranslation copy];
    cpy.incomingCallingPartyAddress = [_incomingCallingPartyAddress copy];
    cpy.incomingCallingPartyCountry = [_incomingCallingPartyCountry copy];
    cpy.incomingCalledPartyAddress = [_incomingCalledPartyAddress copy];
    cpy.incomingCalledPartyCountry = [_incomingCalledPartyCountry copy];
    cpy.incomingMtp3Data = [_incomingMtp3Data copy];
    cpy.incomingSccpData = [_incomingSccpData copy];
    cpy.incomingOptionalData = [_incomingOptionalData copy];
    cpy.incomingReturnCause = _incomingReturnCause;
    cpy.outgoingLocalUser = _outgoingLocalUser;
    cpy.outgoingMtp3Layer = _outgoingMtp3Layer;
    cpy.outgoingLinksetName = _outgoingLinksetName;
    cpy.outgoingOptions = _outgoingOptions;
    cpy.outgoingOpc = _outgoingOpc;
    cpy.outgoingDpc = _outgoingDpc;
    cpy.outgoingServiceClass = _outgoingServiceClass;
    cpy.outgoingServiceType = _outgoingServiceType;
    cpy.outgoingHandling = _outgoingHandling;
    cpy.outgoingCallingPartyAddress = [_outgoingCallingPartyAddress copy];
    cpy.outgoingCalledPartyAddress = [_outgoingCalledPartyAddress copy];
    cpy.outgoingMtp3Data = _outgoingMtp3Data;
    cpy.outgoingSccpData = _outgoingSccpData;
    cpy.outgoingSegment = [_outgoingSegment copy];
    cpy.outgoingOptionalData = _outgoingOptionalData;
    cpy.outgoingMaxHopCount = _outgoingMaxHopCount;
    cpy.outgoingFromLocal = _outgoingFromLocal;
    cpy.outgoingToLocal = _outgoingToLocal;
    cpy.outgoingReturnCause = _outgoingReturnCause;
    cpy.outgoingDestination = _outgoingDestination;
    cpy.incomingTcapAsn1            = _incomingTcapAsn1;
    cpy.incomingTcapBegin           = _incomingTcapBegin;
    cpy.incomingTcapContinue        = _incomingTcapContinue;
    cpy.incomingTcapEnd             = _incomingTcapEnd;
    cpy.incomingTcapAbort           = _incomingTcapAbort;
    cpy.incomingTcapUnidirectional  = _incomingTcapUnidirectional;
    cpy.incomingTcapCommand         = _incomingTcapCommand;
    cpy.incomingApplicationContext = _incomingApplicationContext;
    cpy.incomingGsmMapAsn1 = _incomingGsmMapAsn1;
    cpy.incomingGsmMapOperations = _incomingGsmMapOperations;
    cpy.incomingCategory = _incomingCategory;
    cpy.canNotDecode = _canNotDecode;
    cpy.tags = [_tags copy];
    cpy.vars = [_vars copy];
    cpy.rerouteDestinationGroup = _rerouteDestinationGroup;
    cpy.logLevel =     _logLevel;
    cpy.incoming_tcap_otid = _incoming_tcap_otid;
    cpy.incoming_tcap_dtid = _incoming_tcap_dtid;
    cpy.msisdn = _msisdn;
    cpy.imsi = _imsi;
    cpy.smsc = _smsc;
    cpy.hlr = _hlr;
    cpy.msc = _msc;
    cpy.sms = _sms;
    cpy.partsInfo = _partsInfo;
    cpy.routingSelector = _routingSelector;
    cpy.sls = _sls;
    cpy.incomingLinksetTcapSharingInsideName    = _incomingLinksetTcapSharingInsideName;
    cpy.incomingLinksetTcapSharingOutsideName   = _incomingLinksetTcapSharingOutsideName;
    cpy.incomingLinksetTcapSharingInside        = _incomingLinksetTcapSharingInside;
    cpy.incomingLinksetTcapSharingOutside       = _incomingLinksetTcapSharingOutside;
    cpy.incomingLinksetTcapSharingPriority      = _incomingLinksetTcapSharingPriority;
    cpy.errorCauseValue                         = _errorCauseValue;
    cpy.forcedDestinationName                   = _forcedDestinationName;
    cpy.forcedDestinationGroup                  = _forcedDestinationGroup;
    cpy.forcedLinkset                           = _forcedLinkset;
    cpy.forcedDpc                               = _forcedDpc;
    cpy.forcedLocalUser                         = _forcedLocalUser;
    cpy.tcapSharingTraceLevel                   = _tcapSharingTraceLevel;
    
    cpy.routingTest = _routingTest;
    cpy.routingTestTcapTransactionId = _routingTestTcapTransactionId;
    cpy.routingTestApplicationContext = _routingTestApplicationContext;
    cpy.routingTestMapOperation = _routingTestMapOperation;
    cpy.routingTestDebug = _routingTestDebug;
    return cpy;
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
    [s appendFormat:@"\t_state: %@\n", [UMSCCP_Packet sccpStatToString:_state]];
    [s appendFormat:@"\t_incomingLocalUser: %@\n", _incomingLocalUser ? _incomingLocalUser.layerName : @"NULL"];
    [s appendFormat:@"\t_incomingMtp3Layer: %@\n", _incomingMtp3Layer ? _incomingMtp3Layer.layerName : @"NULL"];
    [s appendFormat:@"\t_incomingOptions: %@\n", _incomingOptions ? _incomingOptions : @"NULL"];
    [s appendFormat:@"\t_incomingOpc: %@\n", _incomingOpc ? _incomingOpc : @"NULL"];
    [s appendFormat:@"\t_incomingOptions: %@\n", _incomingDpc ? _incomingDpc : @"NULL"];
    [s appendFormat:@"\t_incomingServiceClass: %@\n",[UMSCCP_Packet sccpServiceClassToString:_incomingServiceClass]];
    [s appendFormat:@"\t_incomingServiceType: %@\n",[UMSCCP_Packet sccpServiceTypeToString:_incomingServiceType]];
    [s appendFormat:@"\t_incomingHandling: %d\n",_incomingHandling];
    [s appendFormat:@"\t_incomingMaxHopCount: %d\n",_incomingMaxHopCount];
    [s appendFormat:@"\t_incomingFromLocal: %@\n",_incomingFromLocal ? @"YES" : @"NO"];
    [s appendFormat:@"\t_incomingToLocal: %@\n",_incomingToLocal ? @"YES" : @"NO"];
    [s appendFormat:@"\t_incomingCallingPartyAddress: %@\n",_incomingCallingPartyAddress.description];
    [s appendFormat:@"\t_incomingCalledPartyAddress: %@\n",_incomingCalledPartyAddress.description];
    [s appendFormat:@"\t_incomingMtp3Data: %@\n",_incomingMtp3Data.hexString];
    [s appendFormat:@"\t_incomingSccpData: %@\n",_incomingSccpData.hexString];
    [s appendFormat:@"\t_incomingOptionalData: %@\n",_incomingOptionalData.hexString];

    if(_incomingReturnCause!=SCCP_ReturnCause_not_set)
    {
        [s appendFormat:@"\t_incomingReturnCause: %@\n",[UMSCCP_Packet sccpReturnCauseString:_incomingReturnCause]];
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
    [s appendFormat:@"\t_incomingGsmMapOperation: %@\n",_incomingGsmMapOperations];
    [s appendFormat:@"\t_incomingCategory: %d\n",_incomingCategory];
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
    
    if(_routingTest)
    {
        [s appendFormat:@"\t_routingTest: YES"];
    }
    if(_routingTestTcapTransactionId)
    {
        [s appendFormat:@"\t_routingTestTcapTransactionId: %@",_routingTestTcapTransactionId];
    }
    if(_routingTestApplicationContext)
    {
        [s appendFormat:@"\t_routingTestApplicationContext: %@",_routingTestApplicationContext];
    }
    if(_routingTestMapOperation)
    {
        [s appendFormat:@"\t_routingTestMapOperation: %@",_routingTestMapOperation];
    }
    if(_routingTestDebug)
    {
        [s appendFormat:@"\t__routingTestDebug: YES"];
    }


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
    DICT_SET_STRING(dict, @"mtp_inbound_linkset",_incomingLinksetName);
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
    DICT_SET_STRING(dict, @"mtp_outbound_linkset",_outgoingLinksetName);
    DICT_SET_STRING(dict, @"mtp_outound_localuser",[_outgoingLocalUser layerName]);
    DICT_SET_STRING(dict, @"mtp_outbound_linkset",_outgoingLinksetName);
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

    dict[@"sccp_state"] = [UMSCCP_Packet sccpStatToString:_state];

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
    
    dict[@"sccp_service_type"] = [UMSCCP_Packet sccpServiceTypeToString:_incomingServiceType];
    DICT_SET_INTEGER(dict,@"sccp_handling",_incomingHandling);
    DICT_SET_INTEGER(dict,@"sccp_hopcount",_incomingMaxHopCount);
    if(hasCause)
    {
        NSString *s = [UMLayerSCCP causeValueToString: _incomingReturnCause];
        dict[@"sccp_return_cause"] = [NSString stringWithFormat:@"%d: %@",_incomingReturnCause,s];
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

- (void)applyIncomingNumberTranslation
{
    BOOL translationWasApplied = NO;

    _incomingCallingPartyAddressBeforeTranslation = [_incomingCallingPartyAddress copy];
    _incomingCalledPartyAddressBeforeTranslation = [_incomingCalledPartyAddress copy];
    
    if(_cga_number_translation_in)
    {
        translationWasApplied = YES;
        if(self.logLevel <=UMLOG_DEBUG)
        {
            [self.logFeed debugText:[NSString stringWithFormat:@"applying cga_number_translation_in=%@",_cga_number_translation_in.name]];
        }
        NSNumber *newCallingTT = NULL;
        NSNumber *newCalledTT = NULL;
        _incomingCallingPartyAddress = [_cga_number_translation_in translateAddress:_incomingCallingPartyAddressBeforeTranslation
                                                                       newCallingTT:&newCallingTT
                                                                        newCalledTT:&newCalledTT];
        if(newCallingTT)
        {
            _incomingCallingPartyAddress.tt.tt = newCallingTT.intValue;
        }
        if(newCalledTT)
        {
            _incomingCalledPartyAddress.tt.tt = newCalledTT.intValue;
        }
    }
    if(_cda_number_translation_in)
    {
        translationWasApplied = YES;
        if(self.logLevel <=UMLOG_DEBUG)
        {
            [self.logFeed debugText:[NSString stringWithFormat:@"applying cda_number_translation_in=%@",_cda_number_translation_in.name]];
        }
        NSNumber *newCallingTT = NULL;
        NSNumber *newCalledTT = NULL;
        _incomingCalledPartyAddress = [_cda_number_translation_in translateAddress:_incomingCalledPartyAddressBeforeTranslation
                                                                      newCallingTT:&newCallingTT
                                                                       newCalledTT:&newCalledTT];
        if(newCallingTT)
        {
            _incomingCallingPartyAddress.tt.tt = newCallingTT.intValue;
        }
        if(newCalledTT)
        {
            _incomingCalledPartyAddress.tt.tt = newCalledTT.intValue;
        }
    }
    
    if(self.logLevel <=UMLOG_DEBUG)
    {
        if(translationWasApplied == YES)
        {
            [self.logFeed debugText:@"applyIncomingNumberTranslation: done something"];
            [self.logFeed debugText:[NSString stringWithFormat:@"CALLING_PARTY_ADDRESS_BEFORE_TRANSLATION:%@" ,_incomingCallingPartyAddressBeforeTranslation]];
            [self.logFeed debugText:[NSString stringWithFormat:@"CALLING_PARTY_ADDRESS_AFTER_TRANSLATION:%@"  ,_incomingCallingPartyAddress]];
            [self.logFeed debugText:[NSString stringWithFormat:@"CALLED_PARTY_ADDRESS_BEFORE_TRANSLATION:%@"  ,_incomingCalledPartyAddressBeforeTranslation]];
            [self.logFeed debugText:[NSString stringWithFormat:@"CALLED_PARTY_ADDRESS_AFTER_TRANSLATION:%@"   ,_incomingCalledPartyAddress]];
        }
        else
        {
            [self.logFeed debugText:@"applyIncomingNumberTranslation: done nothing"];
        }
    }
}

- (void)applyOutgoingNumberTranslation
{
    _outgoingCallingPartyAddressBeforeTranslation = [_outgoingCallingPartyAddress copy];
    _outgoingCalledPartyAddressBeforeTranslation = [_outgoingCalledPartyAddress copy];
    
    if(_cga_number_translation_out)
    {
        NSNumber *newCallingTT = NULL;
        NSNumber *newCalledTT = NULL;
        _outgoingCallingPartyAddress = [_cga_number_translation_out translateAddress:_outgoingCallingPartyAddressBeforeTranslation
                                                                        newCallingTT:&newCallingTT
                                                                         newCalledTT:&newCalledTT];
        if(newCalledTT)
        {
            _outgoingCalledPartyAddress.tt.tt = newCalledTT.intValue;
        }
        if(newCallingTT)
        {
            _outgoingCallingPartyAddress.tt.tt = newCallingTT.intValue;
        }
    }
    if(_cda_number_translation_out)
    {
        NSNumber *newCallingTT = NULL;
        NSNumber *newCalledTT = NULL;
        _outgoingCalledPartyAddress = [_cda_number_translation_out translateAddress:_outgoingCalledPartyAddressBeforeTranslation
                                                                      newCallingTT:&newCallingTT
                                                                       newCalledTT:&newCalledTT];
        if(newCalledTT)
        {
            _outgoingCalledPartyAddress.tt.tt = newCalledTT.intValue;
        }
        if(newCallingTT)
        {
            _outgoingCallingPartyAddress.tt.tt = newCallingTT.intValue;
        }
    }
}


+(NSString *)sccpServiceTypeToString:(SCCP_ServiceType)i
{
    switch(i)
    {
        case SCCP_UDT:
        {
            return @"UDT";
        }
        case SCCP_UDTS:
        {
            return @"UDTS";
        }
        case SCCP_XUDT:
        {
            return @"XUDT";
        }
        case SCCP_XUDTS:
        {
            return @"XUDTS";
        }
        case SCCP_LUDT:
        {
            return @"LUDT";
        }
        case SCCP_LUDTS:
        {
            return @"LUDTS";
        }
        default:
        {
            return [NSString stringWithFormat:@"%d",i];
        }
    }
}

+ (SCCP_ServiceType) stringToSccpServiceType:(NSString *)str
{
    if([str isEqualToStringCaseInsensitive:@"UDT"])
    {
        return SCCP_UDT;
    }
    else if([str isEqualToStringCaseInsensitive:@"UDTS"])
    {
        return SCCP_UDTS;
    }
    else if([str isEqualToStringCaseInsensitive:@"XUDT"])
    {
        return SCCP_XUDT;
    }
    else if([str isEqualToStringCaseInsensitive:@"XUDTS"])
    {
        return SCCP_XUDTS;
    }
    else if([str isEqualToStringCaseInsensitive:@"LUDT"])
    {
        return SCCP_LUDT;
    }
    else if([str isEqualToStringCaseInsensitive:@"LUDTS"])
    {
        return SCCP_LUDTS;
    }
    else
    {
        return (SCCP_ServiceType)[str integerValue];
    }
}


+ (NSString *) sccpStatToString:(SCCP_State)state
{
    NSString *s;
    switch(state)
    {
        case SCCP_STATE_IDLE:
            s = @"IDLE";
            break;
            
        case SCCP_STATE_DATA_TRANSFER:
            s = @"DATA_TRANSFER";
            break;
            
        case SCCP_STATE_INCOMING_CONNECTION_PENDING:
            s = @"INCOMING_CONNECTION_PENDING";
            break;
            
        case SCCP_STATE_PROVIDER_INITIATED_RESET_PENDING:
            s = @"PROVIDER_INITIATED_RESET_PENDING";
            break;
            
        case SCCP_STATE_OUTGOING_CONNECTION_PENDING:
            s = @"OUTGOING_CONNECTION_PENDING";
            break;
            
        case SCCP_STATE_USER_REQUEST_RESET_PENDING:
            s = @"USER_REQUEST_RESET_PENDING";
            break;
        default:
            s = [NSString stringWithFormat:@"unknown(%d)",(int)state];
            break;
    }
    return s;
}

+ (NSString *) sccpServiceClassToString:(SCCP_ServiceClass)serviceClass
{
    NSString *s;
    switch(serviceClass)
    {
        case SCCP_CLASS_UNDEFINED:
            s = @"UNDEFINED";
            break;
        case SCCP_CLASS_BASIC:
            s = @"BASIC";
            break;
        case SCCP_CLASS_INSEQ_CL:
            s = @"INSEQ_CL";
            break;
        case SCCP_CLASS_BASIC_CO:
            s = @"BASIC_CO";
            break;
        case SCCP_CLASS_FLOW_CONTROL_CO:
            s = @"FLOW_CONTROL_CO";
            break;
        default:
            s = [NSString stringWithFormat:@"unknown(%d)",(int)serviceClass];
            break;
    }
    return s;
}

+ (NSString *) sccpReturnCauseString:(SCCP_ReturnCause)cause
{
    switch(cause)
    {
        case SCCP_ReturnCause_not_set:
            return @"ReturnCause_not_set";
            break;
        case SCCP_ReturnCause_NoTranslationForAnAddressOfSuchNature:
            return @"NoTranslationForAnAddressOfSuchNature";
            break;
        case    SCCP_ReturnCause_NoTranslationForThisSpecificAddress :
            return @"NoTranslationForThisSpecificAddress";
            break;
        case    SCCP_ReturnCause_SubsystemCongestion:
            return @"SubsystemCongestion";
            break;
        case    SCCP_ReturnCause_SubsystemFailure:
            return @"SubsystemFailure";
            break;
        case    SCCP_ReturnCause_Unequipped:
            return @"Unequipped";
            break;
        case   SCCP_ReturnCause_MTPFailure:
            return @"MTPFailure";
            break;
        case   SCCP_ReturnCause_NetworkCongestion:
           return @"NetworkCongestion";
            break;
        case   SCCP_ReturnCause_Unqualified:
            return @"Unqualified";
            break;
        case    SCCP_ReturnCause_ErrorInMessageTransport:
            return @"ErrorInMessageTransport";
            break;
        case   SCCP_ReturnCause_ErrorInLocalProcessing:
            return @"ErrorInLocalProcessing";
            break;
        case    SCCP_ReturnCause_DestinationCannotPerformReassembly:
            return @"DestinationCannotPerformReassembly";
            break;
        case    SCCP_ReturnCause_SCCPFailure:
            return @"SCCPFailure";
            break;
        case    SCCP_ReturnCause_HopCounterViolation:
            return @"HopCounterViolation";
            break;
        case   SCCP_ReturnCause_SegmentationNotSupported:
            return @"SegmentationNotSupported";
            break;
        case    SCCP_ReturnCause_SegmentationFailure:
            return @"SegmentationFailure";
            break;
        default:
            return [NSString stringWithFormat:@"UnknownReturnCause_%d",cause];
            break;
    }
}
@end
