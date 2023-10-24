//
//  UMSCCP_Filter.h
//  ulibsccp
//
//  Created by Andreas Fink on 11.01.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibgt/ulibgt.h>
#import <ulibsccp/UMSCCP_Packet.h>
#import <ulibsccp/UMSCCP_FilterProtocol.h>

@class UMSCCP_Packet;

@interface UMSCCP_Filter : UMPlugin
{
    NSString    *_filterConfigFileName;
    NSString    *_filterConfigString;
    BOOL        _isActive;
}

@property(readwrite,strong,atomic)      NSString *filterConfigFile;

- (NSString *)filterName;
- (NSString *)filterDescription;
- (NSError *)setConfigFileName:(NSString *)configFileName;
- (NSError *)setConfigString:(NSString *)config;

- (NSError *)loadConfigFromFile:(NSString *)filename;
- (NSError *)loadConfigFromString:(NSString *)str;
- (BOOL)processConfig:(NSString *)str error:(NSError **)e;

- (void)activate;
- (void)deactivate;
- (BOOL)isActive;

- (UMSCCP_FilterResult) filterInbound:(UMSCCP_Packet *)packet; /* from MTP3 link */
- (UMSCCP_FilterResult) filterOutbound:(UMSCCP_Packet *)packet; /* to MTP3 link */
- (UMSCCP_FilterResult) filterFromLocalSubsystem:(UMSCCP_Packet *)packet; /* from local MTP3 user */
- (UMSCCP_FilterResult) filterToLocalSubsystem:(UMSCCP_Packet *)packet; /* to local MTP3 user */

@end

/* Note: the final subclass must implement the following C functions to work as plugins

 int         plugin_init(void);
 int         plugin_exit(void);
 NSString *  plugin_name(void);
 UMPlugin *  plugin_create(void);
 NSDictionary *plugin_info(void);

 */
