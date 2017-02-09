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

-(UMSynchronizedSortedDictionary *)decodedJson
{
    return decodedJson;
}

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
        options = xoptions;
        sccpLayer = layer;
        mtp3Layer = mtp3;
    }
    return self;
}

- (void)main
{
    if(options)
    {
        NSMutableDictionary *o = [options mutableCopy];
        o[@"sccp-pdu"] = [data hexString];
        options = o;
    }
    else
    {
        options = @{@"sccp-pdu":[data hexString]};
    }
    BOOL decodeOnly = [options[@"decode-only"] boolValue];
    if(decodeOnly)
    {
        decodedJson = [[UMSynchronizedSortedDictionary alloc]init];
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
        int param_segment;
        
        switch(m_type)
        {
            case SCCP_UDT:
                decodedJson[@"sccp-pdu-type"]=@"UDT";
                m_protocol_class = d[i] & 0x0F;
                decodedJson[@"sccp-protocol-class"]=@(m_protocol_class);
                m_handling = (d[i++]>>4) & 0x0F;
                decodedJson[@"sccp-protocol-handling"]=@(m_handling);
                param_called_party_address = d[i] + i;
                i++;
                param_calling_party_address = d[i] + i;
                i++;
                param_data = d[i] + i;
                i++;
                param_segment = -1;
                break;
                
            case SCCP_UDTS:
                decodedJson[@"sccp-pdu-type"]=@"UDTS";
                m_return_cause = d[i++] & 0x0F;
                decodedJson[@"sccp-return-cause"]=@(m_return_cause);
                param_called_party_address = d[i] + i;
                i++;
                param_calling_party_address = d[i] + i;
                i++;
                param_data      = d[i] + i;
                i++;
                param_segment   = -1;
                break;
                
            case SCCP_XUDT:
                decodedJson[@"sccp-pdu-type"]=@"XUDT";
                m_protocol_class = d[i] & 0x0F;
                decodedJson[@"sccp-protocol-class"]=@(m_protocol_class);
                m_handling = (d[i++]>>4) & 0x0F;
                decodedJson[@"sccp-protocol-handling"]=@(m_handling);
                param_called_party_address = d[i] + i;
                i++;
                param_calling_party_address = d[i] + i;
                i++;
                param_data = d[i] + i;
                i++;
                param_segment = -1;
                break;
                
            case SCCP_XUDTS:
                decodedJson[@"sccp-pdu-type"]=@"XUDTS";
                m_return_cause = d[i++] & 0x0F;
                decodedJson[@"sccp-protocol-return-cause"]=@(m_return_cause);
                m_hopcounter = d[i++] & 0x0F;
                decodedJson[@"sccp-hop-counter"]=@(m_hopcounter);
                param_called_party_address = d[i] + i;
                i++;
                param_calling_party_address = d[i] + i;
                i++;
                param_data      = d[i] + i;
                i++;
                param_segment   = d[i] + i;
                i++;
                break;
                
            default:
                @throw([NSException exceptionWithName:@"SCCP_UNKNOWN_PACKET_TYPE" reason:NULL userInfo:@{@"backtrace": UMBacktrace(NULL,0)}] );
        }
        if(param_called_party_address > len)
        {
            @throw([NSException exceptionWithName:@"SCCP_PTR1_POINTS_BEYOND_END" reason:NULL userInfo:@{@"backtrace": UMBacktrace(NULL,0)}] );
            return;
        }
        
        if(param_calling_party_address > len)
        {
            @throw([NSException exceptionWithName:@"SCCP_PTR2_POINTS_BEYOND_END" reason:NULL userInfo:@{@"backtrace": UMBacktrace(NULL,0)}] );
            return;
        }
        if(param_data > len)
        {
            @throw([NSException exceptionWithName:@"SCCP_PTR3_POINTS_BEYOND_END" reason:NULL userInfo:@{@"backtrace": UMBacktrace(NULL,0)}] );
            return;
        }
        if((param_segment > len) && (param_segment > 0))
        {
            @throw([NSException exceptionWithName:@"SCCP_PTR4_POINTS_BEYOND_END" reason:NULL userInfo:@{@"backtrace": UMBacktrace(NULL,0)}] );
            return;
        }
        
        NSData *dstData = NULL;
        NSData *srcData = NULL;

        if(param_called_party_address>0)
        {
            i = (int)d[param_called_party_address];
            dstData = [NSData dataWithBytes:&d[param_called_party_address+1] length:i];
            dst = [[SccpAddress alloc]initWithItuData:dstData];
            decodedJson[@"sccp-called-party-address"]=[dst dictionaryValue];
        }
        if(param_calling_party_address>0)
        {
            i = (int)d[param_calling_party_address];
            srcData = [NSData dataWithBytes:&d[param_calling_party_address+1] length:i];
            src = [[SccpAddress alloc]initWithItuData:srcData];
            decodedJson[@"sccp-calling-party-address"]=[src dictionaryValue];
        }
        if(param_data > 0)
        {
            i = (int)d[param_data];
            sccp_pdu = [NSData dataWithBytes:&d[param_data+1] length:i];
            decodedJson[@"sccp-payload-bytes"]=[sccp_pdu hexString];
            if(decodeOnly)
            {
                id<UMSCCP_UserProtocol> user = [sccpLayer getUserForSubsystem:dst.ssn number:dst];
                id decodedUserPdu = [user decodePdu:sccp_pdu];
                decodedJson[@"sccp-payload"]=decodedUserPdu;
            }
        }
        if(param_segment > 0)
        {
            i = (int)d[param_segment];
            segment = [NSData dataWithBytes:&d[param_segment+1] length:i];
            decodedJson[@"sccp-segment"] = segment.hexString;
        }
        
        if(src == NULL)
        {
            @throw([NSException exceptionWithName:@"SCCP_MISSING_CALLING_PARTY_ADDRESS" reason:NULL userInfo:@{@"backtrace": UMBacktrace(NULL,0)}] );
        }
        if(dst==NULL)
        {
            @throw([NSException exceptionWithName:@"SCCP_MISSING_CALLED_PARTY_ADDRESS" reason:NULL userInfo:@{@"backtrace": UMBacktrace(NULL,0)}] );
        }
        
        if(!decodeOnly)
        {
            switch(m_type)
            {
                case SCCP_UDT:
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
                    [self processUDTS];
                    break;
                case SCCP_XUDT:
                    [self processXUDT];
                    break;
                case SCCP_XUDTS:
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
        NSLog(@"Error: %@",e);
        if(decodeOnly)
        {
            decodedJson[@"decode-error"] = e.description;
        }
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
            r[0] = 0x01;
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
            
            SccpL3Provider *provider = [[SccpL3Provider alloc]init];
            provider.opc = dpc;
            provider.dpc = opc;
            provider.mtp3Layer = mtp3Layer;
            
            /*UMMTP3_Error err = */[sccpLayer sendUDT:rpdu
                                              calling:response_calling_sccp
                                               called:response_called_sccp
                                                class:0
                                        returnOnError:NO
                                                  opc:opc
                                                  dpc:dpc
                                              options:@{}
                                             provider:provider];
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
    id<UMSCCP_UserProtocol> upperLayer = [sccpLayer getUserForSubsystem:dst.ssn number:dst];
    if(upperLayer == NULL)
    {
        NSLog(@"no upper layer found for %@",dst.debugDescription);
    }
    [upperLayer sccpNUnitdata:sccp_pdu
                 callingLayer:sccpLayer
                      calling:src
                       called:dst
             qualityOfService:0
                      options:options];
}

- (void)processUDTS
{
    id<UMSCCP_UserProtocol> upperLayer = [sccpLayer getUserForSubsystem:dst.ssn number:dst];
    
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
    
    if(segment == NULL)
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
        UMSCCP_Segment *s = [[UMSCCP_Segment alloc]initWithData:segment];
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
    
}




@end
