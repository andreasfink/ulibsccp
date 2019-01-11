//
//  UMSCCP_Filter.h
//  ulibsccp
//
//  Created by Andreas Fink on 11.01.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibgt/ulibgt.h>
#import "UMSCCP_Packet.h"

#define	UMSCCP_FILTER_RESULT_UNMODIFIED	0x00
#define	UMSCCP_FILTER_RESULT_MODIFIED	0x01	/* flag to indicate it has been altered */
#define	UMSCCP_FILTER_RESULT_MONITOR	0x02	/* flag to send a copy to monitor 		*/
#define	UMSCCP_FILTER_RESULT_DROP		0x04	/* dont process 						*/
#define	UMSCCP_FILTER_RESULT_STATUS		0x08	/* send UDTS / XUDTS etc 				*/

typedef int UMSCCP_FilterResult; /* bitmask */


@interface UMSCCP_Filter : UMObject

- (UMSCCP_FilterResult) filterInbound:(UMSCCP_Packet *)packet;
- (UMSCCP_FilterResult) filterOutbound:(UMSCCP_Packet *)packet;
- (UMSCCP_FilterResult) filterFromLocalSubsystem:(UMSCCP_Packet *)packet;
- (UMSCCP_FilterResult) filterToLocalSubsystem:(UMSCCP_Packet *)packet;

@end

