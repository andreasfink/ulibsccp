//
//  UMLayerSCCP.h
//  ulibsccp
//
//  Created by Andreas Fink on 01/07/15.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulibsctp/ulibsctp.h>
#import <ulibm2pa/ulibm2pa.h>
#import <ulibmtp3/ulibmtp3.h>
#import <ulibgt/ulibgt.h>
#import "UMSCCP_UserProtocol.h"
#import "UMSCCPConnection.h"
#import "UMSCCP_Defs.h"
#import "UMSCCP_Segment.h"
#import "UMLayerSCCPApplicationContextProtocol.h"

@class UMSCCP_MTP3RoutingTable;
@interface UMLayerSCCP : UMLayer<UMLayerMTP3UserProtocol>
{
    SccpVariant                 sccpVariant;
    SccpNextHop                 *defaultNextHop;
    SccpL3Provider              *defaultProvider;
    
    SccpGttRegistry             *gttSelectorRegistry;
    UMSynchronizedDictionary    *subsystemUsers;
    NSString                    *mtp3_name;
    UMLayerMTP3                 *mtp3;
    UMSynchronizedDictionary    *dpcAvailability;
    NSMutableDictionary         *pendingSegments;

    UMSynchronizedArray         *traceSendDestinations;
    UMSynchronizedArray         *traceReceiveDestinations;
    UMSynchronizedArray         *traceDroppedDestinations;

    UMSCCP_MTP3RoutingTable *_routingTable;

}

@property(readwrite,assign) SccpVariant sccpVariant;
@property(readwrite,strong) UMSynchronizedDictionary *allProviders;
@property(readwrite,strong) SccpNextHop     *defaultNextHop;
@property(readwrite,strong) SccpL3Provider  *defaultProvider;
@property(readwrite,strong) SccpGttRegistry *gttSelectorRegistry;
@property(readwrite,strong) NSString    *attachTo;
@property(readwrite,strong) UMLayerMTP3  *attachedTo;
@property(readwrite,strong) NSMutableDictionary *pendingSegments;

- (UMLayerMTP3 *)mtp3;
- (UMMTP3Variant) variant;

- (NSString *)status;

/* connection oriented primitives */
- (void)sccpNConnectRequest:(UMSCCPConnection **)connection
               callingLayer:(id<UMSCCP_UserProtocol>)userLayer
                    calling:(SccpAddress *)src
                     called:(SccpAddress *)dst
                    options:(NSDictionary *)options;

- (void)sccpNDataRequest:(NSData *)data
              connection:(UMSCCPConnection *)connection
                 options:(NSDictionary *)options;

- (void)sccpNExpeditedData:(NSData *)data
                connection:(UMSCCPConnection *)connection
                   options:(NSDictionary *)options;

- (void)sccpNResetRequest:(UMSCCPConnection *)connection
                  options:(NSDictionary *)options;

- (void)sccpNResetIndication:(UMSCCPConnection *)connection
                     options:(NSDictionary *)options;

- (void)sccpNDisconnectRequest:(UMSCCPConnection *)connection
                       options:(NSDictionary *)options;

- (void)sccpNDisconnectIndicaton:(UMSCCPConnection *)connection
                         options:(NSDictionary *)options;

- (void)sccpNInform:(UMSCCPConnection *)connection
            options:(NSDictionary *)options;


/* connectionless primitives */
- (void)sccpNUnidata:(NSData *)data
        callingLayer:(id<UMSCCP_UserProtocol>)userLayer
             calling:(SccpAddress *)src
              called:(SccpAddress *)dst
    qualityOfService:(int)qos
             options:(NSDictionary *)options;

- (void)sccpNNotice:(NSData *)data
       callingLayer:(id<UMSCCP_UserProtocol>)userLayer
            calling:(SccpAddress *)src
             called:(SccpAddress *)dst
            options:(NSDictionary *)options;

- (void)sccpNState:(NSData *)data
      callingLayer:(id<UMSCCP_UserProtocol>)userLayer
           calling:(SccpAddress *)src
            called:(SccpAddress *)dst
           options:(NSDictionary *)options;

- (void)sccpNCoord:(NSData *)data
      callingLayer:(id<UMSCCP_UserProtocol>)userLayer
           calling:(SccpAddress *)src
            called:(SccpAddress *)dst
           options:(NSDictionary *)options;

- (void)sccpNTraffic:(NSData *)data
        callingLayer:(id<UMSCCP_UserProtocol>)userLayer
             calling:(SccpAddress *)src
              called:(SccpAddress *)dst
             options:(NSDictionary *)options;

- (void)sccpNPcState:(NSData *)data
        callingLayer:(id<UMSCCP_UserProtocol>)userLayer
             calling:(SccpAddress *)src
              called:(SccpAddress *)dst
             options:(NSDictionary *)options;


- (void)mtpTransfer:(NSData *)data
       callingLayer:(id)mtp3Layer
                opc:(UMMTP3PointCode *)opc
                dpc:(UMMTP3PointCode *)dpc
                 si:(int)si
                 ni:(int)ni
        linksetName:(NSString *)linksetName
            options:(NSDictionary *)options;

- (void)mtpPause:(NSData *)data
    callingLayer:(id)mtp3Layer
      affectedPc:(UMMTP3PointCode *)opc
              si:(int)si
              ni:(int)ni
         options:(NSDictionary *)options;

- (void)mtpResume:(NSData *)data
     callingLayer:(id)mtp3Layer
       affectedPc:(UMMTP3PointCode *)opc
               si:(int)si
               ni:(int)ni
          options:(NSDictionary *)options;

- (void)mtpStatus:(NSData *)data
     callingLayer:(id)mtp3Layer
       affectedPc:(UMMTP3PointCode *)opc
               si:(int)si
               ni:(int)ni
           status:(int)status
          options:(NSDictionary *)options;

- (id<UMSCCP_UserProtocol>)getUserForSubsystem:(SccpSubSystemNumber *)ssn number:(SccpAddress *)number;

- (id<UMSCCP_UserProtocol>)getUserForSubsystem:(SccpSubSystemNumber *)ssn; /* DEPRECIATED */
- (void)setUser:(id<UMSCCP_UserProtocol>)usr forSubsystem:(SccpSubSystemNumber *)ssn number:(SccpAddress *)number;
- (void)setUser:(id<UMSCCP_UserProtocol>)usr forSubsystem:(SccpSubSystemNumber *)ssn;

- (void)setDefaultUser:(id<UMSCCP_UserProtocol>)usr;


-(UMMTP3_Error) sendUDT:(NSData *)pdu
                calling:(SccpAddress *)src
                 called:(SccpAddress *)dst
                  class:(int)cls
          returnOnError:(BOOL)reterr
                    opc:(UMMTP3PointCode *)opc
                    dpc:(UMMTP3PointCode *)dpc
                options:(NSDictionary *)options
               provider:(SccpL3Provider *)provider;

-(UMMTP3_Error) sendXUDTsegment:(UMSCCP_Segment *)pdu
                        calling:(SccpAddress *)src
                         called:(SccpAddress *)dst
                          class:(int)cls
                    maxHopCount:(int)maxHopCount
                  returnOnError:(BOOL)reterr
                            opc:(UMMTP3PointCode *)opc
                            dpc:(UMMTP3PointCode *)dpc
                    optionsData:(NSData *)xoptionsdata
                        options:(NSDictionary *)options
                       provider:(SccpL3Provider *)provider;

-(UMMTP3_Error) sendXUDTdata:(NSData *)pdu
                     calling:(SccpAddress *)src
                      called:(SccpAddress *)dst
                       class:(int)cls
                 maxHopCount:(int)maxHopCount
               returnOnError:(BOOL)reterr
                         opc:(UMMTP3PointCode *)opc
                         dpc:(UMMTP3PointCode *)dpc
                 optionsData:(NSData *)xoptionsdata
                     options:(NSDictionary *)options
                    provider:(SccpL3Provider *)provider;

- (NSUInteger)maxPayloadSizeForServiceType:(SCCP_ServiceType) serviceType
                        callingAddressSize:(NSUInteger)cas
                         calledAddressSize:(NSUInteger)cds
                             usingSegments:(BOOL)useSeg
                                  provider:(SccpL3Provider *)provider;

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerSCCPApplicationContextProtocol>)appContext;
- (NSDictionary *)config;
- (void)startUp;

+ (NSString *)reasonString:(SCCP_ReturnCause)reason;
- (id)decodePdu:(NSData *)data;
- (void)traceSentPdu:(NSData *)pdu options:(NSDictionary *)dict;
- (void)traceReceivedPdu:(NSData *)pdu options:(NSDictionary *)dict;
- (void)traceDroppedPdu:(NSData *)pdu options:(NSDictionary *)dict;

@end
