//
//  UMSCCP_RoutingState.m
//  ulibsccp
//
//  Created by Andreas Fink on 15.07.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_RoutingState.h"
#import "UMSCCP_Packet.h"
#import "UMLayerSCCP.h"

@implementation UMSCCP_RoutingState

- (UMSCCP_RoutingState *)init
{
    self = [super init];
    if(self)
    {
        _processRouting = YES;
    }
    return self;
}

- (UMSynchronizedSortedDictionary *)objectValue
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc] init];
    if(_dpcForErrors)
    {
        dict[@"dpc-for-errors"] = _dpcForErrors.objectValue;
    }
    if(_opcForErrors)
    {
        dict[@"opc-for-errors"] = _opcForErrors.objectValue;
    }
    if(_linksetForErrors)
    {
        dict[@"linkset-for-errors"] = _linksetForErrors;
    }
    if(_slcForErrors)
    {
        dict[@"slc-for-errors"] = _slcForErrors;
    }
    if(_linkForErrors)
    {
        dict[@"link-for-errors"] = _linkForErrors.name;
    }
    if(_asForErrors)
    {
        dict[@"as-for-errors"] = _asForErrors.name;
    }
    if(_errorPacket)
    {
        dict[@"error-packet"] = _errorPacket;
    }
    if(_errorPacketSegments)
    {
        dict[@"error-packet-segments"] = _errorPacketSegments;
    }
    
    if(_deliverLocal)
    {
        dict[@"deliver-local"] = @(YES);
    }
    if(_reportStatus)
    {
        dict[@"report-status"] = @(YES);
    }
    if(_swallow)
    {
        dict[@"swallow"] = @(YES);
    }
    if(_drop)
    {
        dict[@"drop"] = @(YES);
    }
    if(_cause)
    {
        if(_cause.intValue!=SCCP_ReturnCause_not_set)
        {
            dict[@"cause"] = [NSString stringWithFormat:@"%@: %@",_cause,[UMLayerSCCP causeValueToString: _cause.intValue]];
        }
    }
    
    if(_destinationGroup)
    {
        dict[@"destination-group"] = _destinationGroup.name;
    }
    if(_outgoingLinksetName)
    {
        dict[@"outgoing-linkset-name"] = _outgoingLinksetName;
        
    }
    if(_outgoingDpc)
    {
        dict[@"outgoing-dpc"] = _outgoingDpc.objectValue;
    }
    if(_outgoingSlc)
    {
        dict[@"outgoing-slc"] = _outgoingSlc;
    }/*
    if(_packetToDeliver)
    {
        dict[@"packet-to-deliver"] = _packetToDeliver;
    }*/
    if(_packetSegmentsToDeliver)
    {
        dict[@"packet-segments-to-deliver"] = _packetSegmentsToDeliver;
    }
    if(_forcedDestinationGroup)
    {
        dict[@"forced-destination-group"] = _forcedDestinationGroup;
    }
    if(_forcedDestinationName)
    {
        dict[@"forced-destination"] = _forcedDestinationName;
    }
    if(_forcedLinkset)
    {
        dict[@"forced-linkset"] = _forcedLinkset;
    }
    if(_forcedDpc)
    {
        dict[@"forced-dpc"] = _forcedDpc.objectValue;
    }
    if(_mtp3DeliveryError != UMMTP3_no_error)
    {
        switch(_mtp3DeliveryError)
        {
            case  UMMTP3_error_pdu_too_big:
                dict[@"mtp3-delivery-error"] = @"pdu-too-big";
                break;
            case UMMTP3_error_no_route_to_destination:
                dict[@"mtp3-delivery-error"] = @"no-route-to-destination";
                break;
            case UMMTP3_error_invalid_variant:
                dict[@"mtp3-delivery-error"] = @"invalid-variant";
                break;
            case UMMTP3_error_unsupported_pdu_type:
                dict[@"mtp3-delivery-error"] = @"unsupported-pdu-type";
                break;
            case UMMTP3_error_internal_error:
                dict[@"mtp3-delivery-error"] = @"internal-error";
                break;
            default:
                break;
        }
    }
    switch(_status)
    {
        case UMSCCP_RoutingStatus_success:
            dict[@"status"] = @"success";
            break;
        case UMSCCP_RoutingStatus_failed:
            dict[@"status"] = @"failed";
            break;
        case UMSCCP_RoutingStatus_dropPacket:
            dict[@"status"] = @"dropped";
            break;
        case UMSCCP_RoutingStatus_awaitingSegments:
            dict[@"status"] = @"awaiting-segments";
            break;
    }

    return dict;
}

- (BOOL)forceRouted
{
    if(_forcedDestinationGroup || _forcedDestinationName || _forcedLinkset || _forcedDpc)
    {
        return YES;
    }
    return NO;
}
@end
