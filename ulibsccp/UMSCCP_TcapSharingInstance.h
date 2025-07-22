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

typedef enum UMSCCP_TcapSharing_result
{
    UMSCCP_TcapSharing_routeNormal      = 0,
    UMSCCP_TcapSharing_skipRouting      = 1,
} UMSCCP_TcapSharing_result;

@interface UMSCCP_TcapSharingInstance : UMBackgrounder
{
    NSTimeInterval  _timeout;
    id              _appDelegate;
    NSString        *_sccpName;
    UMLayerSCCP     *_sccpInstance;
    UMSynchronizedDictionary    *_outsideBackRoutes;
    
}
@property(readwrite,assign,atomic)  NSTimeInterval  timeout;
@property(readwrite,strong,atomic)  id              appDelegate;
@property(readwrite,strong,atomic)  NSString        *sccpName;
@property(readwrite,strong,atomic)  UMLayerSCCP     *sccpInstance;
@property(readwrite,strong,atomic)  UMSynchronizedDictionary    *outsideBackRoutes;

- (UMSCCP_TcapSharingInstance *)initWithConfig:(NSDictionary *)config;

- (UMSCCP_TcapSharing_result)preroutingPacketInside:(UMSCCP_Packet *)packet;
- (UMSCCP_TcapSharing_result)postroutingPacketInside:(UMSCCP_Packet *)packet;
- (UMSCCP_TcapSharing_result)preroutingPacketOutside:(UMSCCP_Packet *)packet;
- (UMSCCP_TcapSharing_result)postroutingPacketOutside:(UMSCCP_Packet *)packet;

@end

