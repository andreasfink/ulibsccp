//
//  UMSCCP_TcapSharingInstance.h
//  ulibsccp
//
//  Created by Andreas Fink on 11.07.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibgt/ulibgt.h>
@class UMLayerSCCP;
@class UMSCCP_Packet;

typedef enum UMSCCP_TcapSharing_prerouteResult
{
    UMSCCP_TcapSharing_routeNormal      = 0,
    UMSCCP_TcapSharing_routingComplete  = 1,
} UMSCCP_TcapSharing_prerouteResult;

@interface UMSCCP_TcapSharingInstance : UMBackgrounder
{
    NSNumber        *_timeout;
    id              _appDelegate;
    NSString        *_sccpName;
    UMLayerSCCP     *_sccpInstance;
}
@property(readwrite,strong,atomic)  NSNumber        *timeout;
@property(readwrite,strong,atomic)  id              appDelegate;
@property(readwrite,strong,atomic)  NSString        *sccpName;
@property(readwrite,strong,atomic)  UMLayerSCCP     *sccpInstance;

- (UMSCCP_TcapSharingInstance *)initWithConfig:(NSDictionary *)config;

- (UMSCCP_TcapSharing_prerouteResult)preroutingPacketInside:(UMSCCP_Packet *)packet;
- (UMSCCP_TcapSharing_prerouteResult)postroutingPacketInside:(UMSCCP_Packet *)packet;
- (UMSCCP_TcapSharing_prerouteResult)preroutingPacketOutside:(UMSCCP_Packet *)packet;
- (UMSCCP_TcapSharing_prerouteResult)postroutingPacketOutside:(UMSCCP_Packet *)packet;

@end

