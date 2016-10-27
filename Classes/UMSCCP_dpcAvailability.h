//
//  UMSCCP_dpcAvailability.h
//  ulibsccp
//
//  Created by Andreas Fink on 05.04.16.
//  Copyright (c) 2016 Andreas Fink
//

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
