//
//  UMLayerSCCPApplicationContextProtocol.h
//  ulibsccp
//
//  Created by Andreas Fink on 24.01.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibsccp/UMSCCP_FilterProtocol.h>

@class UMLayerMTP3;
@class UMSCCP_TcapSharingInstance;
@protocol UMLayerSCCPApplicationContextProtocol<NSObject,UMSCCP_FilterDelegateProtocol>
- (UMLayerMTP3 *)getMTP3:(NSString *)name;
- (UMLayerSCCP *)getSCCP:(NSString *)name;
- (UMSynchronizedDictionary *)dbPools;
- (NSString *)filterEnginesPath;
- (id)licenseDirectory;
- (UMPrometheus *)prometheus;
- (NSString *)instanceName;
- (UMSCCP_TcapSharingInstance *)getTcapSharingInstance:(NSString *)name;

@end

