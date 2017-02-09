//
//  UMSCCP_dpcAvailability.h
//  ulibsccp
//
//  Created by Andreas Fink on 05.04.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibmtp3/ulibmtp3.h>

typedef enum UMSCCP_dpcAvailabilityStatus
{
    UMSCCP_dpcAvailabe      = 1,
    UMSCCP_dpcUnavailabe    = 2,
    UMSCCP_dpcCongested     = 3,
    UMSCCP_dpcRestricted    = 4,
} UMSCCP_dpcAvailabilityStatus;

@interface UMSCCP_dpcAvailability : UMObject
{
    UMMTP3PointCode *pc;
    UMSCCP_dpcAvailabilityStatus status;
    int congestionLevel;
}

@property(readwrite,strong) UMMTP3PointCode *pc;
@property(readwrite,assign) UMSCCP_dpcAvailabilityStatus status;
@property(readwrite,assign) int congestionLevel;

@end
