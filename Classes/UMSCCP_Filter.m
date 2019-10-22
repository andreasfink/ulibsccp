//
//  UMSCCP_Filter.m
//  ulibsccp
//
//  Created by Andreas Fink on 11.01.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_Filter.h"


int         plugin_init(NSDictionary *dict);
int         plugin_exit(void);
NSString *  plugin_name(void);
UMPlugin *  plugin_create(void);
NSDictionary *plugin_info(void);



@implementation UMSCCP_Filter


- (NSError *)setConfigFileName:(NSString *)configFileName
{
    return [self loadConfigFromFile:_filterConfigFileName];
}



- (NSError *)setConfigString:(NSString *)str
{
    return [self loadConfigFromFile:_filterConfigFileName];
}



- (NSError *)loadConfigFromFile:(NSString *)filename
{
    NSError *e = NULL;
    NSString *str = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:&e];
    if(e)
    {
        NSLog(@"Can not read config from file %@. Error %@",filename,e);
        return e;
    }
    [self processConfig:str error:&e];
    if(e)
    {
        NSLog(@"Error while reading config file %@ %@",filename,e);
    }
    else
    {
        _filterConfigString = str;
        _filterConfigFile = str;
    }
    return e;
}

- (NSError *)loadConfigFromString:(NSString *)str
{
    NSError *e = NULL;
    [self processConfig:str error:&e];
    if(e)
    {
        NSLog(@"Error processing config string %@ %@",str,e);
    }
    else
    {
        _filterConfigString = str;
    }
    return e;
}

- (void)processConfig:(NSString *)str error:(NSError **)e
{
}

- (void)activate
{
    _isActive = YES;
}

- (void)deactivate
{
    _isActive = NO;
}

-(BOOL)isActive
{
    return _isActive;
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


int plugin_init(NSDictionary *dict)
{
    return 0;
}

int plugin_exit(void)
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



