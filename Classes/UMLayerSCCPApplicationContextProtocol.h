//
//  UMLayerSCCPApplicationContextProtocol.h
//  ulibsccp
//
//  Created by Andreas Fink on 24.01.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UMLayerMTP3;
@protocol UMLayerSCCPApplicationContextProtocol<NSObject>

-(UMLayerMTP3 *)getMTP3:(NSString *)name;

@end
