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


@implementation UMSCCP_TcapSharingInstance


- (UMSCCP_TcapSharingInstance *)initWithConfig:(NSDictionary *)config
{
    NSString *name = config[@"name"];
    
    self = [super initWithName:name];
    if(self)
    {
        _timeout  = config[@"timeout"];
        _sccpName = config[@"sccp"];
    }
    return self;
}

- (UMSCCP_TcapSharing_prerouteResult)preroutingPacketInside:(UMSCCP_Packet *)packet
{
    return UMSCCP_TcapSharing_routeNormal;
}

- (UMSCCP_TcapSharing_prerouteResult)postroutingPacketInside:(UMSCCP_Packet *)packet
{
    return UMSCCP_TcapSharing_routeNormal;
}

- (UMSCCP_TcapSharing_prerouteResult)preroutingPacketOutside:(UMSCCP_Packet *)packet
{
    return UMSCCP_TcapSharing_routeNormal;
}

- (UMSCCP_TcapSharing_prerouteResult)postroutingPacketOutside:(UMSCCP_Packet *)packet
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
