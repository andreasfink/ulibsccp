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
    SccpVariant                 _sccpVariant;
    SccpDestinationGroup        *_defaultNextHop;

    SccpGttRegistry             *_gttSelectorRegistry;
    UMSynchronizedDictionary    *_subsystemUsers;
    NSString                    *_mtp3_name;
    UMLayerMTP3                 *_mtp3;
    UMSynchronizedDictionary    *_dpcAvailability;
    NSMutableDictionary         *_pendingSegments;

    UMSynchronizedArray         *_traceSendDestinations;
    UMSynchronizedArray         *_traceReceiveDestinations;
    UMSynchronizedArray         *_traceDroppedDestinations;

    SccpL3RoutingTable          *_mtp3RoutingTable;
    UMSCCP_MTP3RoutingTable     *_routingTable;
    int                         _xudt_max_hop_count;
    int                         _xudts_max_hop_count;
    BOOL                        _stpMode;
    UMMTP3PointCode             *_next_pc;
}

@property(readwrite,assign) SccpVariant sccpVariant;
@property(readwrite,strong) SccpDestinationGroup *defaultNextHop;
@property(readwrite,strong) SccpGttRegistry *gttSelectorRegistry;
@property(readwrite,strong) NSMutableDictionary *pendingSegments;
@property(readwrite,strong) SccpL3RoutingTable *mtp3RoutingTable;
@property(readwrite,assign) int xudt_max_hop_count;
@property(readwrite,assign) int xudts_max_hop_count;
@property(readwrite,assign) BOOL stpMode;
@property(readwrite,strong) UMMTP3PointCode *next_pc;

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
               provider:(UMLayerMTP3 *)provider;

- (UMMTP3_Error) sendUDTS:(NSData *)data
                  calling:(SccpAddress *)src
                   called:(SccpAddress *)dst
                   reason:(int)reasonCode
                      opc:(UMMTP3PointCode *)opc
                      dpc:(UMMTP3PointCode *)dpc
                  options:(NSDictionary *)options
                 provider:(UMLayerMTP3 *)provider;


-(UMMTP3_Error) sendXUDT:(NSData *)pdu
                 calling:(SccpAddress *)src
                  called:(SccpAddress *)dst
                   class:(int)cls
              hopCount:(int)hopCount
           returnOnError:(BOOL)reterr
                     opc:(UMMTP3PointCode *)opc
                     dpc:(UMMTP3PointCode *)dpc
             optionsData:(NSData *)xoptionsdata
                 options:(NSDictionary *)options
                provider:(UMLayerMTP3 *)provider;


-(UMMTP3_Error) sendXUDTsegment:(UMSCCP_Segment *)pdu
                        calling:(SccpAddress *)src
                         called:(SccpAddress *)dst
                          class:(int)cls
                     hopCount:(int)hopCount
                  returnOnError:(BOOL)reterr
                            opc:(UMMTP3PointCode *)opc
                            dpc:(UMMTP3PointCode *)dpc
                    optionsData:(NSData *)xoptionsdata
                        options:(NSDictionary *)options
                       provider:(UMLayerMTP3 *)provider;

-(UMMTP3_Error) sendXUDTS:(NSData *)data
                  calling:(SccpAddress *)src
                   called:(SccpAddress *)dst
              returnCause:(int)returnCause
               hopCount:(int)hopCount
                      opc:(UMMTP3PointCode *)opc
                      dpc:(UMMTP3PointCode *)dpc
              optionsData:(NSData *)xoptionsdata
                  options:(NSDictionary *)options
                 provider:(UMLayerMTP3 *)provider;


-(void) routeUDT:(NSData *)pdu
         calling:(SccpAddress *)src
          called:(SccpAddress *)dst
           class:(int)cls
   returnOnError:(BOOL)reterr
             opc:(UMMTP3PointCode *)opc
             dpc:(UMMTP3PointCode *)dpc
         options:(NSDictionary *)options
        provider:(UMLayerMTP3 *)provider
       fromLocal:(BOOL)fromLocal;


- (void) routeUDTS:(NSData *)data
           calling:(SccpAddress *)src
            called:(SccpAddress *)dst
            reason:(int)reasonCode
               opc:(UMMTP3PointCode *)opc
               dpc:(UMMTP3PointCode *)dpc
           options:(NSDictionary *)options
          provider:(UMLayerMTP3 *)provider
         fromLocal:(BOOL)fromLocal;



- (void) routeXUDT:(NSData *)data
           calling:(SccpAddress *)src
            called:(SccpAddress *)dst
             class:(int)class_and_handling
          hopCount:(int)hopCount
     returnOnError:(BOOL)returnOnError
               opc:(UMMTP3PointCode *)opc
               dpc:(UMMTP3PointCode *)dpc
       optionsData:(NSData *)xoptionsdata
           options:(NSDictionary *)options
          provider:(UMLayerMTP3 *)provider
         fromLocal:(BOOL)fromLocal;


-(void) routeXUDTsegment:(UMSCCP_Segment *)segment
                 calling:(SccpAddress *)src
                  called:(SccpAddress *)dst
                   class:(int)class_and_handling
                hopCount:(int)hopCount
           returnOnError:(BOOL)reterr
                     opc:(UMMTP3PointCode *)opc
                     dpc:(UMMTP3PointCode *)dpc
             optionsData:(NSData *)xoptionsdata
                 options:(NSDictionary *)options
                provider:(UMLayerMTP3 *)provider
               fromLocal:(BOOL)fromLocal;


- (void) routeXUDTS:(NSData *)data
           calling:(SccpAddress *)src
            called:(SccpAddress *)dst
            reason:(int)reasonCode
          hopCount:(int)maxHopCount
               opc:(UMMTP3PointCode *)opc
               dpc:(UMMTP3PointCode *)dpc
        optionsData:(NSData *)xoptionsdata
           options:(NSDictionary *)options
          provider:(UMLayerMTP3 *)provider
          fromLocal:(BOOL)fromLocal;


- (void)findRoute:(SccpAddress **)dst
       causeValue:(int *)cause
        localUser:(id<UMSCCP_UserProtocol> *)user
        pointCode:(UMMTP3PointCode **)pc
        fromLocal:(BOOL)isLocal;

- (NSUInteger)maxPayloadSizeForServiceType:(SCCP_ServiceType) serviceType
                        callingAddressSize:(NSUInteger)cas
                         calledAddressSize:(NSUInteger)cds
                             usingSegments:(BOOL)useSeg
                                  provider:(UMLayerMTP3 *)provider;

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerSCCPApplicationContextProtocol>)appContext;
- (NSDictionary *)config;
- (void)startUp;

+ (NSString *)reasonString:(SCCP_ReturnCause)reason;
- (id)decodePdu:(NSData *)data;
- (void)traceSentPdu:(NSData *)pdu options:(NSDictionary *)dict;
- (void)traceReceivedPdu:(NSData *)pdu options:(NSDictionary *)dict;
- (void)traceDroppedPdu:(NSData *)pdu options:(NSDictionary *)dict;
- (NSDictionary *)apiStatus;

- (void)stopDetachAndDestroy;

@end
