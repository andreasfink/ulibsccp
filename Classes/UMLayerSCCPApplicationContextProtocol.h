//
//  UMLayerSCCPApplicationContextProtocol.h
//  ulibsccp
//
//  Created by Andreas Fink on 24.01.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMSCCP_FilterProtocol.h"

@class UMLayerMTP3;
@protocol UMLayerSCCPApplicationContextProtocol<NSObject,UMSCCP_FilterDelegateProtocol>

-(UMLayerMTP3 *)getMTP3:(NSString *)name;
-(UMLayerSCCP *)getSCCP:(NSString *)name;
- (UMSynchronizedDictionary *)dbPools;

@end

