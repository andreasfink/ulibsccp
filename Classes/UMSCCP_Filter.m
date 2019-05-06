//
//  UMSCCP_Filter.m
//  ulibsccp
//
//  Created by Andreas Fink on 11.01.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_Filter.h"


int         plugin_init(void);
int         plugin_exit(void);
NSString *  plugin_name(void);
UMPlugin *  plugin_create(void);
NSDictionary *plugin_info(void);



@implementation UMSCCP_Filter



- (UMSCCP_Filter *)initWithConfigFile:(NSString *)configFileName
{
    self = [super init];
    if(self)
    {
        _filterConfigFile = configFileName;
        [self processConfigFile];
    }
    return self;
}

- (void)activate
{
    _isActive = YES;
}

- (void)deactivate
{
    _isActive = NO;
}

- (void)processConfigFile
{
}


- (NSString *)filterName
{
    return @"undefined";
}

- (NSString *)filterDescription
{
    return @"undefined";
}


- (UMSCCP_FilterResult) filterInbound:(UMSCCP_Packet *)packet;
{
	return UMSCCP_FILTER_RESULT_UNMODIFIED;
}

- (UMSCCP_FilterResult) filterOutbound:(UMSCCP_Packet *)packet;
{
	return UMSCCP_FILTER_RESULT_UNMODIFIED;
}

- (UMSCCP_FilterResult) filterFromLocalSubsystem:(UMSCCP_Packet *)packet
{
	return UMSCCP_FILTER_RESULT_UNMODIFIED;
}
- (UMSCCP_FilterResult) filterToLocalSubsystem:(UMSCCP_Packet *)packet
{
	return UMSCCP_FILTER_RESULT_UNMODIFIED;
}

@end


int         plugin_init(void)
{
    return 0;
}

int         plugin_exit(void)
{
    return 0;
}

NSString *  plugin_name(void)
{
    return @"sccp-filter";
}

UMPlugin *  plugin_create(void)
{
    UMPlugin *plugin = [[UMSCCP_Filter alloc]init];
    return plugin;
}

NSDictionary *plugin_info(void)
{
    return @{ @"name" : @"sccp-filter" };
}



