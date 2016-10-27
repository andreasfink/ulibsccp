//
//  UMSCCP_UserProtocol.h
//  ulibsccp
//
//  Created by Andreas Fink on 31/03/16.
//  Copyright (c) 2016 Andreas Fink
//

#import <ulibgt/ulibgt.h>

#import "UMSCCP_UserProtocol.h"
#import "UMSCCPConnection.h"
@class UMLayerSCCP;

@protocol UMSCCP_UserProtocol <NSObject,UMLayerUserProtocol>

/* this is called from lower layer to deliver data to the TCAP Layer */

- (void)sccpNDataIndication:(NSData *)data
                 connection:(UMSCCPConnection *)connection
                    options:(NSDictionary *)options;

- (void)sccpNUnitdata:(NSData *)data
         callingLayer:(UMLayerSCCP *)sccpLayer
              calling:(SccpAddress *)src
               called:(SccpAddress *)dst
     qualityOfService:(int)qos
              options:(NSDictionary *)options;

- (void)sccpNNotice:(NSData *)data
       callingLayer:(UMLayerSCCP *)sccpLayer
            calling:(SccpAddress *)src
             called:(SccpAddress *)dst
             reason:(int)reason
            options:(NSDictionary *)options;

- (NSString *)decodePdu:(NSData *)data;

@end

@protocol UMSCCP_TraceProtocol <NSObject>

- (void)sccpTraceSentPdu:(NSData *)data
                 options:(NSDictionary *)options;


@end
