//
//  UMSCCP_Defs.h
//  ulibsccp
//
//  Created by Andreas Fink on 01.04.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

typedef enum SCCP_ServiceClass
{
    SCCP_CLASS_BASIC = 				0,
    SCCP_CLASS_INSEQ_CL = 			1,
    SCCP_CLASS_BASIC_CO = 			2,
    SCCP_CLASS_FLOW_CONTROL_CO = 	3,
} SCCP_ServiceClass;

typedef enum SCCP_ServiceType
{
    SCCP_UDT				= 		0x09,
    SCCP_UDTS				= 		0x0A,
    SCCP_XUDT				= 		0x11,
    SCCP_XUDTS				= 		0x12,
    SCCP_LUDT				= 		0x13,
    SCCP_LUDTS				= 		0x14,
} SCCP_ServiceType;


typedef	enum SCCP_State
{
    SCCP_STATE_IDLE								= 0,
    SCCP_STATE_DATA_TRANSFER					= 1,
    SCCP_STATE_INCOMING_CONNECTION_PENDING		= 2,
    SCCP_STATE_PROVIDER_INITIATED_RESET_PENDING	= 3,
    SCCP_STATE_OUTGOING_CONNECTION_PENDING		= 4,
    SCCP_STATE_USER_REQUEST_RESET_PENDING		= 5,
} SCCP_State;


#define UMSCCP_HANDLING_RETURN_ON_ERROR 0x08

typedef enum SCCP_ReturnCause
{
    SCCP_ReturnCause_NoTranslationForAnAddressOfSuchNature   = 0,
    SCCP_ReturnCause_NoTranslationForThisSpecificAddress    = 1,
    SCCP_ReturnCause_SubsystemCongestion    = 2,
    SCCP_ReturnCause_SubsystemFailure    = 3,
    SCCP_ReturnCause_Unequipped = 4,
    SCCP_ReturnCause_MTPFailure = 5,
    SCCP_ReturnCause_NetworkCongestion = 6,
    SCCP_ReturnCause_Unqualified = 7,
    SCCP_ReturnCause_ErrorInMessageTransport = 8,
    SCCP_ReturnCause_ErrorInLocalProcessing = 9,
    SCCP_ReturnCause_DestinationCannotPerformReassembly = 10,
    SCCP_ReturnCause_SCCPFailure = 11,
    SCCP_ReturnCause_HopCounterViolation = 12,
    SCCP_ReturnCause_SegmentationNotSupported = 13,
    SCCP_ReturnCause_SegmentationFailure = 14,
} SCCP_ReturnCause;
#define	SCCP_CLASS_BASIC	0

