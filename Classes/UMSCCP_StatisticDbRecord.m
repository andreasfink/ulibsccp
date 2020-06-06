//
//  UMSCCP_StatisticDbRecord.m
//  ulibsccp
//
//  Created by Andreas Fink on 01.06.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_StatisticDbRecord.h"
#import <ulibdb/ulibdb.h>

//#define UMSCCP_STATISTICS_DEBUG 1

@implementation UMSCCP_StatisticDbRecord

- (UMSCCP_StatisticDbRecord *)init
{
    self = [super init];
    if(self)
    {
        _lock = [[UMMutex alloc]initWithName:@"UMSCCP_StatisticDbRecord-lock"];
    }
    return self;
}

- (NSString *)keystring
{
    
    return [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@:%@:%@",_ymdh,_incoming_linkset,_calling_prefix,_outgoing_linkset,_called_prefix,_gtt_selector,_sccp_operation,_instance];

}

+ (NSString *)keystringFor:(NSString *)ymdh
           incomingLinkset:(NSString *)incomingLinkset
           outgoingLinkset:(NSString *)outgoingLinkset
             callingPrefix:(NSString *)callingPrefix
              calledPrefix:(NSString *)calledPrefix
               gttSelector:(NSString *)selector
             sccpOperation:(NSString *)sccpOperation
                  instance:(NSString *)instance
{
    return [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@:%@:%@",ymdh,incomingLinkset,callingPrefix,outgoingLinkset,calledPrefix,selector,sccpOperation,instance];
}

- (BOOL)insertIntoDb:(UMDbPool *)pool table:(UMDbTable *)dbt /* returns YES on success */
{
    BOOL success = NO;
    @autoreleasepool
    {
        @try
        {
            [_lock lock];
            UMDbQuery *query = [UMDbQuery queryForFile:__FILE__ line: __LINE__];
            if(![query isInCache])
            {
                NSArray *fields = @[
                                    @"dbkey",
                                    @"ymdh",
                                    @"instance",
                                    @"incoming_linkset",
                                    @"outgoing_linkset",
                                    @"calling_prefix",
                                    @"called_prefix",
                                    @"gtt_selector",
                                    @"sccp_operation",
                                    @"msu_count",
                                    @"bytes_count"];
                [query setType:UMDBQUERYTYPE_INSERT];
                [query setTable:dbt];
                [query setFields:fields];
                [query addToCache];
            }
            NSString *key = [self keystring];
            NSArray *params  = [NSArray arrayWithObjects:
                                STRING_NONEMPTY(key),
                                STRING_NONEMPTY(_ymdh),
                                STRING_NONEMPTY(_instance),
                                STRING_NONEMPTY(_incoming_linkset),
                                STRING_NONEMPTY(_outgoing_linkset),
                                STRING_NONEMPTY(_calling_prefix),
                                STRING_NONEMPTY(_called_prefix),
                                STRING_NONEMPTY(_gtt_selector),
                                STRING_NONEMPTY(_sccp_operation),
                                STRING_FROM_INT(_msu_count),
                                STRING_FROM_INT(_bytes_count),
                                NULL];
            UMDbSession *session = [pool grabSession:FLF];
            unsigned long long affectedRows = 0;
            success = [session cachedQueryWithNoResult:query parameters:params allowFail:YES primaryKeyValue:key affectedRows:&affectedRows];
#if defined(UMSCCP_STATISTICS_DEBUG)
            if(success==NO)
            {
                NSLog(@"Insert SQL failed: %@",query.lastSql);
            }
            else
            {
                NSLog(@"Insert SQL success: %@",query.lastSql);
            }
#endif
            [session.pool returnSession:session file:FLF];
        }
        @catch (NSException *e)
        {
            NSLog(@"Exception: %@",e);
        }
        @finally
        {
            [_lock unlock];
        }
    }
    return success;
}

- (BOOL)updateDb:(UMDbPool *)pool table:(UMDbTable *)dbt /* returns YES on success */
{
    BOOL success = NO;
    @autoreleasepool
    {
        @try
        {
            [_lock lock];
            
            UMDbQuery *query = [UMDbQuery queryForFile:__FILE__ line: __LINE__];
            if(![query isInCache])
            {
                [query setType:UMDBQUERYTYPE_INCREASE_BY_KEY];
                [query setTable:dbt];
                [query setFields:@[@"msu_count",@"bytes_count"]];
                [query setPrimaryKeyName:@"dbkey"];
                [query addToCache];
            }
            NSArray *params = [NSArray arrayWithObjects:
                                [NSNumber numberWithInt:_msu_count],
                                [NSNumber numberWithInt:_bytes_count],
                                 NULL];
            NSString *key = [self keystring];
            UMDbSession *session = [pool grabSession:FLF];
            success = [session cachedQueryWithNoResult:query parameters:params allowFail:YES primaryKeyValue:key];
#if defined(UMSCCP_STATISTICS_DEBUG)
            if(success==NO)
            {
                NSLog(@"Update SQL failed: %@",query.lastSql);
            }
            else
            {
                NSLog(@"Update SQL success: %@",query.lastSql);
            }
#endif
            [session.pool returnSession:session file:FLF];
        }
        @catch (NSException *e)
        {
            NSLog(@"Exception: %@",e);
        }
        @finally
        {
            [_lock unlock];
        }
    }
    return success;
}

- (void)increaseMsuCount:(int)msuCount byteCount:(int)byteCount
{
    [_lock lock];
    _msu_count += msuCount;
    _bytes_count += byteCount;
    [_lock unlock];
}

- (void)flushToPool:(UMDbPool *)pool table:(UMDbTable *)table
{
#if defined(UMSCCP_STATISTICS_DEBUG)
    NSLog(@"UMSCCP_STATISTICS_DEBUG: flushToPool:%@ table:%@",pool.poolName,table.tableName);
#endif

    [_lock lock];
    BOOL success = [self updateDb:pool table:table];
    if(success == NO)
    {
#if defined(UMSCCP_STATISTICS_DEBUG)
        NSLog(@"UMSCCP_STATISTICS_DEBUG: trying insert instead\n");
#endif
        if([self insertIntoDb:pool table:table])
        {
            _msu_count = 0;
            _bytes_count = 0;
        }
    }
    [_lock unlock];
}


- (id)proxyForJson
{
    UMSynchronizedSortedDictionary *d = [[UMSynchronizedSortedDictionary alloc]init];
    d[@"_ymdh"]             = _ymdh ? _ymdh : @"(null)";
    d[@"_instance"]         = _instance ? _instance : @"(null)";
    d[@"_incoming_linkset"] = _incoming_linkset ? _incoming_linkset : @"(null)";
    d[@"_outgoing_linkset"] = _outgoing_linkset ? _outgoing_linkset : @"(null)";
    d[@"_calling_prefix"]   = _calling_prefix ? _calling_prefix : @"(null)";
    d[@"_gtt_selector"]     = _gtt_selector ? _gtt_selector : @"(null)";
    d[@"_sccp_operation"]   = _sccp_operation ? _sccp_operation : @"(null)";
    d[@"_msu_count"]        = @(_msu_count);
    d[@"_bytes_count"]      = @(_bytes_count);
    return d;
}
@end
