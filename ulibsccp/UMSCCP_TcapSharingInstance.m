//
//  UMSCCP_TcapSharingInstance.m
//  ulibsccp
//
//  Created by Andreas Fink on 11.07.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_TcapSharingInstance.h"
#import "UMSCCP_Packet.h"
#import "UMLayerSCCP.h"
#import "UMSCCP_TcapSharingSession.h"

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


@implementation UMSCCP_TcapSharingInstance


- (UMSCCP_TcapSharingInstance *)initWithConfig:(NSDictionary *)config
{
    NSString *name = config[@"name"];
    
    self = [super initWithName:name];
    if(self)
    {
        _timeout = 90;
        NSNumber *timeoutNumber  = config[@"timeout"];
        if(timeoutNumber)
        {
            _timeout = [timeoutNumber doubleValue];
        }
        if((_timeout < 10) || (_timeout > 180))
        {
            _timeout = 90;
        }
        _sccpName = config[@"sccp"];
        _outsideBackRoutes = [[UMSynchronizedDictionary alloc]init];
    }
    return self;
}

- (UMSCCP_TcapSharing_result)preroutingPacketInside:(UMSCCP_Packet *)packet
{
    packet.candidateForTcapSharing = YES;
    return UMSCCP_TcapSharing_routeNormal;
}

- (UMSCCP_TcapSharing_result)postroutingPacketInside:(UMSCCP_Packet *)packet
{
    if(packet.candidateForTcapSharing)
    {
        if(packet.incomingTcapCommand == TCAP_TAG_ITU_UNIDIRECTIONAL)
        {
            return UMSCCP_TcapSharing_routeNormal;
        }
        else if(packet.incomingTcapCommand == TCAP_TAG_ITU_BEGIN)
        {
            NSString *key = [NSString stringWithFormat:@"%@:%@",packet.outgoingCallingPartyAddress.stringValueE164, packet.incoming_tcap_otid];

            UMSCCP_TcapSharingSession *session = [[UMSCCP_TcapSharingSession alloc]initWithTimeout:_timeout];
            session.insideLocalTcapTransactionId = packet.incoming_tcap_otid;
            session.callingAddress  = [packet.outgoingCallingPartyAddress copy];
            session.calledAddress   = [packet.outgoingCalledPartyAddress copy];
            session.insideLinkset   = packet.incomingLinksetName;
            session.insideLocalUser = packet.incomingLocalUser;
            session.insidePointcode = packet.incomingOpc;
            session.insideRemoteTcapTransactionId = NULL;
            _outsideBackRoutes[key] = session;
        }
        else if(packet.incomingTcapCommand == TCAP_TAG_ITU_CONTINUE)
        {
    
            NSString *key = [NSString stringWithFormat:@"%@:%@",packet.outgoingCallingPartyAddress.stringValueE164, packet.incoming_tcap_otid];
            UMSCCP_TcapSharingSession *session = _outsideBackRoutes[key];
            if(session)
            {
                [session touch];
                packet.outgoing_tcap_otid = session.outsideLocalTcapTransactionId;
                packet.outgoing_tcap_dtid = session.outsideRemoteTcapTransactionId;
            }
        }
        else if(   (packet.incomingTcapCommand == TCAP_TAG_ITU_END)
                || (packet.incomingTcapCommand == TCAP_TAG_ITU_ABORT))
        {
            NSString *key = [NSString stringWithFormat:@"%@:%@",packet.outgoingCallingPartyAddress.stringValueE164, packet.incoming_tcap_otid];
            UMSCCP_TcapSharingSession *session = _outsideBackRoutes[key];
            if(session)
            {
                [_outsideBackRoutes removeObjectForKey:key];
                session = NULL; /* destroys session */
            }
        }
    }
    return UMSCCP_TcapSharing_routeNormal;
}

- (UMSCCP_TcapSharing_result)preroutingPacketOutside:(UMSCCP_Packet *)packet
{
    if((packet.incomingTcapCommand == TCAP_TAG_ITU_CONTINUE) ||
       (packet.incomingTcapCommand == TCAP_TAG_ITU_END) ||
       (packet.incomingTcapCommand == TCAP_TAG_ITU_ABORT))
    {
        NSString *key = [NSString stringWithFormat:@"%@:%@",packet.incomingCalledPartyAddress.stringValueE164, packet.incoming_tcap_dtid];
        UMSCCP_TcapSharingSession *session = _outsideBackRoutes[key];
        if(session != NULL)
        {
            if(packet.incomingTcapCommand == TCAP_TAG_ITU_CONTINUE)
            {
                [session touch];
            }
            else
            {
                [_outsideBackRoutes removeObjectForKey:key];
            }
            packet.forcedDpc        = session.insidePointcode;
            packet.forcedLinkset    = session.insideLinkset;
            packet.forcedLocalUser  = session.insideLocalUser;
            packet.forcedDpc        = session.insidePointcode;
            return UMSCCP_TcapSharing_skipRouting;
        }
    }
    return UMSCCP_TcapSharing_routeNormal;
}

- (UMSCCP_TcapSharing_result)postroutingPacketOutside:(UMSCCP_Packet *)packet
{
    return UMSCCP_TcapSharing_routeNormal;
}

- (UMLayerSCCP *)sccpInstance
{
    if(_sccpInstance)
    {
        return _sccpInstance;
    }
    if((_sccpName) && (_appDelegate))
    {
        UMLayerSCCP *sccp = [_appDelegate getSCCP:_sccpName];
        _sccpInstance = sccp;
        return _sccpInstance;
    }
    return NULL;
}

- (void)setSccpInstance:(UMLayerSCCP *)sccpInstance
{
    _sccpInstance = sccpInstance;
}
@end
