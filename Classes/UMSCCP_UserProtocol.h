//
//  UMSCCP_UserProtocol.h
//  ulibsccp
//
//  Created by Andreas Fink on 31/03/16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

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

- (id)decodePdu:(NSData *)data; /* should return a type which can be converted to json */

@end

@protocol UMSCCP_TraceProtocol <NSObject>

- (void)sccpTraceSentPdu:(NSData *)data
                 options:(NSDictionary *)options;


- (void)sccpTraceReceivedPdu:(NSData *)data
                     options:(NSDictionary *)options;

@end
