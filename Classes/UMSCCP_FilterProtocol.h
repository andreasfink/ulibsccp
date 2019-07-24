//
//  UMSCCP_FilterProtocol.h
//  ulibsccp
//
//  Created by Andreas Fink on 24.07.2019.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibgt/ulibgt.h>

@class UMSCCP_Packet;


#define    UMSCCP_FILTER_RESULT_UNMODIFIED      0x00
#define    UMSCCP_FILTER_RESULT_MODIFIED        0x01    /* flag to indicate it has been altered */
#define    UMSCCP_FILTER_RESULT_MONITOR         0x02    /* flag to send a copy to monitor         */
#define    UMSCCP_FILTER_RESULT_DROP            0x04    /* dont process                         */
#define    UMSCCP_FILTER_RESULT_STATUS          0x08    /* send UDTS / XUDTS etc                 */
#define    UMSCCP_FILTER_RESULT_CAN_NOT_DECODE  0x10    /* set if the filter has problems decoding   */
#define    UMSCCP_FILTER_RESULT_ADD_TO_TRACE1   0x20    /* set if the filter has problems decoding   */
#define    UMSCCP_FILTER_RESULT_ADD_TO_TRACE2   0x40    /* set if the filter has problems decoding   */
#define    UMSCCP_FILTER_RESULT_ADD_TO_TRACE3   0x80    /* set if the filter has problems decoding   */
#define    UMSCCP_FILTER_RESULT_ADD_TO_TRACEFILE_CAN_NOT_DECODE   0x100    /* set if the filter has problems decoding   */


typedef enum UMSCCP_FilterMatchResult
{
    UMSCCP_FilterMatchResult_does_not_match = 0,
    UMSCCP_FilterMatchResult_does_match = 1,
    UMSCCP_FilterMatchResult_untested = 2,
} UMSCCP_FilterMatchResult;

typedef int UMSCCP_FilterResult; /* bitmask */


@protocol UMSCCP_FilterProtocol


- (NSString *)filterName;
- (NSString *)filterDescription;
- (void)activate;
- (void)deactivate;
- (BOOL)isActive;

- (UMSCCP_FilterResult) filterInbound:(UMSCCP_Packet *)packet; /* from MTP3 link */
- (UMSCCP_FilterResult) filterOutbound:(UMSCCP_Packet *)packet; /* to MTP3 link */
- (UMSCCP_FilterResult) filterFromLocalSubsystem:(UMSCCP_Packet *)packet; /* from local MTP3 user */
- (UMSCCP_FilterResult) filterToLocalSubsystem:(UMSCCP_Packet *)packet; /* to local MTP3 user */

@end
