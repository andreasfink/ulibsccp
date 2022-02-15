//
//  UMSCCP_mtpTransfer.m
//  ulibsccp
//
//  Created by Andreas Fink on 05.04.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMSCCP_mtpTransfer.h"
#import "UMLayerSCCP.h"
#import "UMSCCP_Defs.h"
#import "UMSCCP_ReceivedSegments.h"
#import "UMSCCP_Packet.h"
#import "UMSCCP_StatisticDb.h"
#import "UMSCCP_PrometheusData.h"
#import "UMSCCP_Segment.h"

@implementation UMSCCP_mtpTransfer


- (UMSCCP_mtpTransfer *)initForSccp:(UMLayerSCCP *)layer
                               mtp3:(UMLayerMTP3 *)mtp3
                                opc:(UMMTP3PointCode *)xopc
                                dpc:(UMMTP3PointCode *)xdpc
                                 si:(int)xsi
                                 ni:(int)xni
                               data:(NSData *)xdata
                            options:(NSDictionary *)xoptions
{
    return [self initForSccp:layer
                        mtp3:mtp3
                         opc:xopc
                         dpc:xdpc
                          si:xsi
                          ni:xni
                        data:xdata
                     options:xoptions
                         map:NULL];

}

- (UMSCCP_mtpTransfer *)initForSccp:(UMLayerSCCP *)layer
                               mtp3:(UMLayerMTP3 *)mtp3
                                opc:(UMMTP3PointCode *)xopc
                                dpc:(UMMTP3PointCode *)xdpc
                                 si:(int)xsi
                                 ni:(int)xni
                               data:(NSData *)xdata
                            options:(NSDictionary *)xoptions
                                map:(UMMTP3TranslationTableMap *)ttmap;

{
    self = [super initWithName:@"UMSCCP_mtpTransfer" receiver:layer sender:mtp3 requiresSynchronisation:NO];
    if(self)
    {
		_packet = [[UMSCCP_Packet alloc]init];
        if(xoptions[@"created-timestamp"])
        {
            _packet.created = xoptions[@"created-timestamp"];
        }
		_packet.sccp = layer;
        _packet.logFeed = layer.logFeed;
        _packet.logLevel = layer.logLevel;
		_packet.incomingOpc = xopc;
		_packet.incomingDpc = xdpc;
        _map = ttmap;
        _data = xdata;

        if(xoptions)
        {
            _options = [xoptions mutableCopy];
        }
        else
        {
            _options = [[NSMutableDictionary alloc]init];
        }
        _options[@"mtp3-opc"] = xopc;
        _options[@"mtp3-dpc"] = xdpc;
		_packet.incomingMtp3Layer = mtp3;
        _packet.incomingLinkset = xoptions[@"mtp3-incoming-linkset"];
		_created = [NSDate date];
        _statsSection = UMSCCP_StatisticSection_TRANSIT;
        _opc = xopc;
        _dpc = xdpc;
        _si = xsi;
        _ni = xni;
        _sccpLayer = layer;
        _mtp3Layer = mtp3;
    }
    return self;
}

- (void)main
{
    @autoreleasepool
    {
        NSString *outgoingLinkset=NULL;

        _startOfProcessing = [NSDate date];
        /* we build a pseudo MTP3 raw packet for debugging /tracing and logging */
        UMMTP3Label *label = [[UMMTP3Label alloc]init];
        label.opc = _opc;
        label.dpc = _dpc;
        NSMutableData *rawMtp3 = [[NSMutableData alloc]init];
        int sio = ((_ni & 0x03) << 6) | (_si & 0x0F);
        [rawMtp3 appendByte:sio];
        [label appendToMutableData:rawMtp3];
        [rawMtp3 appendData:_data];
        _packet.incomingMtp3Data = rawMtp3;

        if(_options==NULL)
        {
            _options = [[NSMutableDictionary alloc]init];
        }
        _options[@"mtp3-pdu"] = rawMtp3;
        _options[@"sccp-pdu"] = [_data hexString];
        _packet.incomingSccpData = _data;
        
        BOOL decodeOnly = [_options[@"decode-only"] boolValue];
        if(decodeOnly)
        {
            _decodedJson = [[UMSynchronizedSortedDictionary alloc]init];
        }

        _packet.incomingServiceClass = SCCP_CLASS_UNDEFINED;
        @try
        {
            NSUInteger len = _data.length;
            if(len < 6)
            {
                @throw([NSException exceptionWithName:@"SCCP_TOO_SMALL_PACKET_RECEIVED" reason:NULL userInfo:NULL] );
            }
            const uint8_t *d = _data.bytes;
            int i = 0;
            int m_type = d[i++];
            int param_called_party_address;
            int param_calling_party_address;
            int param_data;
            int param_optional;
            int param_hop_counter = 0;
            NSString *type;

            _packet.incomingServiceType = m_type;
            _packet.outgoingServiceType = m_type;
            _packet.incomingHandling = SCCP_HANDLING_NO_SPECIAL_OPTIONS;
            _packet.outgoingHandling = SCCP_HANDLING_NO_SPECIAL_OPTIONS;

            switch(m_type)
            {
                case SCCP_UDT:
                    type = @"UDT";
                    _decodedJson[@"sccp-pdu-type"]=type;
                    _m_protocol_class = d[i] & 0x0F;
                    _m_handling = (d[i++]>>4) & 0x0F;

                    _packet.incomingServiceClass = _m_protocol_class;
                    _packet.outgoingServiceClass = _m_protocol_class;
                    if(_m_handling & 0x08)
                    {
                        _packet.incomingHandling = SCCP_HANDLING_RETURN_ON_ERROR;
                        _packet.outgoingHandling = SCCP_HANDLING_RETURN_ON_ERROR;
                    }
                    _decodedJson[@"sccp-protocol-class"]=@(_m_protocol_class);
                    _decodedJson[@"sccp-protocol-handling"]=@(_m_handling);
                    param_called_party_address = d[i] + i;
                    i++;
                    param_calling_party_address = d[i] + i;
                    i++;
                    param_data = d[i] + i;
                    i++;
                    param_optional = -1;
                    break;
                    
                case SCCP_UDTS:
                    type=@"UDTS";
                    _decodedJson[@"sccp-pdu-type"]=type;
                    _m_return_cause = d[i++] & 0x0F;
                    _packet.incomingReturnCause = _m_return_cause;
                    _decodedJson[@"sccp-return-cause"]=@(_m_return_cause);
                    param_called_party_address = d[i] + i;
                    i++;
                    param_calling_party_address = d[i] + i;
                    i++;
                    param_data      = d[i] + i;
                    i++;
                    param_optional   = -1;
                    break;
                    
                case SCCP_XUDT:
                    type=@"XUDT";
                    _decodedJson[@"sccp-pdu-type"]=type;
                    _m_protocol_class = d[i] & 0x0F;
                    _packet.incomingServiceClass = _m_protocol_class;
                    _packet.outgoingServiceClass = _m_protocol_class;
                    _decodedJson[@"sccp-protocol-class"]=@(_m_protocol_class);
                    _m_handling = (d[i++]>>4) & 0x0F;
                    if(_m_handling & 0x08)
                    {
                        _packet.incomingHandling = SCCP_HANDLING_RETURN_ON_ERROR;
                        _packet.outgoingHandling = SCCP_HANDLING_RETURN_ON_ERROR;
                    }
                    _decodedJson[@"sccp-protocol-handling"]=@(_m_handling);
                    param_hop_counter=d[i];
                    _packet.incomingMaxHopCount = param_hop_counter;
                    i++;
                    param_called_party_address = d[i] + i;
                    i++;
                    param_calling_party_address = d[i] + i;
                    i++;
                    param_data = d[i] + i;
                    i++;
                    param_optional = d[i] + i;
                    i++;
                    break;

                case SCCP_XUDTS:
                    type=@"XUDTS";
                    _decodedJson[@"sccp-pdu-type"]=type;
                    _m_return_cause = d[i++] & 0x0F;
                    _packet.incomingReturnCause = _m_return_cause;
                    _decodedJson[@"sccp-protocol-return-cause"]=@(_m_return_cause);
                    _m_hopcounter = d[i++] & 0x0F;
                    _decodedJson[@"sccp-hop-counter"]=@(_m_hopcounter);
                    _packet.incomingMaxHopCount = _m_return_cause;
                    param_called_party_address = d[i] + i;
                    i++;
                    param_calling_party_address = d[i] + i;
                    i++;
                    param_data      = d[i] + i;
                    i++;
                    param_optional   = d[i] + i;
                    i++;
                    break;

                default:
                    @throw([NSException exceptionWithName:@"SCCP_UNKNOWN_PACKET_TYPE" reason:NULL
                                                 userInfo:@{@"mtp3": [rawMtp3 hexString] } ]);
            }
            if(param_called_party_address > len)
            {
                @throw([NSException exceptionWithName:@"SCCP_PTR1_POINTS_BEYOND_END" reason:NULL userInfo:@{@"mtp3": [rawMtp3 hexString] }] );
                return;
            }
            
            if(param_calling_party_address > len)
            {
                @throw([NSException exceptionWithName:@"SCCP_PTR2_POINTS_BEYOND_END" reason:NULL userInfo:@{@"mtp3": [rawMtp3 hexString] }] );
                return;
            }
            if(param_data > len)
            {
                @throw([NSException exceptionWithName:@"SCCP_PTR3_POINTS_BEYOND_END" reason:NULL userInfo:@{@"mtp3": [rawMtp3 hexString] }] );
                return;
            }
            if((param_optional > len) && (param_optional > 0))
            {
                @throw([NSException exceptionWithName:@"SCCP_PTR4_POINTS_BEYOND_END" reason:NULL userInfo:@{@"mtp3": [rawMtp3 hexString] }] );
                return;
            }
            NSData *dstData = NULL;
            NSData *srcData = NULL;
#if defined(SCCP_DECODING_DEBUG)
            if(_sccpLayer.sccpVariant == SCCP_VARIANT_ANSI)
            {
                NSLog(@"We are in ANSI mode");
            }
            else
            {
                NSLog(@"We are NOT in ANSI mode");
            }
#endif
            
            if(param_called_party_address>0)
            {
                i = (int)d[param_called_party_address];
                dstData = [NSData dataWithBytes:&d[param_called_party_address+1] length:i];
                if(_sccpLayer.sccpVariant == SCCP_VARIANT_ANSI)
                {
#if defined(SCCP_DECODING_DEBUG)
                    NSLog(@"Decoding ANSI SCCP Called Party Address %@",dstData);
#endif
                    _dst = [[SccpAddress alloc]initWithAnsiData:dstData];
#if defined(SCCP_DECODING_DEBUG)
                    NSLog(@"resulting %@",_dst.description);
#endif
                }
                else
                {
#if defined(SCCP_DECODING_DEBUG)
                    NSLog(@"Decoding ITU SCCP Called Party Address %@",dstData);
#endif
                    _dst = [[SccpAddress alloc]initWithItuData:dstData];
#if defined(SCCP_DECODING_DEBUG)
                    NSLog(@"resulting %@",_dst.description);
#endif
                }
                if(_map)
                {
                    _dst.tt.tt = [_map mapTT:_dst.tt.tt];
                }
                _decodedJson[@"sccp-called-party-address"]=[_dst dictionaryValue];
                _packet.incomingCalledPartyAddress = _dst;
            }
            if(param_calling_party_address>0)
            {
                i = (int)d[param_calling_party_address];
                srcData = [NSData dataWithBytes:&d[param_calling_party_address+1] length:i];
                if(_sccpLayer.sccpVariant == SCCP_VARIANT_ANSI)
                {
#if defined(SCCP_DECODING_DEBUG)
                    NSLog(@"Decoding ANSI SCCP Calling Party Address %@",dstData);
#endif
                    _src = [[SccpAddress alloc]initWithAnsiData:srcData];
#if defined(SCCP_DECODING_DEBUG)
                    NSLog(@"result: %@",_src.description);
#endif
                }
                else
                {
#if defined(SCCP_DECODING_DEBUG)
                    NSLog(@"Decoding ITU SCCP Calling Party Address %@",dstData);
#endif
                    _src = [[SccpAddress alloc]initWithItuData:srcData];
#if defined(SCCP_DECODING_DEBUG)
                        NSLog(@"result: %@",_src.description);
#endif
                }
                _decodedJson[@"sccp-calling-party-address"]=[_src dictionaryValue];
                _packet.incomingCalledPartyAddress = _src;
            }
            if(param_data > 0)
            {
                i = (int)d[param_data];
                _sccp_pdu = [NSData dataWithBytes:&d[param_data+1] length:i];
                _decodedJson[@"sccp-payload-bytes"]=[_sccp_pdu hexString];
                if(decodeOnly)
                {
                    id<UMSCCP_UserProtocol> user = [_sccpLayer getUserForSubsystem:_dst.ssn number:_dst];
                    id decodedUserPdu = [user decodePdu:_sccp_pdu];
                    _decodedPdu = _sccp_pdu;
                    _decodedJson[@"sccp-payload"]=decodedUserPdu;
                }
                _packet.incomingSccpData = _sccp_pdu;
            }
            if(param_optional > 0)
            {
                _sccp_optional = [NSData dataWithBytes:&d[param_optional] length:len-param_optional];
                _packet.incomingOptionalData = _sccp_optional;
                _decodedJson[@"sccp-optional-raw"] = _sccp_optional.hexString;
                const uint8_t *bytes = _sccp_optional.bytes;
                NSUInteger m = _sccp_optional.length;
                NSUInteger j=0;
                while(j<m)
                {
                    int paramType = bytes[j++];
                    if(j<m)
                    {
                        int len = bytes[j++];
                        if((j+len)<m)
                        {
                            _optional_dict = [[NSMutableDictionary alloc]init];
                            NSData *param = [NSData dataWithBytes:&bytes[j] length:len];
                            j = j+len;
                            if(paramType==0x00)
                            {
                                break; /*end of optional parameters */
                            }
                            switch(paramType)
                            {
                                case 0x01:
                                    _optional_dict[@"destination-local-reference"] = param;
                                    break;
                                case 0x02:
                                    _optional_dict[@"source-local-reference"] = param;
                                    break;
                                case 0x03:
                                    _optional_dict[@"called-party-address"] = param;
                                    break;
                                case 0x04:
                                    _optional_dict[@"calling-party-address"] = param;
                                    break;
                                case 0x05:
                                    _optional_dict[@"protocol-class"] = param;
                                    break;
                                case 0x06:
                                    _optional_dict[@"segmenting-reassembling"] = param;
                                    break;
                                case 0x07:
                                    _optional_dict[@"receive-sequence-number"] = param;
                                    break;
                                case 0x08:
                                    _optional_dict[@"sequencing-segmenting"] = param;
                                    break;
                                case 0x09:
                                    _optional_dict[@"credit"] = param;
                                    break;
                                case 0x0a:
                                    _optional_dict[@"release-cause"] = param;
                                    break;
                                case 0x0b:
                                    _optional_dict[@"return-cause"] = param;
                                    break;
                                case 0x0c:
                                    _optional_dict[@"reset-cause"] = param;
                                    break;
                                case 0x0d:
                                    _optional_dict[@"error-cause"] = param;
                                    break;
                                case 0x0e:
                                    _optional_dict[@"refusal-cause"] = param;
                                    break;
                                case 0x0f:
                                    _optional_dict[@"data"] = param;
                                    break;
                                case 0x10:
                                {
                                    _optional_dict[@"segmentation"] = param;
                                    //_packet.incomingSegment = [[UMSCCP_Segment alloc]initWithHeaderData:param];
                                    // _packet.incomingSegment.data = _packet.incomingSccpData;
                                }
                                    break;
                                case 0x11:
                                    _optional_dict[@"hop-counter"] = param;
                                    break;
                                case 0x12:
                                    _optional_dict[@"importance"] = param;
                                    break;
                                case 0x13:
                                    _optional_dict[@"long-data"] = param;
                                    break;
                                    
                                
                            }
                        }
                    }
                }
                _decodedJson[@"sccp-optional"] = _optional_dict;
            }
            
            if(_src == NULL)
            {
                @throw([NSException exceptionWithName:@"SCCP_MISSING_CALLING_PARTY_ADDRESS" reason:NULL userInfo:@{@"mtp3": [rawMtp3 hexString] }] );
            }
            if(_dst==NULL)
            {
                @throw([NSException exceptionWithName:@"SCCP_MISSING_CALLED_PARTY_ADDRESS" reason:NULL userInfo:@{@"mtp3": [rawMtp3 hexString] }] );
            }

            NSDictionary *o = @{
                                @"type" : type,
                                @"action" : @"rx",
                                @"opc"  : _opc.stringValue,
                                @"dpc"  : _dpc.stringValue,
                                @"mtp3" : (_mtp3Layer ? _mtp3Layer.layerName : @"")
                                };
            [_sccpLayer traceReceivedPdu:_data options:o];
            [_sccpLayer traceReceivedPacket:_packet options:o];

            _options[@"sccp-calling-address"] = _src;
            _options[@"sccp-called-address"] = _dst;
            _packet.incomingCallingPartyAddress = _src;
            _packet.incomingCalledPartyAddress = _dst;

            _packet.incomingCallingPartyCountry = [_packet.incomingCallingPartyAddress country];
            _packet.incomingCalledPartyCountry = [_packet.incomingCalledPartyAddress country];

            if(!decodeOnly)
            {
                [_packet copyIncomingToOutgoing];
                if(_packet.logLevel <=UMLOG_DEBUG)
                {
                    NSMutableString *s = [[NSMutableString alloc]init];
                    if(_packet.incomingFromLocal)
                    {
                        [s appendFormat:@"MsgType %@   from local\n",_packet.incomingPacketType];
                    }
                    else
                    {
                        [s appendFormat:@"MsgType %@   LS: %@\n",_packet.incomingPacketType,_packet.incomingLinkset];
                    }
                    [s appendFormat:@"OPC: %@\tCgPA: %@\n",_packet.incomingOpc,_packet.incomingCallingPartyAddress];
                    [s appendFormat:@"DPC: %@\tCdPA: %@\n",_packet.incomingDpc,_packet.incomingCalledPartyAddress];
                    [_sccpLayer.logFeed debugText:s];
                }

                switch(m_type)
                {
                    case SCCP_UDT:
                        _options[@"sccp-udt"] = @(YES);
                        break;
                    case SCCP_UDTS:
                        _options[@"sccp-udts"] = @(YES);
                        break;
                    case SCCP_XUDT:
                        _options[@"sccp-xudt"] = @(YES);
                        break;
                    case SCCP_XUDTS:
                        _options[@"sccp-xudts"] = @(YES);
                        break;
                }

                _packet.incomingOptions = _options;

                UMSCCP_FilterResult r =  UMSCCP_FILTER_RESULT_UNMODIFIED;
                
            
                if(_sccpLayer.filterDelegate)
                {
                    r = [_sccpLayer.filterDelegate filterInbound:_packet];
                }
                if(r & UMSCCP_FILTER_RESULT_DROP)
                {
                    [_sccpLayer.logFeed debugText:@"Filter returns DROP"];
                    return;
                }
                if(r & UMSCCP_FILTER_RESULT_STATUS)
                {
                    SCCP_ServiceType st = SCCP_UDTS;
                    switch(_packet.outgoingServiceType)
                    {
                        case SCCP_UDT:
                        case SCCP_UDTS:
                            st = SCCP_UDTS;
                            break;
                        case SCCP_XUDT:
                        case SCCP_XUDTS:
                            st = SCCP_XUDTS;
                            break;
                        case SCCP_LUDT:
                        case SCCP_LUDTS:
                            st = SCCP_LUDTS;
                            break;
                        default:
                            switch(_packet.incomingServiceType)
                        {
                            case SCCP_UDT:
                            case SCCP_UDTS:
                                st = SCCP_UDTS;
                                break;
                            case SCCP_XUDT:
                            case SCCP_XUDTS:
                                st = SCCP_XUDTS;
                                break;
                            case SCCP_LUDT:
                            case SCCP_LUDTS:
                                st = SCCP_LUDTS;
                                break;
                        }
                    }
                    switch(st)
                    {
                        case SCCP_UDTS:
                            if(_sccpLayer.routeErrorsBackToSource)
                            {
                                [_sccpLayer sendUDTS:_packet.incomingSccpData
                                                 calling:_packet.incomingCalledPartyAddress
                                                  called:_packet.incomingCallingPartyAddress
                                                   class:_packet.incomingServiceClass
                                             returnCause:_packet.outgoingReturnCause
                                                     opc:_sccpLayer.mtp3.opc /* errors are always sent from this instance */
                                                     dpc:_packet.incomingOpc
                                                 options:@{}
                                                provider:_sccpLayer.mtp3
                                         routedToLinkset:&outgoingLinkset];
                                _packet.outgoingLinkset = outgoingLinkset;
                            }
                            else
                            {
                                [_sccpLayer generateUDTS:_packet.incomingSccpData
                                                 calling:_packet.incomingCalledPartyAddress
                                                  called:_packet.incomingCallingPartyAddress
                                                   class:_packet.incomingServiceClass
                                             returnCause:_packet.outgoingReturnCause
                                                     opc:_sccpLayer.mtp3.opc /* errors are always sent from this instance */
                                                     dpc:_packet.incomingOpc
                                                 options:@{}
                                                provider:_sccpLayer.mtp3];
                            }
                            break;
                        case SCCP_XUDTS:
                            if(_sccpLayer.routeErrorsBackToSource)
                            {
                                [_sccpLayer sendXUDTS:_packet.incomingSccpData
                                              calling:_packet.incomingCalledPartyAddress
                                               called:_packet.incomingCallingPartyAddress
                                                class:_packet.incomingServiceClass
                                             hopCount:0x0F
                                          returnCause:_packet.outgoingReturnCause
                                                  opc:_sccpLayer.mtp3.opc /* errors are always sent from this instance */
                                                  dpc:_packet.incomingOpc
                                          optionsData:_packet.incomingOptionalData
                                              options:@{}
                                             provider:_sccpLayer.mtp3
                                      routedToLinkset:&outgoingLinkset];
                                _packet.outgoingLinkset = outgoingLinkset;
                            }
                            else
                            {
                                [_sccpLayer generateXUDTS:_packet.incomingSccpData
                                                  calling:_packet.incomingCalledPartyAddress
                                                   called:_packet.incomingCallingPartyAddress
                                                    class:_packet.incomingServiceClass
                                              returnCause:_packet.outgoingReturnCause
                                                      opc:_sccpLayer.mtp3.opc /* errors are always sent from this instance */
                                                      dpc:_packet.incomingOpc
                                                  options:@{}
                                                 provider:_sccpLayer.mtp3];
                            }
                            break;
                        case SCCP_LUDTS:
    #if 0       /* sendLUDTS is not implemented yet */
                            if(_sccpLayer.routeErrorsBackToSource)
                            {
                                [_sccpLayer sendLUDTS:_packet.incomingSccpData
                                              calling:_packet.incomingCalledPartyAddress
                                               called:_packet.incomingCallingPartyAddress
                                                class:_packet.incomingServiceClass
                                          returnCause:_packet.outgoingReturnCause
                                                  opc:_sccpLayer.mtp3.opc
                                                  dpc:_packet.incomingOpc
                                              options:@{}
                                             provider:_sccpLayer.mtp3];

                            }
                            else
    #endif
                            {
                                [_sccpLayer generateLUDTS:_packet.incomingSccpData
                                                  calling:_packet.incomingCalledPartyAddress
                                                   called:_packet.incomingCallingPartyAddress
                                                    class:_packet.incomingServiceClass
                                              returnCause:_packet.outgoingReturnCause
                                                      opc:_sccpLayer.mtp3.opc /* errors are always sent from this instance */
                                                      dpc:_packet.incomingOpc
                                                  options:@{}
                                                 provider:_sccpLayer.mtp3];
                            }
                            break;
                        default:
                            break;
                    }
                    return;
                }

                if((m_type != SCCP_UDT) || (_dst.ssn.ssn!=SCCP_SSN_SCCP_MG))
                {
                    if([_sccpLayer routePacket:_packet] == NO)
                    {
                        if(_sccpLayer.unrouteablePacketsTraceDestination)
                        {
                            [_sccpLayer.unrouteablePacketsTraceDestination logPacket:_packet];
                        }
                    }
                }
                switch(m_type)
                {
                    case SCCP_UDT:
                        if(_dst.ssn.ssn==SCCP_SSN_SCCP_MG)
                        {
                            if([self process_udt_sccp_mg])
                            {
                                _statsSection = UMSCCP_StatisticSection_RX;
                                _statsSection2 = UMSCCP_StatisticSection_UDT_RX;
                            }
                            else
                            {
                                _statsSection = UMSCCP_StatisticSection_TRANSIT;
                                _statsSection2 = UMSCCP_StatisticSection_UDT_TRANSIT;
                            }
                        }
                        else
                        {
                            if(_packet.outgoingToLocal)
                            {
                                _statsSection = UMSCCP_StatisticSection_RX;
                                _statsSection2 = UMSCCP_StatisticSection_UDT_RX;
                            }
                            else
                            {
                                _statsSection = UMSCCP_StatisticSection_TRANSIT;
                                _statsSection2 = UMSCCP_StatisticSection_UDT_TRANSIT;
                            }
                        }
                        break;
                    case SCCP_UDTS:
                        if(_packet.outgoingToLocal)
                        {
                            _statsSection = UMSCCP_StatisticSection_RX;
                            _statsSection2 = UMSCCP_StatisticSection_UDTS_RX;
                        }
                        else
                        {
                            _statsSection = UMSCCP_StatisticSection_TRANSIT;
                            _statsSection2 = UMSCCP_StatisticSection_UDTS_TRANSIT;
                        }
                        break;
                    case SCCP_XUDT:
                        if(_packet.outgoingToLocal)
                        {
                            _statsSection = UMSCCP_StatisticSection_RX;
                            _statsSection2 = UMSCCP_StatisticSection_XUDT_RX;
                        }
                        else
                        {
                            _statsSection = UMSCCP_StatisticSection_TRANSIT;
                            _statsSection2 = UMSCCP_StatisticSection_XUDT_TRANSIT;
                        }
                        break;
                    case SCCP_XUDTS:
                        if(_packet.outgoingToLocal)
                        {
                            _statsSection = UMSCCP_StatisticSection_RX;
                            _statsSection2 = UMSCCP_StatisticSection_XUDTS_RX;
                        }
                        else
                        {
                            _statsSection = UMSCCP_StatisticSection_TRANSIT;
                            _statsSection2 = UMSCCP_StatisticSection_XUDTS_TRANSIT;
                        }
                        break;
                }
                
                if(_sccpLayer.statisticDb)
                {
                    NSString *callingPrefix = _packet.incomingCallingPartyAddress.address;
                    NSString *calledPrefix = _packet.incomingCalledPartyAddress.address;

                    if(_packet.incomingCallingPartyAddress.npi.npi == SCCP_NPI_ISDN_MOBILE_E214)
                    {
                        callingPrefix =  [_sccpLayer.statisticDb e214prefixOf:_packet.incomingCallingPartyAddress.address];
                    }
                    else if(_packet.incomingCallingPartyAddress.npi.npi == SCCP_NPI_LAND_MOBILE_E212)
                    {
                        callingPrefix =  [_sccpLayer.statisticDb e212prefixOf:_packet.incomingCallingPartyAddress.address];

                    }
                    else
                    {
                        callingPrefix =  [_sccpLayer.statisticDb e164prefixOf:_packet.incomingCallingPartyAddress.address];
                    }

                    
                    if(_packet.incomingCalledPartyAddress.npi.npi == SCCP_NPI_ISDN_MOBILE_E214)
                    {
                        calledPrefix =  [_sccpLayer.statisticDb e214prefixOf:_packet.incomingCalledPartyAddress.address];
                    }
                    else if(_packet.incomingCalledPartyAddress.npi.npi == SCCP_NPI_LAND_MOBILE_E212)
                    {
                        calledPrefix =  [_sccpLayer.statisticDb e212prefixOf:_packet.incomingCalledPartyAddress.address];

                    }
                    else
                    {
                        calledPrefix =  [_sccpLayer.statisticDb e164prefixOf:_packet.incomingCalledPartyAddress.address];
                    }

                    NSString *gttSelector=_packet.routingSelector;
                    NSString *incomingLinkset = _packet.incomingLinkset;
                    NSString *outgoingLinkset = _packet.outgoingLinkset;
                    if(_packet.incomingFromLocal)
                    {
                        incomingLinkset=@"local";
                    }
                    if(_packet.outgoingToLocal)
                    {
                        outgoingLinkset=@"local";
                    }
                    
                    [_sccpLayer.statisticDb  addByteCount:(int)_packet.outgoingSccpData.length
                                          incomingLinkset:incomingLinkset
                                          outgoingLinkset:outgoingLinkset
                                            callingPrefix:callingPrefix
                                             calledPrefix:calledPrefix
                                              gttSelector:gttSelector
                                            sccpOperation:_packet.incomingServiceType
                                        incomingPointCode:(int)_packet.incomingOpc.integerValue
                                        outgoingPointCode:(int)_packet.outgoingDpc.integerValue
                                              destination:_packet.outgoingDestination];
                }
            }
            else
            {
                /* only decoding */
            }
        }
        @catch(NSException *e)
        {
            if(_mtp3Layer.problematicPacketDumper)
            {
                [_mtp3Layer.problematicPacketDumper logRawPacket:rawMtp3];
            }
            if(_sccpLayer.problematicTraceDestination)
            {
                [_sccpLayer.problematicTraceDestination logPacket:_packet];
            }
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"Error: %@",e]];
            if(decodeOnly)
            {
                _decodedJson[@"decode-error"] = e.description;
            }
        }

        _endOfProcessing = [NSDate date];
        [_sccpLayer addProcessingStatistic:_statsSection
                              waitingDelay:[_startOfProcessing timeIntervalSinceDate:_created]
                           processingDelay:[_endOfProcessing timeIntervalSinceDate:_startOfProcessing]];
        [_sccpLayer addProcessingStatistic:_statsSection2
                             waitingDelay:[_startOfProcessing timeIntervalSinceDate:_created]
                          processingDelay:[_endOfProcessing timeIntervalSinceDate:_startOfProcessing]];
        [_sccpLayer increaseThroughputCounter:_statsSection];
        [_sccpLayer increaseThroughputCounter:_statsSection2];
        
        if(_packet.outgoingToLocal)
        {
            [_sccpLayer.prometheusData increaseMapCounter:UMSCCP_StatisticSection_RX operations:_packet.incomingGsmMapOperations];
        }
        else
        {
            [_sccpLayer.prometheusData increaseMapCounter:UMSCCP_StatisticSection_TRANSIT operations:_packet.incomingGsmMapOperations];
        }
    }
}

- (BOOL)process_udt_sccp_mg /* returns true if processed locally */
{
    int scgm_format = -1;
    int affected_ssn = 0;
    int affected_pc = 0;
    int ss_multiplicity_indicator = 0;
    int sccp_congestion_level = 0;
    
    const uint8_t *dat = _sccp_pdu.bytes;
    NSUInteger len = _sccp_pdu.length;
    NSString *outgoingLinkset = NULL;
    
    /* Management Message */
    if(len<1)
    {
        @throw([NSException exceptionWithName:@"SCCP_MGMT_MESSAGE_TOO_SHORT" reason:NULL userInfo:@{@"backtrace": UMBacktrace(NULL,0)}] );
    }
    scgm_format = dat[0];
    
    switch(scgm_format)
    {
        case 0x01: /* SSA subsystem-allowed*/
        case 0x02: /* SSP subsystem-prohibited */
        case 0x03: /* SST subsystem-status-test */
        case 0x04: /* SOR subsystem-out-of-service-request */
        case 0x05: /* SOG subsystem-out-of-service-grant */
        {
            if(len<5)
            {
                @throw([NSException exceptionWithName:@"SCCP_MGMT_MESSAGE_TOO_SHORT" reason:NULL userInfo:@{@"backtrace": UMBacktrace(NULL,0)}] );
            }
            
            affected_ssn = dat[1];
#pragma unused(affected_pc)
#pragma unused(ss_multiplicity_indicator)
#pragma unused(sccp_congestion_level)
            
            affected_pc = dat[2] | ((dat[3] << 8) & 0x3F);
            ss_multiplicity_indicator = dat[4] & 0x3;
        }
            break;
        case 0x06: /* SSC SCCP/subsystem-congested */
        {
            if(len<6)
            {
                @throw([NSException exceptionWithName:@"SCCP_MGMT_MESSAGE_TOO_SHORT" reason:NULL userInfo:@{@"backtrace": UMBacktrace(NULL,0)}] );
            }
            affected_ssn = dat[1];
            affected_pc = dat[2] | ((dat[3] << 8) & 0x3F);
            ss_multiplicity_indicator = dat[4] & 0x3;
            sccp_congestion_level = dat[5];
        }
            break;
        default:
            /* we dont know what to do with this */
            @throw([NSException exceptionWithName:@"SCCP_MGMT_UNKNOWN_MESSAGE" reason:NULL userInfo:@{@"backtrace": UMBacktrace(NULL,0)}] );
            break;
    }
    
    switch(scgm_format)
    {
        case 0x01: /* SSA subsystem-allowed*/
            break;
        case 0x02: /* SSP subsystem-prohibited */
            break;
        case 0x03: /* SST subsystem-status-test */
            /* we return exactly same packet as SSA */
        {
            SccpSubSystemNumber *ssn = [[SccpSubSystemNumber alloc]initWithInt:affected_ssn];
            id<UMSCCP_UserProtocol> user = [_sccpLayer getUserForSubsystem:ssn];
            unsigned char r[5];
            r[0] = user ? 0x01 : 0x00;
            r[1] = affected_ssn;
            r[2] = dat[2];
            r[3] = dat[3];
            r[4] = dat[4];
            
            NSData *rpdu = [[NSData alloc]initWithBytes:r length:5];
            
            SccpAddress *response_calling_sccp  = [[SccpAddress alloc]init];
            SccpAddress *response_called_sccp   = [[SccpAddress alloc]init];
            
            response_calling_sccp.pc = _dpc;
            [response_calling_sccp setSsnFromInt:0x01];
            [response_calling_sccp setAiFromInt:0x43]; /* route on SSN (0x40), SSn present (0x02), PC present (0x01); */
            
            response_called_sccp.pc = _opc;
            [response_called_sccp setSsnFromInt:0x01]; /* SCCP MGMT */
            [response_called_sccp setAiFromInt:0x43]; /* route on SSN (0x40), SSn present (0x02), PC present (0x01); */

            /*UMMTP3_Error err = */[_sccpLayer sendUDT:rpdu
                                              calling:response_calling_sccp
                                               called:response_called_sccp
                                                class:_m_protocol_class
                                             handling:_m_handling
                                                  opc:_opc
                                                  dpc:_dpc
                                              options:@{}
                                             provider:_sccpLayer.mtp3
                                       routedToLinkset:&outgoingLinkset];
            _packet.outgoingLinkset = outgoingLinkset;
            break;
        }
        case 0x04: /* SOR subsystem-out-of-service-request */
        case 0x05: /* SOG subsystem-out-of-service-grant */
        case 0x06: /* SSC SCCP/subsystem-congested */
        default:
            break;
    }
    return YES;
}

#if 0
- (BOOL)processUDT /* returns true if processed locally */
{
    return [sccpLayer routeUDT:sccp_pdu
                       calling:src
                        called:dst
                         class:m_protocol_class
                      handling:m_handling
                           opc:opc
                           dpc:dpc
                       options:options
                      provider:sccpLayer.mtp3
                     fromLocal:NO];
}

- (BOOL)processUDTS
{
    NSDate *ts = [NSDate new];
    options[@"sccp-timestamp-udt"] = ts;

    return [sccpLayer routeUDTS:sccp_pdu
                        calling:src
                         called:dst
                         reason:m_return_cause
                            opc:opc
                            dpc:dpc
                        options:options
                       provider:sccpLayer.mtp3
                      fromLocal:NO];
}

- (BOOL)processXUDT /* returns true if processed locally */
{
    BOOL returnValue = NO;
    NSDate *ts = [NSDate new];
    options[@"sccp-timestamp-udt"] = ts;
    returnValue = [sccpLayer routeXUDT:sccp_pdu
                               calling:src
                                called:dst
                                 class:m_protocol_class
                                handling:m_handling
                              hopCount:m_hopcounter
                                   opc:opc
                                   dpc:dpc
                           optionsData:sccp_optional
                               options:options
                              provider:sccpLayer.mtp3
                             fromLocal:NO];

    id<UMSCCP_UserProtocol> upperLayer = [sccpLayer getUserForSubsystem:dst.ssn number:dst];
    options[@"sccp-timestamp-udt"] = ts;

    if((optional_dict == NULL) ||
        (      (optional_dict[@"segmenting-reassembling"]==NULL)
            && (optional_dict[@"sequencing-segmenting"]==NULL)
            && (optional_dict[@"segmentation"]==NULL)))
    {
        [upperLayer sccpNUnitdata:sccp_pdu
                     callingLayer:sccpLayer
                          calling:src
                           called:dst
                 qualityOfService:0
                            class:m_protocol_class
                         handling:m_handling
                          options:options];
    }
    else
    {
        UMSCCP_Segment *s = [[UMSCCP_Segment alloc]initWithHeaderData:sccp_optional];
        s.data = sccp_pdu;
        NSData *reassembled = NULL;
        NSString *key = MAKE_SEGMENT_KEY(src,dst,s.reference);
        @synchronized(sccpLayer.pendingSegments)
        {
            UMSCCP_ReceivedSegments *rs = sccpLayer.pendingSegments[key];
            if(rs == NULL)
            {
                rs = [[UMSCCP_ReceivedSegments alloc]init];
                rs.src = src;
                rs.dst = dst;
                rs.ref = s.reference;
            }
            [rs addSegment:s];
            reassembled = [rs reassembledData];
            if(reassembled)
            {
                [sccpLayer.pendingSegments removeObjectForKey:key];
            }
            else
            {
                sccpLayer.pendingSegments[key] = rs;
            }
        }
        if(reassembled)
        {
            [upperLayer sccpNUnitdata:reassembled
                         callingLayer:sccpLayer
                              calling:src
                               called:dst
                     qualityOfService:0
                                class:m_protocol_class
                             handling:m_handling
                              options:options];
        }
        
    }
    return returnValue;
}

- (BOOL)processXUDTS
{
    NSDate *ts = [NSDate new];
    options[@"sccp-timestamp-udt"] = ts;

    return [sccpLayer routeXUDTS:sccp_pdu
                         calling:src
                          called:dst
                          reason:m_return_cause
                        hopCount:m_hopcounter
                             opc:opc
                             dpc:dpc
                     optionsData:sccp_optional
                         options:options
                        provider:sccpLayer.mtp3
                       fromLocal:NO];
}
#endif

@end
