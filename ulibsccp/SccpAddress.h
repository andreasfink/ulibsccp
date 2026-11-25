//
//  SccpAddress.h
//  ulibgt
//
//  Created by Andreas Fink on 24.03.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulibmtp3/ulibmtp3.h>

#import <ulibsccp/SccpAddressIndicator.h>
#import <ulibsccp/SccpNatureOfAddressIndicator.h>
#import <ulibsccp/SccpTypeOfNumberIndicator.h>
#import <ulibsccp/SccpNumberPlanIndicator.h>
#import <ulibsccp/SccpSubSystemNumber.h>
#import <ulibsccp/SccpTranslationTableNumber.h>
#import <ulibsccp/SccpVariant.h>

typedef enum SccpAddress_TAG_enum
{
    SccpAddress_TAG_AI          = 1,
    SccpAddress_TAG_NAI         = 2,
    SccpAddress_TAG_NPI         = 3,
    SccpAddress_TAG_SSN         = 4,
    SccpAddress_TAG_TT          = 5,
    SccpAddress_TAG_ADDRESS     = 6,
    SccpAddress_TAG_PC          = 7,
    SccpAddress_TAG_ENCODING    = 8,
} SccpAddress_TAG_enum;

@interface SccpAddress : UMASN1Sequence
{
    SccpAddressIndicator            *_ai;
    SccpNatureOfAddressIndicator    *_nai;
    SccpNumberPlanIndicator         *_npi;
    SccpSubSystemNumber             *_ssn;
    SccpTranslationTableNumber      *_tt;
    NSString                        *_address;
    UMMTP3PointCode                 *_pc;
    NSNumber                        *_encodingScheme;
}

#define MAX_SCCP_DIGITS 64


@property(readwrite,strong)     SccpAddressIndicator            *ai;
@property(readwrite,strong)     SccpNatureOfAddressIndicator    *nai;
@property(readwrite,strong)     SccpNumberPlanIndicator         *npi;
@property(readwrite,strong)     SccpSubSystemNumber             *ssn;
@property(readwrite,strong)     SccpTranslationTableNumber      *tt;
@property(readwrite,strong)     NSString                        *address;
@property(readwrite,strong)     UMMTP3PointCode                 *pc;
@property(readwrite,strong)     NSNumber                        *encodingScheme;

- (void)setAiFromInt:(int)i;
- (void)setNaiFromInt:(int)i;
- (void)setNpiFromInt:(int)i;
- (void)setSsnFromInt:(int)i;
- (void)setTtFromInt:(int)i;
- (NSData *)encode:(SccpVariant) variant;
- (NSData *)encoded;
- (void)decodeItu:(NSData *)d;
- (void)decodeAnsi:(NSData *)d;
- (SccpAddress *)initWithItuData:(NSData *)data;
- (SccpAddress *)initWithAnsiData:(NSData *)data;
- (SccpAddress *)initWithData:(NSData *)data;

- (SccpAddress *)initWithHumanReadableString:(NSString *)msisdn variant:(UMMTP3Variant)var;
- (SccpAddress *)initWithHumanReadableString:(NSString *)msisdn sccpVariant:(SccpVariant)svar mtp3Variant:(UMMTP3Variant)m3var;
- (NSString *)country;

- (NSDictionary *)dictionaryValue;
- (UMSynchronizedSortedDictionary *)objectValue;
- (NSString *)debugDescription;

- (SccpAddress *)anyAddress;
+ (SccpAddress *)anyAddress;
- (SccpAddress *)anySsnAddress;

- (NSString *)stringValueE164;
- (id)proxyForJson;
@end

int sccp_digit_to_nibble(unichar digit, int def);
