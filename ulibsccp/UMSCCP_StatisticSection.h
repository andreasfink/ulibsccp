//
//  UMSCCP_StatisticSection.h
//  ulibsccp
//
//  Created by Andreas Fink on 28.10.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

typedef enum UMSCCP_StatisticSection
{
    UMSCCP_StatisticSection_RX,
    UMSCCP_StatisticSection_TX,
    UMSCCP_StatisticSection_TRANSIT,
    UMSCCP_StatisticSection_UDT_RX,
    UMSCCP_StatisticSection_UDTS_RX,
    UMSCCP_StatisticSection_XUDT_RX,
    UMSCCP_StatisticSection_XUDTS_RX,
    UMSCCP_StatisticSection_LUDT_RX,
    UMSCCP_StatisticSection_LUDTS_RX,
    UMSCCP_StatisticSection_UDT_TX,
    UMSCCP_StatisticSection_UDTS_TX,
    UMSCCP_StatisticSection_XUDT_TX,
    UMSCCP_StatisticSection_XUDTS_TX,
    UMSCCP_StatisticSection_LUDT_TX,
    UMSCCP_StatisticSection_LUDTS_TX,
    UMSCCP_StatisticSection_UDT_TRANSIT,
    UMSCCP_StatisticSection_UDTS_TRANSIT,
    UMSCCP_StatisticSection_XUDT_TRANSIT,
    UMSCCP_StatisticSection_XUDTS_TRANSIT,
    UMSCCP_StatisticSection_LUDT_TRANSIT,
    UMSCCP_StatisticSection_LUDTS_TRANSIT,
    UMSCCP_StatisticSection_MAX,
} UMSCCP_StatisticSection;


