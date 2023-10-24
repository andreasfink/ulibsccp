//
//  UMSCCP_StatisticSection.h
//  ulibsccp
//
//  Created by Andreas Fink on 28.10.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

typedef enum UMSCCP_StatisticSection
{
    UMSCCP_StatisticSection_RX = 0,
    UMSCCP_StatisticSection_TX = 1,
    UMSCCP_StatisticSection_TRANSIT = 2,
    UMSCCP_StatisticSection_UDT_RX= 3,
    UMSCCP_StatisticSection_UDTS_RX = 4,
    UMSCCP_StatisticSection_XUDT_RX= 5,
    UMSCCP_StatisticSection_XUDTS_RX = 6,
    UMSCCP_StatisticSection_UDT_TX= 7,
    UMSCCP_StatisticSection_UDTS_TX = 8,
    UMSCCP_StatisticSection_XUDT_TX= 9,
    UMSCCP_StatisticSection_XUDTS_TX = 10,
    UMSCCP_StatisticSection_UDT_TRANSIT= 11,
    UMSCCP_StatisticSection_UDTS_TRANSIT = 12,
    UMSCCP_StatisticSection_XUDT_TRANSIT= 13,
    UMSCCP_StatisticSection_XUDTS_TRANSIT = 14,
} UMSCCP_StatisticSection;

#define UMSCCP_StatisticSection_MAX 15

