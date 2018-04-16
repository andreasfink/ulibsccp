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

@implementation UMSCCP_mtpTransfer


- (UMSCCP_mtpTransfer *)initForSccp:(UMLayerSCCP *)layer
                               mtp3:(UMLayerMTP3 *)mtp3
                                opc:(UMMTP3PointCode *)xopc
                                dpc:(UMMTP3PointCode *)xdpc
                                 si:(int)xsi
                                 ni:(int)xni
                               data:(NSData *)xdata
                            options:(NSDictionary *)xoptions;
{
    self = [super initWithName:@"UMSCCP_mtpTransfer" receiver:layer sender:mtp3 requiresSynchronisation:NO];
    if(self)
    {
        opc = xopc;
        dpc = xdpc;
        si = xsi;
        ni = xni;
        data = xdata;
        if(xoptions)
        {
            options = [xoptions mutableCopy];
        }
        else
        {
            options = [[NSMutableDictionary alloc]init];
        }
        sccpLayer = layer;
        mtp3Layer = mtp3;
    }
    return self;
}

- (void)main
{
    /* we build a pseudo MTP3 raw packet for debugging logging */
    UMMTP3Label *label = [[UMMTP3Label alloc]init];
    label.opc = opc;
    label.dpc = dpc;
    NSMutableData *rawMtp3 = [[NSMutableData alloc]init];
    int sio = ((ni & 0x03) << 6) | (si & 0x0F);
    [rawMtp3 appendByte:sio];
    [label appendToMutableData:rawMtp3];
    [rawMtp3 appendData:data];

    options[@"mtp3-pdu"] = rawMtp3;

    options[@"sccp-pdu"] = [data hexString];
    BOOL decodeOnly = [options[@"decode-only"] boolValue];
    if(decodeOnly)
    {
        _decodedJson = [[UMSynchronizedSortedDictionary alloc]init];
    }
    @try
    {
        NSUInteger len = data.length;
        if(len < 6)
        {
            @throw([NSException exceptionWithName:@"SCCP_TOO_SMALL_PACKET_RECEIVED" reason:NULL userInfo:NULL] );
        }
        const uint8_t *d = data.bytes;
        int i = 0;
        int m_type = d[i++];
        
        int m_handling;
        int param_called_party_address;
        int param_calling_party_address;
        int param_data;
        int param_optional;
        int param_hop_counter = 0;
        NSString *type;

        switch(m_type)
        {
            case SCCP_UDT:
                type = @"UDT";
                _decodedJson[@"sccp-pdu-type"]=type;
                m_protocol_class = d[i] & 0x0F;
                _decodedJson[@"sccp-protocol-class"]=@(m_protocol_class);
                m_handling = (d[i++]>>4) & 0x0F;
                _decodedJson[@"sccp-protocol-handling"]=@(m_handling);
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
                m_return_cause = d[i++] & 0x0F;
                _decodedJson[@"sccp-return-cause"]=@(m_return_cause);
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
                m_protocol_class = d[i] & 0x0F;
                _decodedJson[@"sccp-protocol-class"]=@(m_protocol_class);
                m_handling = (d[i++]>>4) & 0x0F;
                _decodedJson[@"sccp-protocol-handling"]=@(m_handling);
                param_hop_counter=d[i];
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
                m_return_cause = d[i++] & 0x0F;
                _decodedJson[@"sccp-protocol-return-cause"]=@(m_return_cause);
                m_hopcounter = d[i++] & 0x0F;
                _decodedJson[@"sccp-hop-counter"]=@(m_hopcounter);
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

        if(param_called_party_address>0)
        {
            i = (int)d[param_called_party_address];
            dstData = [NSData dataWithBytes:&d[param_called_party_address+1] length:i];
            dst = [[SccpAddress alloc]initWithItuData:dstData];
            _decodedJson[@"sccp-called-party-address"]=[dst dictionaryValue];
            _decodedCalled = dst;
        }
        if(param_calling_party_address>0)
        {
            i = (int)d[param_calling_party_address];
            srcData = [NSData dataWithBytes:&d[param_calling_party_address+1] length:i];
            src = [[SccpAddress alloc]initWithItuData:srcData];
            _decodedJson[@"sccp-calling-party-address"]=[src dictionaryValue];
            _decodedCalling = src;
        }
        if(param_data > 0)
        {
            i = (int)d[param_data];
            sccp_pdu = [NSData dataWithBytes:&d[param_data+1] length:i];
            _decodedJson[@"sccp-payload-bytes"]=[sccp_pdu hexString];
            if(decodeOnly)
            {
                id<UMSCCP_UserProtocol> user = [sccpLayer getUserForSubsystem:dst.ssn number:dst];
                id decodedUserPdu = [user decodePdu:sccp_pdu];
                _decodedPdu = sccp_pdu;
                _decodedJson[@"sccp-payload"]=decodedUserPdu;
            }
        }
        if(param_optional > 0)
        {
            sccp_optional = [NSData dataWithBytes:&d[param_optional] length:len-param_optional];
            _decodedJson[@"sccp-optional-raw"] = sccp_optional.hexString;
            const uint8_t *bytes = sccp_optional.bytes;
            NSUInteger m = sccp_optional.length;
            NSUInteger j=0;
            while(j<m)
            {
                int paramType = bytes[j++];
                if(j<m)
                {
                    int len = bytes[j++];
                    if((j+len)<m)
                    {
                        optional_dict = [[NSMutableDictionary alloc]init];
                        NSData *param = [NSData dataWithBytes:&bytes[j] length:len];
                        j = j+len;
                        if(paramType==0x00)
                        {
                            break; /*end of optional parameters */
                        }
                        switch(paramType)
                        {
                            case 0x01:
                                optional_dict[@"destination-local-reference"] = param;
                                break;
                            case 0x02:
                                optional_dict[@"source-local-reference"] = param;
                                break;
                            case 0x03:
                                optional_dict[@"called-party-address"] = param;
                                break;
                            case 0x04:
                                optional_dict[@"calling-party-address"] = param;
                                break;
                            case 0x05:
                                optional_dict[@"protocol-class"] = param;
                                break;
                            case 0x06:
                                optional_dict[@"segmenting-reassembling"] = param;
                                break;
                            case 0x07:
                                optional_dict[@"receive-sequence-number"] = param;
                                break;
                            case 0x08:
                                optional_dict[@"sequencing-segmenting"] = param;
                                break;
                            case 0x09:
                                optional_dict[@"credit"] = param;
                                break;
                            case 0x0a:
                                optional_dict[@"release-cause"] = param;
                                break;
                            case 0x0b:
                                optional_dict[@"return-cause"] = param;
                                break;
                            case 0x0c:
                                optional_dict[@"reset-cause"] = param;
                                break;
                            case 0x0d:
                                optional_dict[@"error-cause"] = param;
                                break;
                            case 0x0e:
                                optional_dict[@"refusal-cause"] = param;
                                break;
                            case 0x0f:
                                optional_dict[@"data"] = param;
                                break;
                            case 0x10:
                                optional_dict[@"segmentation"] = param;
                                break;
                            case 0x11:
                                optional_dict[@"hop-counter"] = param;
                                break;
                            case 0x12:
                                optional_dict[@"importance"] = param;
                                break;
                            case 0x13:
                                optional_dict[@"long-data"] = param;
                                break;
                        }
                    }
                }
            }
            _decodedJson[@"sccp-optional"] = optional_dict;
        }
        
        if(src == NULL)
        {
            @throw([NSException exceptionWithName:@"SCCP_MISSING_CALLING_PARTY_ADDRESS" reason:NULL userInfo:@{@"mtp3": [rawMtp3 hexString] }] );
        }
        if(dst==NULL)
        {
            @throw([NSException exceptionWithName:@"SCCP_MISSING_CALLED_PARTY_ADDRESS" reason:NULL userInfo:@{@"mtp3": [rawMtp3 hexString] }] );
        }
        NSMutableDictionary *o = [[NSMutableDictionary alloc]init];
        o[@"type"]=type;
        if(opc)
        {
            o[@"opc"]=opc.stringValue;
        }
        if(dpc)
        {
            o[@"dpc"]=dpc.stringValue;
        }
        if(mtp3Layer)
        {
            o[@"mtp3"]=mtp3Layer.layerName;
        }
        else
        {
            o[@"mtp3"]=@"(not-set)";
        }
        if(optional_dict)
        {
            o[@"sccp-optional"] = optional_dict;
            options[@"sccp-optional"] = optional_dict;
        }
        [sccpLayer traceReceivedPdu:data options:o];
        if(!decodeOnly)
        {
            switch(m_type)
            {
                case SCCP_UDT:
                    options[@"sccp-udt"] = @(YES);
                    if(dst.ssn.ssn==SCCP_SSN_SCCP_MG)
                    {
                        [self process_udt_sccp_mg];
                    }
                    else
                    {
                        [self processUDT];
                    }
                    break;
                case SCCP_UDTS:
                    options[@"sccp-udts"] = @(YES);
                    [self processUDTS];
                    break;
                case SCCP_XUDT:
                    options[@"sccp-xudt"] = @(YES);
                    [self processXUDT];
                    break;
                case SCCP_XUDTS:
                    options[@"sccp-xudts"] = @(YES);
                    [self processXUDTS];
                    break;
            }
        }
        else
        {
            
        }
    }
    @catch(NSException *e)
    {
        if(mtp3Layer.problematicPacketDumper)
        {
            [mtp3Layer.problematicPacketDumper logRawPacket:rawMtp3];
        }

        [logFeed majorErrorText:[NSString stringWithFormat:@"Error: %@",e]];
        if(decodeOnly)
        {
            _decodedJson[@"decode-error"] = e.description;
        }
    }
}

- (void)routeOnGlobalTitle
{
    /* route on global number */
    switch(m_type)
    {
        case SCCP_UDT:
            options[@"sccp-udt"] = @(YES);
            if(dst.ssn.ssn==SCCP_SSN_SCCP_MG)
            {
                [self process_udt_sccp_mg];
            }
            else
            {
                [self processUDT];
            }
            break;
        case SCCP_UDTS:
            options[@"sccp-udts"] = @(YES);
            [self processUDTS];
            break;
        case SCCP_XUDT:
            options[@"sccp-xudt"] = @(YES);
            [self processXUDT];
            break;
        case SCCP_XUDTS:
            options[@"sccp-xudts"] = @(YES);
            [self processXUDTS];
            break;
    }
}

- (void)routeOnSubsystem
{
    /* route on subsystem number */
    switch(m_type)
    {
        case SCCP_UDT:
            options[@"sccp-udt"] = @(YES);
            if(dst.ssn.ssn==SCCP_SSN_SCCP_MG)
            {
                [self process_udt_sccp_mg];
            }
            else
            {
                [self processUDT];
            }
            break;
        case SCCP_UDTS:
            options[@"sccp-udts"] = @(YES);
            [self processUDTS];
            break;
        case SCCP_XUDT:
            options[@"sccp-xudt"] = @(YES);
            [self processXUDT];
            break;
        case SCCP_XUDTS:
            options[@"sccp-xudts"] = @(YES);
            [self processXUDTS];
            break;
    }
}

- (void)process_udt_sccp_mg
{
    int scgm_format = -1;
    int affected_ssn = 0;
    int affected_pc = 0;
    int ss_multiplicity_indicator = 0;
    int sccp_congestion_level = 0;
    
    const uint8_t *dat = sccp_pdu.bytes;
    NSUInteger len = sccp_pdu.length;
    
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
            unsigned char r[5];
            r[0] = 0x01; /* FIXME: should we maybe check here if the subsystem is really alive ? */
            r[1] = affected_ssn;
            r[2] = dat[2];
            r[3] = dat[3];
            r[4] = dat[4];
            
            NSData *rpdu = [[NSData alloc]initWithBytes:r length:5];
            
            SccpAddress *response_calling_sccp = [[SccpAddress alloc]init];
            SccpAddress *response_called_sccp = [[SccpAddress alloc]init];
            
            response_calling_sccp.pc = dpc;
            [response_calling_sccp setSsnFromInt:0x01];
            [response_calling_sccp setAiFromInt:0x43]; /* route on SSN (0x40), SSn present (0x02), PC present (0x01); */
            
            response_called_sccp.pc = opc;
            [response_called_sccp setSsnFromInt:0x01]; /* SCCP MGMT */
            [response_called_sccp setAiFromInt:0x43]; /* route on SSN (0x40), SSn present (0x02), PC present (0x01); */

            /*UMMTP3_Error err = */[sccpLayer sendUDT:rpdu
                                              calling:response_calling_sccp
                                               called:response_called_sccp
                                                class:0
                                        returnOnError:NO
                                                  opc:opc
                                                  dpc:dpc
                                              options:@{}
                                             provider:sccpLayer.mtp3];
            break;
        }
        case 0x04: /* SOR subsystem-out-of-service-request */
        case 0x05: /* SOG subsystem-out-of-service-grant */
        case 0x06: /* SSC SCCP/subsystem-congested */
        default:
            break;
    }
}

- (void)processUDT
{
    if(dst.ai.routingIndicatorBit == ROUTE_BY_GLOBAL_TITLE)
    {
        SccpGttRegistry *registry = sccpLayer.gttSelectorRegistry;
        SccpGttSelector *selector = [registry selectorForInstance:sccpLayer.layerName
                                                               tt:dst.tt.tt
                                                              gti:dst.ai.globalTitleIndicator
                                                               np:dst.npi.npi
                                                              nai:dst.nai.nai];
        if(selector == NULL)
        {
            [sccpLayer sendUDTS:sccp_pdu
                        calling:src
                         called:dst
                         reason:SCCP_ReturnCause_NoTranslationForThisSpecificAddress
                            opc:sccpLayer.mtp3.opc
                            dpc:opc
                        options:@{}
                       provider:sccpLayer.mtp3];

        }
        else
        {
            SccpDestination *destination = [selector chooseNextHopWithL3RoutingTable:sccpLayer.mtp3RoutingTable
                                                                              digits:dst.address];
            if(destination==NULL)
            {
                NSLog(@"SCCP: No route to destination for tt=%d gti=%d, np=%d, nai=%d address=%@",dst.tt.tt,dst.ai.globalTitleIndicator,dst.npi.npi,dst.nai.nai,dst.address);
                [sccpLayer sendUDTS:sccp_pdu
                            calling:src
                             called:dst
                             reason:SCCP_ReturnCause_NoTranslationForThisSpecificAddress
                                opc:sccpLayer.mtp3.opc
                                dpc:opc
                            options:@{}
                           provider:sccpLayer.mtp3];
            }
            else
            {
                if(destination.ssn)
                {
                    /* routed by subsystem */
                    id<UMSCCP_UserProtocol> upperLayer = [sccpLayer getUserForSubsystem:dst.ssn number:dst];
                    if(upperLayer == NULL)
                    {
                        [logFeed majorErrorText:[NSString stringWithFormat:@"no upper layer found for %@",dst.debugDescription]];
                        [sccpLayer sendUDTS:sccp_pdu
                                    calling:src
                                     called:dst
                                     reason:SCCP_ReturnCause_SubsystemFailure
                                        opc:sccpLayer.mtp3.opc
                                        dpc:opc
                                    options:@{}
                                   provider:sccpLayer.mtp3];
                    }
                    else
                    {
                        [upperLayer sccpNUnitdata:sccp_pdu
                                     callingLayer:sccpLayer
                                          calling:src
                                           called:dst
                                 qualityOfService:0
                                          options:options];
                    }
                }
                else if(destination.dpc)
                {
                    /* Forwarding */
                    UMMTP3_Error e = [sccpLayer sendUDT:sccp_pdu
                                                calling:src
                                                 called:dst
                                                  class:m_protocol_class   /* MGMT is class 0 */
                                          returnOnError:m_return_on_error
                                                    opc:sccpLayer.mtp3.opc
                                                    dpc:destination.dpc
                                                options:@{}
                                               provider:sccpLayer.mtp3];
                    switch(e)
                    {
                        case UMMTP3_error_no_route_to_destination:
                            [sccpLayer sendUDTS:sccp_pdu
                                        calling:src
                                         called:dst
                                         reason:SCCP_ReturnCause_MTPFailure
                                            opc:sccpLayer.mtp3.opc
                                            dpc:opc
                                        options:@{}
                                       provider:sccpLayer.mtp3];
                            break;
                        case UMMTP3_error_pdu_too_big:
                            [sccpLayer sendUDTS:sccp_pdu
                                        calling:src
                                         called:dst
                                         reason:SCCP_ReturnCause_ErrorInMessageTransport
                                            opc:sccpLayer.mtp3.opc
                                            dpc:opc
                                        options:@{}
                                       provider:sccpLayer.mtp3];

                            break;
                        case UMMTP3_error_invalid_variant:
                            [sccpLayer sendUDTS:sccp_pdu
                                        calling:src
                                         called:dst
                                         reason:SCCP_ReturnCause_ErrorInLocalProcessing
                                            opc:sccpLayer.mtp3.opc
                                            dpc:opc
                                        options:@{}
                                       provider:sccpLayer.mtp3];
                            break;
                        default:
                            break;
                    }
                }
                else if(destination.m3uaAs)
                {
                    /* not yet implemented */
                    [sccpLayer sendUDTS:sccp_pdu
                                calling:src
                                 called:dst
                                 reason:SCCP_ReturnCause_ErrorInLocalProcessing
                                    opc:sccpLayer.mtp3.opc
                                    dpc:opc
                                options:@{}
                               provider:sccpLayer.mtp3];
                }
            }
        }
    }
    else /* ROUTE_BY_SUBSYSTEM */
    {
        /* routed by subsystem */
        id<UMSCCP_UserProtocol> upperLayer = [sccpLayer getUserForSubsystem:dst.ssn number:dst];
        if(upperLayer == NULL)
        {
            [logFeed majorErrorText:[NSString stringWithFormat:@"no upper layer found for %@",dst.debugDescription]];
            [sccpLayer sendUDTS:sccp_pdu
                        calling:src
                         called:dst
                         reason:SCCP_ReturnCause_ErrorInLocalProcessing
                            opc:sccpLayer.mtp3.opc
                            dpc:opc
                        options:@{}
                       provider:sccpLayer.mtp3];

        }
        [upperLayer sccpNUnitdata:sccp_pdu
                     callingLayer:sccpLayer
                          calling:src
                           called:dst
                 qualityOfService:0
                          options:options];
    }
}

- (void)processUDTS
{
    id<UMSCCP_UserProtocol> upperLayer = [sccpLayer getUserForSubsystem:dst.ssn number:dst];
    
    NSDate *ts = [NSDate new];
    options[@"sccp-timestamp-udt"] = ts;

    [upperLayer sccpNNotice:sccp_pdu
               callingLayer:sccpLayer
                    calling:src
                     called:dst
                     reason:m_return_cause
                    options:options];
}

- (void)processXUDT
{
    id<UMSCCP_UserProtocol> upperLayer = [sccpLayer getUserForSubsystem:dst.ssn number:dst];
    NSDate *ts = [NSDate new];
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
                          options:options];
    }
    else
    {
        UMSCCP_Segment *s = [[UMSCCP_Segment alloc]initWithData:sccp_optional];
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
                              options:options];
        }
        
    }
}

- (void)processXUDTS
{
    id<UMSCCP_UserProtocol> upperLayer = [sccpLayer getUserForSubsystem:dst.ssn number:dst];
    
    NSDate *ts = [NSDate new];
    options[@"sccp-timestamp-udt"] = ts;
    
    [upperLayer sccpNNotice:sccp_pdu
               callingLayer:sccpLayer
                    calling:src
                     called:dst
                     reason:m_return_cause
                    options:options];
}
@end
