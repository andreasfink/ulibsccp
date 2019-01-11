//
//  UMSCCP_Filter.m
//  ulibsccp
//
//  Created by Andreas Fink on 11.01.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_Filter.h"

@implementation UMSCCP_Filter
{

}

- (UMSCCP_FilterResult) filterInbound:(UMSCCP_Packet *)packet;
{
	return UMSCCP_FILTER_RESULT_UNMODIFIED;
}

- (UMSCCP_FilterResult) filterOutbound:(UMSCCP_Packet *)packet;
{
	return UMSCCP_FILTER_RESULT_UNMODIFIED;
}

- (UMSCCP_FilterResult) filterFromLocalSubsystem:(UMSCCP_Packet *)packet
{
	return UMSCCP_FILTER_RESULT_UNMODIFIED;
}
- (UMSCCP_FilterResult) filterToLocalSubsystem:(UMSCCP_Packet *)packet
{
	return UMSCCP_FILTER_RESULT_UNMODIFIED;
}

@end
