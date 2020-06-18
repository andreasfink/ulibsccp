//
//  UMSCCP_StatisticDb.h
//  ulibsccp
//
//  Created by Andreas Fink on 01.06.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibdb/ulibdb.h>
#import "UMLayerSCCPApplicationContextProtocol.h"
#import "UMSCCP_Defs.h"

@class UMDigitTree;

@interface UMSCCP_StatisticDb : UMObject
{
    UMDbPool *_pool;
    UMDbTable *_table;
    UMMutex *_lock;
    UMSynchronizedDictionary *_entries;
    NSDateFormatter *_ymdhDateFormatter;
    NSString *_instance;
    NSString *_poolName;

    UMSynchronizedDictionary *_e164;
    UMSynchronizedDictionary *_e212;
    UMSynchronizedDictionary *_e214;
}

- (UMSCCP_StatisticDb *)initWithPoolName:(NSString *)pool
                              tableName:(NSString *)table
                             appContext:(id<UMLayerSCCPApplicationContextProtocol>)appContext
                             autocreate:(BOOL)autocreate
                               instance:(NSString *)instance;

- (void)addByteCount:(int)byteCount
     incomingLinkset:(NSString *)incomingLinkset
     outgoingLinkset:(NSString *)outgoingLinkset
       callingPrefix:(NSString *)callingPrefix
        calledPrefix:(NSString *)calledPrefix
         gttSelector:(NSString *)selector
       sccpOperation:(SCCP_ServiceType)sccpOperation;

- (void)doAutocreate;
- (void)flush;

- (void)addE164prefix:(NSString *)prefix;
- (void)addE212prefix:(NSString *)prefix;
- (void)addE214prefix:(NSString *)prefix;
- (NSString *)e164prefixOf:(NSString *)in;
- (NSString *)e212prefixOf:(NSString *)in;
- (NSString *)e214prefixOf:(NSString *)in;

- (NSArray *)listPrefixesE164;
- (NSArray *)listPrefixesE212;
- (NSArray *)listPrefixesE214;

@end

