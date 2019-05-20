//
//  UMSCCP_Packet.m
//  ulibsccp
//
//  Created by Andreas Fink on 11.01.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_Packet.h"

@implementation UMSCCP_Packet

- (UMSCCP_Packet *)init
{
	self = [super init];
	if(self)
	{
		_created = [NSDate date];
        _tags = [[UMSynchronizedDictionary alloc]init];
	}
	return self;
}


-(NSString *)incomingPacketType
{
    switch(_incomingServiceType)
    {
        case SCCP_UDT:
            return @"udt";
        case SCCP_UDTS:
            return @"udts";
        case SCCP_XUDT:
            return @"xudt";
        case SCCP_XUDTS:
            return @"xudts";
        case SCCP_LUDT:
            return @"ludt";
        case SCCP_LUDTS:
            return @"ludts";
        default:
            return [NSString stringWithFormat:@"%d",_incomingServiceType];
    }
}

-(NSString *)outgoingPacketType
{
    switch(_outgoingServiceType)
    {
        case SCCP_UDT:
            return @"udt";
        case SCCP_UDTS:
            return @"udts";
        case SCCP_XUDT:
            return @"xudt";
        case SCCP_XUDTS:
            return @"xudts";
        case SCCP_LUDT:
            return @"ludt";
        case SCCP_LUDTS:
            return @"ludts";
        default:
            return [NSString stringWithFormat:@"%d",_outgoingServiceType];
    }
}

- (void)copyIncomingToOutgoing
{
    _outgoingLocalUser              = _incomingLocalUser;
    _outgoingMtp3Layer              = _incomingMtp3Layer;
    _outgoingLinkset                = _incomingLinkset;
    _outgoingOptions                = _incomingOptions;
    _outgoingOpc                    = _incomingOpc;
    _outgoingDpc                    = _incomingDpc;
    _outgoingServiceClass           = _incomingServiceClass;
    _outgoingServiceType            = _incomingServiceType;
    _outgoingReturnCause            = _incomingReturnCause;
    _outgoingHandling               = _incomingHandling;
    _outgoingMaxHopCount            = _incomingMaxHopCount - 1;
    _outgoingFromLocal              = _incomingFromLocal;
    _outgoingToLocal                = _incomingToLocal;
    _outgoingCallingPartyAddress    = _incomingCallingPartyAddress;
    _outgoingCalledPartyAddress     = _incomingCalledPartyAddress;
    _outgoingMtp3Data               = _incomingMtp3Data;
    _outgoingSccpData               = _incomingSccpData;
    _outgoingOptionalData           = _incomingOptionalData;
    _outgoingReturnCause            = _incomingReturnCause;
}


- (void)addTag:(NSString *)tag
{
    _tags[tag]=tag;
}

- (void)clearTag:(NSString *)tag
{
    [_tags removeObjectForKey:tag];
}

- (BOOL) hasTag:(NSString *)tag
{
    if(_tags[tag])
    {
        return YES;
    }
    return NO;
}

- (void)clearAllTags
{
    _tags = [[UMSynchronizedDictionary alloc] init];
}

@end
