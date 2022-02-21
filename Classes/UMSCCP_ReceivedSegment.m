//
//  UMSCCP_ReceivedSegment.m
//  ulibsccp
//
//  Created by Andreas Fink on 16.02.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_ReceivedSegment.h"
#import "UMSCCP_Packet.h"

@implementation UMSCCP_ReceivedSegment


- (NSString *)key
{
    return [NSString stringWithFormat:@"%@/%@/%06lx", src.stringValueE164, dst.stringValueE164,ref];
}

- (UMSynchronizedSortedDictionary *)jsonObject
{
    UMSynchronizedSortedDictionary *r = [[UMSynchronizedSortedDictionary alloc]init];
    if(_src)
    {
        r[@"src"] = _src;
    }
    if(_dst)
    {
        r[@"dst"] = _dst;
    }
    if(_opc)
    {
        r[@"opc"] = _opc;
    }
    if(_dpc)
    {
        r[@"dpc"] = _dpc;
    }
    r[@"reference"] = @(_reference);
    r[@"sls"] = @(_sls);
    r[@"max"] = @(_max);
    r[@"service-class"] = @(_pclass);
    r[@"handling"] = @(_handling);
    r[@"hop-count"] = @(_hopCount);
    if(_optionsData)
    {
        r[@"options-data"] = _optionsData;
    }
    if(_options)
    {
        r[@"options"] = _options;
    }
    return r;
}


@end

