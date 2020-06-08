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
#import "UMSCCP_Statistics.h"
#import "UMSCCP_FilterProtocol.h"
#import "UMSCCP_StatisticSection.h"
#import "UMSCCP_Packet.h"
#import "UMSCCP_TracefileProtocol.h"
#import "UMSCCP_StatisticDb.h"

typedef enum SccpGtFileSection
{
    SccpGtFileSection_root,
    SccpGtFileSection_selector,
    SccpGtFileSection_application_group,
    SccpGtFileSection_address_conversion,
} SccpGtFileSection;


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
    int                         _xudt_max_hop_count;
    int                         _xudts_max_hop_count;
    BOOL                        _stpMode;
    NSArray<UMMTP3PointCode *>  *_next_pcs;  /* if STP mode is NO, all traffic is sent to next_pcs instead of using a routing table */
    SccpDestinationGroup        *_default_destination_group;
    SccpTranslationTableNumber  *_ntt;
    UMSCCP_Statistics           *_processingStats[UMSCCP_StatisticSection_MAX];
    UMThroughputCounter         *_throughputCounters[UMSCCP_StatisticSection_MAX];
    BOOL                        _statisticsReady;
    
    NSString                    *_statisticDbPool;
    NSString                    *_statisticDbTable;
    NSNumber                    *_statisticDbAutoCreate;
    UMSCCP_StatisticDb          *_statisticDb;
    NSString                    *_statisticDbInstance;

    /* this is now done in appDelegate
    NSString *_inboundFilterName;
    NSString *_outboundFilterName;
    NSString *_fromLocalFilterName;
    NSString *_toLocalFilterName;

	id<UMSCCP_FilterProtocol>   _inboundFilter;
	id<UMSCCP_FilterProtocol>   _outboundFilter;
    id<UMSCCP_FilterProtocol>   _fromLocalFilter;
    id<UMSCCP_FilterProtocol>   _toLocalFilter;
     */

    id<UMSCCP_TracefileProtocol>    _problematicTraceDestination;
    id<UMSCCP_TracefileProtocol>    _unrouteablePacketsTraceDestination;
    BOOL                         _routeErrorsBackToOriginatingPointCode;
    id<UMSCCP_FilterDelegateProtocol> _filterDelegate;
    id<UMLayerSCCPApplicationContextProtocol>_dbDelegate;
    UMTimer                     *_housekeepingTimer;
}

@property(readwrite,assign) SccpVariant sccpVariant;
@property(readwrite,strong) SccpDestinationGroup *defaultNextHop;
@property(readwrite,strong) SccpGttRegistry *gttSelectorRegistry;
@property(readwrite,strong) NSMutableDictionary *pendingSegments;
@property(readwrite,strong) SccpL3RoutingTable *mtp3RoutingTable;
@property(readwrite,assign) int xudt_max_hop_count;
@property(readwrite,assign) int xudts_max_hop_count;
@property(readwrite,assign) BOOL stpMode;
@property(readwrite,assign) BOOL statisticsReady;
@property(readwrite,strong) UMMTP3PointCode *next_pc;

@property(readwrite,strong,atomic)  id<UMSCCP_FilterDelegateProtocol> filterDelegate;

@property(readwrite,strong,atomic)  UMSCCP_StatisticDb          *statisticDb;


/*
@property(readwrite,strong,atomic) id<UMSCCP_FilterProtocol>   inboundFilter;
@property(readwrite,strong,atomic) id<UMSCCP_FilterProtocol>   outboundFilter;
@property(readwrite,strong,atomic) id<UMSCCP_FilterProtocol>   fromLocalFilter;
@property(readwrite,strong,atomic) id<UMSCCP_FilterProtocol>   toLocalFilter;
@property(readwrite,strong,atomic) NSString *  inboundFilterName;
@property(readwrite,strong,atomic) NSString *   outboundFilterName;
@property(readwrite,strong,atomic) NSString *   fromLocalFilterName;
@property(readwrite,strong,atomic) NSString *   toLocalFilterName;
*/


@property(readwrite,strong,atomic) id<UMSCCP_TracefileProtocol>    problematicTraceDestination;
@property(readwrite,strong,atomic) id<UMSCCP_TracefileProtocol>    unrouteablePacketsTraceDestination;
@property(readwrite,assign,atomic) BOOL    routeErrorsBackToSource;

- (void)increaseThroughputCounter:(UMSCCP_StatisticSection)section;

- (UMSynchronizedSortedDictionary *)statisticalInfo;
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
               class:(SCCP_ServiceClass)pclass
            handling:(SCCP_Handling)handling
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
            options:(NSDictionary *)options
              ttmap:(UMMTP3TranslationTableMap *)map;


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
                  class:(SCCP_ServiceClass)pclass
               handling:(SCCP_Handling)handling
                    opc:(UMMTP3PointCode *)opc
                    dpc:(UMMTP3PointCode *)dpc
                options:(NSDictionary *)options
               provider:(UMLayerMTP3 *)provider
        routedToLinkset:(NSString **)outgoingLinkset;

    /* this is for transiting UDTS */
- (UMMTP3_Error) sendUDTS:(NSData *)data
                  calling:(SccpAddress *)src
                   called:(SccpAddress *)dst
                    class:(SCCP_ServiceClass)pclass
              returnCause:(SCCP_ReturnCause)returnCause
                      opc:(UMMTP3PointCode *)opc
                      dpc:(UMMTP3PointCode *)dpc
                  options:(NSDictionary *)options
                 provider:(UMLayerMTP3 *)provider
          routedToLinkset:(NSString **)outgoingLinkset;


    /* this is for UDTS generated locally */
- (UMMTP3_Error) generateUDTS:(NSData *)data
                      calling:(SccpAddress *)src
                       called:(SccpAddress *)dst
                        class:(SCCP_ServiceClass)pclass
                  returnCause:(SCCP_ReturnCause)reasonCode
                          opc:(UMMTP3PointCode *)opc
                          dpc:(UMMTP3PointCode *)dpc
                      options:(NSDictionary *)options
                     provider:(UMLayerMTP3 *)provider;

- (UMMTP3_Error) generateXUDTS:(NSData *)data
                       calling:(SccpAddress *)src
                        called:(SccpAddress *)dst
                         class:(SCCP_ServiceClass)pclass
                   returnCause:(SCCP_ReturnCause)reasonCode
                           opc:(UMMTP3PointCode *)opc
                           dpc:(UMMTP3PointCode *)dpc
                       options:(NSDictionary *)options
                      provider:(UMLayerMTP3 *)provider;

- (UMMTP3_Error) generateLUDTS:(NSData *)data
                       calling:(SccpAddress *)src
                        called:(SccpAddress *)dst
                         class:(SCCP_ServiceClass)pclass
                   returnCause:(SCCP_ReturnCause)reasonCode
                           opc:(UMMTP3PointCode *)opc
                           dpc:(UMMTP3PointCode *)dpc
                       options:(NSDictionary *)options
                      provider:(UMLayerMTP3 *)provider;

-(UMMTP3_Error) sendXUDT:(NSData *)pdu
                 calling:(SccpAddress *)src
                  called:(SccpAddress *)dst
                   class:(SCCP_ServiceClass)pclass
                handling:(SCCP_Handling)handling
                hopCount:(int)hopCount
                     opc:(UMMTP3PointCode *)opc
                     dpc:(UMMTP3PointCode *)dpc
             optionsData:(NSData *)xoptionsdata
                 options:(NSDictionary *)options
                provider:(UMLayerMTP3 *)provider
         routedToLinkset:(NSString **)outgoingLinkset;


-(UMMTP3_Error) sendXUDTsegment:(UMSCCP_Segment *)pdu
                        calling:(SccpAddress *)src
                         called:(SccpAddress *)dst
                          class:(SCCP_ServiceClass)pclass
                       handling:(SCCP_Handling)handling
                       hopCount:(int)hopCount
                            opc:(UMMTP3PointCode *)opc
                            dpc:(UMMTP3PointCode *)dpc
                    optionsData:(NSData *)xoptionsdata
                        options:(NSDictionary *)options
                       provider:(UMLayerMTP3 *)provider
                routedToLinkset:(NSString **)outgoingLinkset;

-(UMMTP3_Error) sendXUDTS:(NSData *)data
                  calling:(SccpAddress *)src
                   called:(SccpAddress *)dst
                    class:(SCCP_ServiceClass)pclass
                 hopCount:(int)hopCount
              returnCause:(SCCP_ReturnCause)returnCause
                      opc:(UMMTP3PointCode *)opc
                      dpc:(UMMTP3PointCode *)dpc
              optionsData:(NSData *)xoptionsdata
                  options:(NSDictionary *)options
                 provider:(UMLayerMTP3 *)provider
          routedToLinkset:(NSString **)outgoingLinkset;

- (UMSynchronizedSortedDictionary *) routeTestForMSISDN:(NSString *)msisdn
                                        translationType:(int)tt
                                              fromLocal:(BOOL)fromLocal;


- (BOOL)routePacket:(UMSCCP_Packet *)packet; /* returns YES if sucessfully forwarded, NO if it wasn able to route it */
/* Note: this doesnt work if all packets dont have the same routing destination ! */


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
- (void)traceSentPacket:(UMSCCP_Packet *)packet options:(NSDictionary *)dict;
- (void)traceReceivedPdu:(NSData *)pdu options:(NSDictionary *)dict;
- (void)traceReceivedPacket:(UMSCCP_Packet *)packet options:(NSDictionary *)o;
- (void)traceDroppedPdu:(NSData *)pdu options:(NSDictionary *)dict;
- (void)traceDroppedPacket:(UMSCCP_Packet *)packet options:(NSDictionary *)dict;
- (NSDictionary *)apiStatus;
- (UMSynchronizedSortedDictionary *)routeStatus;

- (void)stopDetachAndDestroy;
- (void)addProcessingStatistic:(UMSCCP_StatisticSection)section
                  waitingDelay:(NSTimeInterval)waitingDelay
               processingDelay:(NSTimeInterval)processingDelay;

@end
