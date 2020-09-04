//
//  UMSCCP_StatisticDbRecord.h
//  ulibsccp
//
//  Created by Andreas Fink on 01.06.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibdb/ulibdb.h>

@interface UMSCCP_StatisticDbRecord : UMObject
{
    NSString *_ymdh;
    NSString *_instance;
    NSString *_incoming_linkset;
    NSString *_outgoing_linkset;
    
    int _incoming_pc;
    int _outgoing_pc;
    NSString *_destination;

    NSString *_calling_prefix;
    NSString *_called_prefix;
    NSString *_gtt_selector;
    NSString *_sccp_operation;
    int     _msu_count;
    int     _bytes_count;
    UMMutex *_lock;
}


@property(readwrite,strong,atomic)  NSString *ymdh;
@property(readwrite,strong,atomic)  NSString *instance;
@property(readwrite,strong,atomic)  NSString *incoming_linkset;
@property(readwrite,strong,atomic)  NSString *outgoing_linkset;
@property(readwrite,strong,atomic)  NSString *calling_prefix;
@property(readwrite,strong,atomic)  NSString *called_prefix;
@property(readwrite,strong,atomic)  NSString *gtt_selector;
@property(readwrite,strong,atomic)  NSString *sccp_operation;
@property(readwrite,assign,atomic)  int     msu_count;
@property(readwrite,assign,atomic)  int     bytes_count;
@property(readwrite,assign,atomic)  int     incoming_pc;
@property(readwrite,assign,atomic)  int     outgoing_pc;
@property(readwrite,strong,atomic)  NSString *destination;

- (NSString *)keystring;
+ (NSString *)keystringFor:(NSString *)ymdh
  incomingLinkset:(NSString *)incomingLinkset
  outgoingLinkset:(NSString *)outgoingLinkset
    callingPrefix:(NSString *)callingPrefix
     calledPrefix:(NSString *)calledPrefix
      gttSelector:(NSString *)selector
    sccpOperation:(NSString *)sccpOperation
         instance:(NSString *)instance
incomingPointCode:(int)opc
outgoingPointCode:(int)dpc
      destination:(NSString *)dst;

- (void)increaseMsuCount:(int)msuCount byteCount:(int)byteCount;
- (void)flushToPool:(UMDbPool *)pool table:(UMDbTable *)table;

//- (BOOL)insertIntoDb:(UMDbPool *)pool table:(UMDbTable *)dbt; /* returns YES on success */
//- (BOOL)updateDb:(UMDbPool *)pool table:(UMDbTable *)dbt /* returns YES on success */

@end
