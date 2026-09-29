//
//  UMSCCP_RoutingState.h
//  ulibsccp
//
//  Created by Andreas Fink on 15.07.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibmtp3/ulibmtp3.h>
#import <ulibsccp/ulibgt.h>
#import <ulibsccp/UMSCCP_Defs.h>
#import <ulibsccp/UMSCCP_TcapSharingInstance.h>

@class UMSCCP_ReceivedSegment;

typedef enum UMSCCP_RoutingStatus
{
    UMSCCP_RoutingStatus_success = 0,
    UMSCCP_RoutingStatus_failed,
    UMSCCP_RoutingStatus_dropPacket,
    UMSCCP_RoutingStatus_awaitingSegments,
} UMSCCP_RoutingStatus;

typedef enum UMSCCP_RoutingErrorProcessing
{
    UMSCCP_RoutingErrorProcessing_Ignore,
    UMSCCP_RoutingErrorProcessing_UDTS,
    UMSCCP_RoutingErrorProcessing_XUDTS,
    UMSCCP_RoutingErrorProcessing_LUDTS,
} UMSCCP_RoutingErrorProcessing;



@class UMSCCP_Packet;

@interface UMSCCP_RoutingState : UMObject
{
    UMSCCP_RoutingStatus    _status;
    UMSCCP_RoutingErrorProcessing   _errorProcessing;
    /* if we run into errors, thats where we signal it back to */
    UMSCCP_Packet           *_inboundPacket;
    UMSCCP_Packet           *_inboundReassembledPacket;
    NSArray<UMSCCP_ReceivedSegment *>*_inboundPacketSegments;

    UMMTP3PointCode         *_dpcForErrors;
    UMMTP3PointCode         *_opcForErrors;
    NSString                *_linksetForErrors;
    NSNumber                *_slcForErrors;
    UMMTP3Link              *_linkForErrors;
    NSNumber                *_errorServiceType; /* SCCP_ServiceType */
    UMM3UAApplicationServer *_asForErrors;
    UMSCCP_Packet           *_errorPacket;              /* the original packet which created the error. We use it for UDTS generation */
    NSArray<UMSCCP_Packet *>*_errorPacketSegments;      /* if it was multiparts, we have to send errors for every part. in this case _errorPacket is null */
    BOOL                    _errorDestinationLocal;
    BOOL                    _reportStatus;              /* do we report errors at all?  */
    BOOL                    _deliverLocal;              /* we deliver on to the local upper layers  */
    BOOL                    _swallow;                   /* eated the packet because its a multi segment packet and we wait for more */
    BOOL                    _drop;                      /* eated the packet because its violating filters or policy */
    BOOL                    _processRouting;            /* shall we process normal routing */
    NSNumber                *_cause;                    /* the SCCP result cause in UDT/UDTS etc */
    
    SccpDestinationGroup    *_destinationGroup;
    NSString                *_outgoingLinksetName;
    UMMTP3PointCode         *_outgoingDpc;
    NSNumber                *_outgoingSlc;

    UMSCCP_Packet           *_packetToDeliver;
    NSArray<UMSCCP_ReceivedSegment *>*_packetSegmentsToDeliver;
    UMMTP3_Error            _mtp3DeliveryError;
    BOOL                    _skipRouting;
    
    SccpDestinationGroup    *_forcedDestinationGroup;
    NSString                *_forcedDestinationName;
    NSString                *_forcedLinkset;
    UMMTP3PointCode         *_forcedDpc;
    BOOL                    _mustResegment;
    UMSCCP_TcapSharing_result _tcapSharingResult;
    NSMutableString         *_routingTestDebug;
}

@property(readwrite,atomic,assign)  UMSCCP_RoutingStatus            status;
@property(readwrite,atomic,assign)  UMSCCP_RoutingErrorProcessing   errorProcessing;

@property(readwrite,atomic,strong)  UMSCCP_Packet           *inboundPacket;
@property(readwrite,atomic,strong)  UMSCCP_Packet           *inboundReassembledPacket;
@property(readwrite,atomic,strong)  NSArray<UMSCCP_ReceivedSegment *>*inboundPacketSegments;

@property(readwrite,atomic,strong)  UMMTP3PointCode         *dpcForErrors;
@property(readwrite,atomic,strong)  UMMTP3PointCode         *opcForErrors;
@property(readwrite,atomic,strong)  NSString                *linksetForErrors;
@property(readwrite,atomic,strong)  NSNumber                *slcForErrors;
@property(readwrite,atomic,strong)  UMMTP3Link              *linkForErrors;
@property(readwrite,atomic,strong)  NSNumber                *errorServiceType; /* SCCP_ServiceType */
@property(readwrite,atomic,strong)  UMM3UAApplicationServer *asForErrors;
@property(readwrite,atomic,strong)  UMSCCP_Packet           *errorPacket;
@property(readwrite,atomic,strong)  NSArray<UMSCCP_Packet *>*errorPacketSegments;
@property(readwrite,atomic,assign)  BOOL                    deliverLocal;
@property(readwrite,atomic,assign)  BOOL                    errorDestinationLocal;
@property(readwrite,atomic,assign)  BOOL                    reportStatus;
@property(readwrite,atomic,assign)  BOOL                    swallow;
@property(readwrite,atomic,assign)  BOOL                    drop;
@property(readwrite,atomic,assign)  BOOL                    processRouting;
@property(readwrite,atomic,strong)  NSNumber                *cause;
@property(readwrite,atomic,strong)  SccpDestinationGroup    *destinationGroup;
@property(readwrite,atomic,strong)  NSString                *outgoingLinksetName;
@property(readwrite,atomic,strong)  UMMTP3PointCode         *outgoingDpc;
@property(readwrite,atomic,strong)  NSNumber                *outgoingSlc;
@property(readwrite,atomic,strong)  UMSCCP_Packet           *packetToDeliver;
@property(readwrite,atomic,strong)  NSArray<UMSCCP_ReceivedSegment *>*packetSegmentsToDeliver;
@property(readwrite,atomic,assign)  UMMTP3_Error            mtp3DeliveryError;
@property(readwrite,atomic,assign)  BOOL                    skipRouting;
@property(readwrite,atomic,strong)  SccpDestinationGroup    *forcedDestinationGroup;
@property(readwrite,atomic,strong)  NSString                *forcedDestinationName;
@property(readwrite,atomic,strong)  NSString                *forcedLinkset;
@property(readwrite,atomic,strong)  UMMTP3PointCode         *forcedDpc;
@property(readwrite,atomic,assign) BOOL                     mustResegment;
@property(readwrite,atomic,assign) UMSCCP_TcapSharing_result tcapSharingResult;
@property(readwrite,atomic,strong) NSMutableString         *routingTestDebug;


- (BOOL)forceRouted;
- (UMSynchronizedSortedDictionary *)objectValue;
@end

