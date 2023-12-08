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

#import <ulibsccp/ulibsccp.h>
#import <ulibm2pa/ulibm2pa.h>
#import <ulibmtp3/ulibmtp3.h>
#import <ulibgt/ulibgt.h>

#import <ulibsccp/UMSCCP_UserProtocol.h>
#import <ulibsccp/UMSCCPConnection.h>
#import <ulibsccp/UMSCCP_Defs.h>
#import <ulibsccp/UMSCCP_Segment.h>
#import <ulibsccp/UMLayerSCCPApplicationContextProtocol.h>
#import <ulibsccp/UMSCCP_Statistics.h>
#import <ulibsccp/UMSCCP_FilterProtocol.h>
#import <ulibsccp/UMSCCP_StatisticSection.h>
#import <ulibsccp/UMSCCP_Packet.h>
#import <ulibsccp/UMSCCP_TracefileProtocol.h>
#import <ulibsccp/UMSCCP_StatisticDb.h>

@class UMSCCP_Statistics;
@class UMSCCP_PrometheusData;
@class UMSCCP_PendingSegmentsStorage;

typedef enum SccpGtFileSection
{
    SccpGtFileSection_root,
    SccpGtFileSection_selector,
    SccpGtFileSection_application_group,
    SccpGtFileSection_address_conversion,
} SccpGtFileSection;


typedef enum UMSccpScreening_result
{
    UMSccpScreening_undefined=0,
    UMSccpScreening_explicitlyPermitted=1,
    UMSccpScreening_implicitlyPermitted=2,
    UMSccpScreening_explicitlyDenied=-1,
    UMSccpScreening_implicitlyDenied=-2,
    UMSccpScreening_errorResult = -99,
} UMSccpScreening_result;


@protocol sccp_tcapDecoder<NSObject>
- (NSString *) getAppContextFromDialogPortion:(UMASN1Object *)o;
- (NSNumber *) getOperationFromComponentPortion:(UMASN1Object *)o;
@end

@interface UMLayerSCCP : UMLayer<UMLayerMTP3UserProtocol>
{
    SccpVariant                 _sccpVariant;
    SccpDestinationGroup        *_defaultNextHop;

    SccpGttRegistry             *_gttSelectorRegistry;
    UMSynchronizedDictionary    *_subsystemUsers;
    NSString                    *_mtp3_name;
    UMLayerMTP3                 *_mtp3;
    UMSynchronizedDictionary    *_dpcAvailability;
    UMSynchronizedArray         *_traceSendDestinations;
    UMSynchronizedArray         *_traceReceiveDestinations;
    UMSynchronizedArray         *_traceDroppedDestinations;

    SccpL3RoutingTable          *_sccpL3RoutingTable;
    int                         _xudt_max_hop_count;
    int                         _xudts_max_hop_count;
    BOOL                        _stpMode;
    NSArray<UMMTP3PointCode *>  *_next_pcs;  /* if STP mode is NO, all traffic is sent to next_pcs instead of using a routing table */
    SccpDestinationGroup        *_default_destination_group;
    SccpTranslationTableNumber  *_overrideCalledTT;
    SccpTranslationTableNumber  *_overrideCallingTT;
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
    id<UMLayerSCCPApplicationContextProtocol>_appDelegate;
    UMTimer                     *_housekeepingTimer;
    BOOL                        _automaticAnsiItuConversion;
    NSNumber                    *_conversion_e164_tt;
    NSNumber                    *_conversion_e212_tt;
    
    NSString                                *_sccp_screeningPluginName;
    NSString                                *_sccp_screeningPluginConfigFileName;
    NSString                                *_sccp_screeningPluginTraceFileName;
    UMMTP3ScreeningTraceLevel               _sccpScreeningTraceLevel;

    FILE                                     *_sccp_screeningTraceFile;
    UMPlugin<UMMTP3SCCPScreeningPluginProtocol>  *_sccp_screeningPlugin;
    BOOL                                     _sccp_screeningLoggin;
    BOOL                                     _sccp_screeningActive;
    UMMutex                                  *_loggingLock;
    UMSCCP_PrometheusData                    *_prometheusData;
    id<sccp_tcapDecoder>                     _tcapDecodeDelegate; /* a delegate which decodes opcode and appcontext for us */
    UMSCCP_PendingSegmentsStorage            *_pendingSegmentsStorage;
}

@property(readwrite,assign) SccpVariant sccpVariant;
@property(readwrite,strong) SccpDestinationGroup *defaultNextHop;
@property(readwrite,strong) SccpGttRegistry *gttSelectorRegistry;
@property(readwrite,strong) NSMutableDictionary *pendingSegments;
@property(readwrite,strong) SccpL3RoutingTable *sccpL3RoutingTable;
@property(readwrite,assign) int xudt_max_hop_count;
@property(readwrite,assign) int xudts_max_hop_count;
@property(readwrite,assign) BOOL stpMode;
@property(readwrite,assign) BOOL statisticsReady;
@property(readwrite,strong) UMMTP3PointCode *next_pc;

@property(readwrite,strong,atomic)  id<UMSCCP_FilterDelegateProtocol> filterDelegate;

@property(readwrite,strong,atomic)  UMSCCP_StatisticDb          *statisticDb;

@property(readwrite,assign,atomic)  BOOL                        automaticAnsiItuConversion;
@property(readwrite,strong,atomic)  NSNumber                    *conversion_e164_tt;
@property(readwrite,strong,atomic)  NSNumber                    *conversion_e212_tt;
@property(readwrite,strong,atomic) id<sccp_tcapDecoder>         tcapDecoder;

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

@property(readwrite,strong,atomic) NSString                    *sccp_screeningPluginName;
@property(readwrite,strong,atomic) NSString                    *sccp_screeningPluginConfig;
@property(readwrite,strong,atomic) NSString                    *sccp_screeningPluginTraceFile;
@property(readwrite,strong,atomic) UMPlugin<UMMTP3SCCPScreeningPluginProtocol>   *sccp_screeningPlugin;
@property(readwrite,strong,atomic) UMSCCP_PrometheusData    *prometheusData;


- (void)increaseThroughputCounter:(UMSCCP_StatisticSection)section;

- (UMSynchronizedSortedDictionary *)statisticalInfo;
- (UMLayerMTP3 *)mtp3;
- (UMMTP3Variant) mtp3variant;

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
                sls:(int)sls
        linksetName:(NSString *)linksetName
            options:(NSDictionary *)xoptions
              ttmap:(UMMTP3TranslationTableMap *)map;

- (void)mtpTransfer:(NSData *)data
       callingLayer:(id)mtp3Layer
                opc:(UMMTP3PointCode *)opc
                dpc:(UMMTP3PointCode *)dpc
                 si:(int)si
                 ni:(int)ni
                sls:(int)sls
        linksetName:(NSString *)linksetName
            options:(NSDictionary *)options
              ttmap:(UMMTP3TranslationTableMap *)map
   cgaTranslationIn:(SccpNumberTranslation *)cga_number_translation_in
   cdaTranslationIn:(SccpNumberTranslation *)cda_number_translation_in;


- (void)mtpPause:(NSData *)data
    callingLayer:(id)mtp3Layer
      affectedPc:(UMMTP3PointCode *)opc
              si:(int)si
              ni:(int)ni
             sls:(int)sls
         options:(NSDictionary *)options;

- (void)mtpResume:(NSData *)data
     callingLayer:(id)mtp3Layer
       affectedPc:(UMMTP3PointCode *)opc
               si:(int)si
               ni:(int)ni
              sls:(int)sls
         options:(NSDictionary *)options;

- (void)mtpStatus:(NSData *)data
     callingLayer:(id)mtp3Layer
       affectedPc:(UMMTP3PointCode *)opc
               si:(int)si
               ni:(int)ni
              sls:(int)sls
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
        routedToLinkset:(NSString **)outgoingLinkset
                    sls:(int)sls;

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
          routedToLinkset:(NSString **)outgoingLinkset
                      sls:(int)sls;



    /* this is for UDTS generated locally */
- (UMMTP3_Error) generateUDTS:(NSData *)data
                      calling:(SccpAddress *)src
                       called:(SccpAddress *)dst
                        class:(SCCP_ServiceClass)pclass
                  returnCause:(SCCP_ReturnCause)reasonCode
                          opc:(UMMTP3PointCode *)opc
                          dpc:(UMMTP3PointCode *)dpc
                      options:(NSDictionary *)options
                     provider:(UMLayerMTP3 *)provider
                          sls:(int)sls;

- (UMMTP3_Error) generateXUDTS:(NSData *)data
                       calling:(SccpAddress *)src
                        called:(SccpAddress *)dst
                         class:(SCCP_ServiceClass)pclass
                   returnCause:(SCCP_ReturnCause)reasonCode
                           opc:(UMMTP3PointCode *)opc
                           dpc:(UMMTP3PointCode *)dpc
                       options:(NSDictionary *)options
                      provider:(UMLayerMTP3 *)provider
                           sls:(int)sls;

- (UMMTP3_Error) generateLUDTS:(NSData *)data
                       calling:(SccpAddress *)src
                        called:(SccpAddress *)dst
                         class:(SCCP_ServiceClass)pclass
                   returnCause:(SCCP_ReturnCause)reasonCode
                           opc:(UMMTP3PointCode *)opc
                           dpc:(UMMTP3PointCode *)dpc
                       options:(NSDictionary *)options
                      provider:(UMLayerMTP3 *)provider
sls:(int)sls;


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
         routedToLinkset:(NSString **)outgoingLinkset
                     sls:(int)sls;


/*
-(UMMTP3_Error) processXUDTsegment:(UMSCCP_Segment *)pdu
                           calling:(SccpAddress *)src
                            called:(SccpAddress *)dst
                      serviceClass:(SCCP_ServiceClass)pclass
                          handling:(SCCP_Handling)handling
                          hopCount:(int)hopCount
                               opc:(UMMTP3PointCode *)opc
                               dpc:(UMMTP3PointCode *)dpc
                       optionsData:(NSData *)xoptionsdata
                           options:(NSDictionary *)options
                          provider:(UMLayerMTP3 *)provider
                   routedToLinkset:(NSString **)outgoingLinkset
                               sls:(int)sls
                            packet:(UMSCCP_Packet *)pkt;

*/

-(UMMTP3_Error) sendXUDTsegment:(UMSCCP_Segment *)pdu
                        calling:(SccpAddress *)src
                         called:(SccpAddress *)dst
                   serviceClass:(SCCP_ServiceClass)pclass
                       handling:(SCCP_Handling)handling
                       hopCount:(int)hopCount
                            opc:(UMMTP3PointCode *)opc
                            dpc:(UMMTP3PointCode *)dpc
                    optionsData:(NSData *)xoptionsdata
                        options:(NSDictionary *)options
                       provider:(UMLayerMTP3 *)provider
                routedToLinkset:(NSString **)outgoingLinkset
                            sls:(int)sls;

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
          routedToLinkset:(NSString **)outgoingLinkset
                      sls:(int)sls;


- (UMSynchronizedSortedDictionary *) routeTestForMSISDN:(NSString *)msisdn
                                        translationType:(int)tt
                                              fromLocal:(BOOL)fromLocal
                                      transactionNumber:(NSNumber *)tid
                                              operation:(NSNumber *)op
                                     applicationContext:(NSString *)ac
                                        incomingLinkset:(NSString *)linkset
                                          sourceAddress:(NSString *)source;


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

- (void)startStatisticsDb;

- (void)stopDetachAndDestroy;
- (void)addProcessingStatistic:(UMSCCP_StatisticSection)section
                  waitingDelay:(NSTimeInterval)waitingDelay
               processingDelay:(NSTimeInterval)processingDelay;

- (void)  httpGetPost:(UMHTTPRequest *)req;

- (NSString *)webE164;
- (NSString *)webE212;
- (NSString *)webE214;

- (void) localDeliverNUnitdata:(NSData *)data
          toUser:(id<UMSCCP_UserProtocol>)localUser
         calling:(SccpAddress *)callingPartyAddress
          called:(SccpAddress *)calledPartyAddress
qualityOfService:(int)qos
           class:(SCCP_ServiceClass)serviceClass
        handling:(SCCP_Handling)handling
         options:(NSDictionary *)options;

- (UMSccpScreening_result)screenSccpPacketInbound:(UMSCCP_Packet *)packet
                                            error:(NSError **)err
                                           plugin:(UMPlugin<UMMTP3SCCPScreeningPluginProtocol>*)plugin
                                 traceDestination:(UMMTP3LinkSet *)tracedest;

- (void)reopenLogfiles;
- (void)reloadPluginConfigs;
- (void)reloadPlugins;

@end
