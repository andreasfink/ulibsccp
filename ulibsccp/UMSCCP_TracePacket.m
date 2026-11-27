//
//  UMSCCP_TracePacket.m
//  ulibsccp
//
//  Created by Andreas Fink on 25.11.2026.
//

#import "UMSCCP_TracePacket.h"
#import <ulibsccp/SccpAddress.h>

@implementation UMSCCP_TracePacket

- (void) processBeforeEncode
{
    [super processBeforeEncode];
    [_asn1_tag setTagIsConstructed];
    _asn1_list = [[NSMutableArray alloc]init];
    
    [self addNSString:_instanceName withContentSpecificTag:UMSCCP_TracePacket_Tag_instanceName];
    [self addNSString:_sccpInstanceName withContentSpecificTag:UMSCCP_TracePacket_Tag_sccpInstanceName];
    [self addNSString:_mtp3InstanceName withContentSpecificTag:UMSCCP_TracePacket_Tag_mtp3InstanceName];
    [self addNSDateAsString:_created withContentSpecificTag:UMSCCP_TracePacket_Tag_created];
    [self addNSString:_linksetName withContentSpecificTag:UMSCCP_TracePacket_Tag_linksetName];
    [self addNSString:_variant withContentSpecificTag:UMSCCP_TracePacket_Tag_variant];
    [self addIntegerNumber:_networkIndicator withContentSpecificTag:UMSCCP_TracePacket_Tag_networkIndicator];
    [self addIntegerNumber:_opc withContentSpecificTag:UMSCCP_TracePacket_Tag_opc];
    [self addIntegerNumber:_dpc withContentSpecificTag:UMSCCP_TracePacket_Tag_dpc];
    [self addNSString:_serviceClass withContentSpecificTag:UMSCCP_TracePacket_Tag_serviceClass];
    [self addNSString:_serviceType withContentSpecificTag:UMSCCP_TracePacket_Tag_serviceType];
    [self addNSString:_handling withContentSpecificTag:UMSCCP_TracePacket_Tag_handling];
    [self addIntegerNumber:_maxHopCount withContentSpecificTag:UMSCCP_TracePacket_Tag_maxHopCount];
    [self addObject:_callingPartyAddressBeforeTranslation withContentSpecificTag:UMSCCP_TracePacket_Tag_callingPartyAddressBeforeTranslation];
    [self addObject:_callingPartyAddress withContentSpecificTag:UMSCCP_TracePacket_Tag_callingPartyAddress];
    [self addNSString:_callingPartyCountry withContentSpecificTag:UMSCCP_TracePacket_Tag_callingPartyCountry];
    [self addNSString:_callingPartyPrefix withContentSpecificTag:UMSCCP_TracePacket_Tag_callingPartyPrefix];
    [self addObject:_calledPartyAddressBeforeTranslation withContentSpecificTag:UMSCCP_TracePacket_Tag_calledPartyAddressBeforeTranslation];
    [self addObject:_calledPartyAddress withContentSpecificTag:UMSCCP_TracePacket_Tag_calledPartyAddress];
    [self addNSString:_calledPartyCountry withContentSpecificTag:UMSCCP_TracePacket_Tag_calledPartyCountry];
    [self addNSString:_calledPartyPrefix withContentSpecificTag:UMSCCP_TracePacket_Tag_calledPartyPrefix];
    [self addNSData:_mtp3Data withContentSpecificTag:UMSCCP_TracePacket_Tag_mtp3Data];
    [self addNSData:_sccpData withContentSpecificTag:UMSCCP_TracePacket_Tag_sccpData];
    [self addNSData:_optionalData withContentSpecificTag:UMSCCP_TracePacket_Tag_optionalData];
    [self addNSString:_returnCause withContentSpecificTag:UMSCCP_TracePacket_Tag_returnCause];
    [self addNSString:_tcapType withContentSpecificTag:UMSCCP_TracePacket_Tag_tcapType];
    [self addNSString:_applicationContext withContentSpecificTag:UMSCCP_TracePacket_Tag_applicationContext];
    [self addNSString:_mapOperations withContentSpecificTag:UMSCCP_TracePacket_Tag_mapOperations];
    [self addNSString:_tcap_oid withContentSpecificTag:UMSCCP_TracePacket_Tag_tcap_oid];
    [self addNSString:_tcap_did withContentSpecificTag:UMSCCP_TracePacket_Tag_tcap_did];
    [self addNSString:_msisdn withContentSpecificTag:UMSCCP_TracePacket_Tag_msisdn];
    [self addNSString:_imsi withContentSpecificTag:UMSCCP_TracePacket_Tag_imsi];
    [self addNSString:_smsc withContentSpecificTag:UMSCCP_TracePacket_Tag_smsc];
    [self addNSString:_hlr withContentSpecificTag:UMSCCP_TracePacket_Tag_hlr];
    [self addNSString:_msc withContentSpecificTag:UMSCCP_TracePacket_Tag_msc];
    [self addNSString:_partsInfo withContentSpecificTag:UMSCCP_TracePacket_Tag_partsInfo];
    [self addNSString:_routingSelector withContentSpecificTag:UMSCCP_TracePacket_Tag_routingSelector];
    [self addNSString:_error withContentSpecificTag:UMSCCP_TracePacket_Tag_error];
    [self addBooleanNull:_dropped withContentSpecificTag:UMSCCP_TracePacket_Tag_dropped];
    [self addBooleanNull:_fromLocal withContentSpecificTag:UMSCCP_TracePacket_Tag_fromLocal];
    [self addBooleanNull:_toLocal withContentSpecificTag:UMSCCP_TracePacket_Tag_toLocal];
    [self addBooleanNull:_canNotDecode withContentSpecificTag:UMSCCP_TracePacket_Tag_canNotDecode];
    [self addBooleanNull:_routingTest withContentSpecificTag:UMSCCP_TracePacket_Tag_routingTest];
    [self addBooleanNull:_isIncoming withContentSpecificTag:UMSCCP_TracePacket_Tag_isIncoming];
    [self addNSString:_custom0 withContentSpecificTag:UMSCCP_TracePacket_Tag_custom0];
    [self addNSString:_custom1 withContentSpecificTag:UMSCCP_TracePacket_Tag_custom1];
    [self addNSString:_custom2 withContentSpecificTag:UMSCCP_TracePacket_Tag_custom2];
    [self addNSString:_custom3 withContentSpecificTag:UMSCCP_TracePacket_Tag_custom3];
    [self addNSString:_custom4 withContentSpecificTag:UMSCCP_TracePacket_Tag_custom4];
    [self addNSString:_custom5 withContentSpecificTag:UMSCCP_TracePacket_Tag_custom5];
    [self addNSString:_custom6 withContentSpecificTag:UMSCCP_TracePacket_Tag_custom6];
    [self addNSString:_custom7 withContentSpecificTag:UMSCCP_TracePacket_Tag_custom7];
    [self addNSString:_custom8 withContentSpecificTag:UMSCCP_TracePacket_Tag_custom8];
    [self addNSString:_custom9 withContentSpecificTag:UMSCCP_TracePacket_Tag_custom9];
    [self addNSData:_data0 withContentSpecificTag:UMSCCP_TracePacket_Tag_data0];
    [self addNSData:_data1 withContentSpecificTag:UMSCCP_TracePacket_Tag_data1];
    [self addNSData:_data2 withContentSpecificTag:UMSCCP_TracePacket_Tag_data2];
    [self addNSData:_data3 withContentSpecificTag:UMSCCP_TracePacket_Tag_data3];
    [self addNSData:_data4 withContentSpecificTag:UMSCCP_TracePacket_Tag_data4];
    [self addNSData:_data5 withContentSpecificTag:UMSCCP_TracePacket_Tag_data5];
    [self addNSData:_data6 withContentSpecificTag:UMSCCP_TracePacket_Tag_data6];
    [self addNSData:_data7 withContentSpecificTag:UMSCCP_TracePacket_Tag_data7];
    [self addNSData:_data8 withContentSpecificTag:UMSCCP_TracePacket_Tag_data8];
    [self addNSData:_data9 withContentSpecificTag:UMSCCP_TracePacket_Tag_data9];
}

- (UMSCCP_TracePacket *) processAfterDecodeWithContext:(id)context
{
    int p=0;
    UMASN1Object *o = [self getObjectAtPosition:p++];
    while(o)
    {
        if((o) && (o.asn1_tag.tagClass == UMASN1Class_ContextSpecific))
        {
            switch(o.asn1_tag.tagNumber)
            {
                    
                case UMSCCP_TracePacket_Tag_instanceName:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _instanceName = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_sccpInstanceName:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _sccpInstanceName = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_mtp3InstanceName:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _mtp3InstanceName = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_created:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _created = u.stringValue.dateValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_linksetName:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _linksetName = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_variant:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _variant = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_networkIndicator:
                {
                    UMASN1Integer *i = [[UMASN1Integer alloc]initWithASN1Object:o context:context];
                    _networkIndicator = i.number;
                    break;
                }
                case UMSCCP_TracePacket_Tag_opc:
                {
                    UMASN1Integer *i = [[UMASN1Integer alloc]initWithASN1Object:o context:context];
                    _opc = i.number;
                    break;
                }
                case UMSCCP_TracePacket_Tag_dpc:
                {
                    UMASN1Integer *i = [[UMASN1Integer alloc]initWithASN1Object:o context:context];
                    _dpc = i.number;
                    break;
                }
                case UMSCCP_TracePacket_Tag_serviceClass:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _serviceClass = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_serviceType:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _serviceType = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_handling:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _handling = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_maxHopCount:
                {
                    UMASN1Integer *i = [[UMASN1Integer alloc]initWithASN1Object:o context:context];
                    _maxHopCount = i.number;
                    break;
                }
                case UMSCCP_TracePacket_Tag_callingPartyAddressBeforeTranslation:
                {
                    _callingPartyAddressBeforeTranslation = [[SccpAddress alloc]initWithASN1Object:o context:context];
                    break;
                }
                case UMSCCP_TracePacket_Tag_callingPartyAddress:
                {
                    _callingPartyAddress = [[SccpAddress alloc]initWithASN1Object:o context:context];
                    break;
                }
                case UMSCCP_TracePacket_Tag_callingPartyCountry:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _callingPartyCountry = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_callingPartyPrefix:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _callingPartyPrefix = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_calledPartyAddressBeforeTranslation:
                {
                    _calledPartyAddressBeforeTranslation = [[SccpAddress alloc]initWithASN1Object:o context:context];
                    break;
                }
                case UMSCCP_TracePacket_Tag_calledPartyAddress:
                {
                    _calledPartyAddress = [[SccpAddress alloc]initWithASN1Object:o context:context];
                    break;
                }
                case UMSCCP_TracePacket_Tag_calledPartyCountry:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _calledPartyCountry = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_calledPartyPrefix:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _calledPartyPrefix = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_mtp3Data:
                {
                    UMASN1OctetString *d = [[UMASN1OctetString alloc]initWithASN1Object:o context:context];
                    _mtp3Data = d.value;
                    break;
                }                        break;
                case UMSCCP_TracePacket_Tag_sccpData:
                {
                    UMASN1OctetString *d = [[UMASN1OctetString alloc]initWithASN1Object:o context:context];
                    _sccpData = d.value;
                    break;
                }
                case UMSCCP_TracePacket_Tag_optionalData:
                {
                    UMASN1OctetString *d = [[UMASN1OctetString alloc]initWithASN1Object:o context:context];
                    _optionalData = d.value;
                    break;
                }
                case UMSCCP_TracePacket_Tag_returnCause:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _returnCause = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_tcapType:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _tcapType = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_applicationContext:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _applicationContext = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_mapOperations:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _mapOperations = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_tcap_oid:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _tcap_oid = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_tcap_did:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _tcap_did = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_msisdn:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _msisdn = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_imsi:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _imsi = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_smsc:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _smsc = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_hlr:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _hlr = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_msc:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _msc = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_partsInfo:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _partsInfo = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_routingSelector:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _routingSelector = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_error:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _error = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_dropped:
                {
                    _dropped = YES;
                    break;
                }
                case UMSCCP_TracePacket_Tag_fromLocal:
                {
                    _fromLocal = YES;
                    break;
                }
                case UMSCCP_TracePacket_Tag_toLocal:
                {
                    _toLocal = YES;
                    break;
                }
                case UMSCCP_TracePacket_Tag_canNotDecode:
                {
                    _canNotDecode = YES;
                    break;
                }
                case UMSCCP_TracePacket_Tag_routingTest:
                {
                    _routingTest = YES;
                    break;
                }
                case UMSCCP_TracePacket_Tag_isIncoming:
                {
                    _isIncoming = YES;
                    break;
                }
                case UMSCCP_TracePacket_Tag_custom0:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _custom0 = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_custom1:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _custom1 = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_custom2:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _custom2 = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_custom3:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _custom3 = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_custom4:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _custom4 = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_custom5:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _custom5 = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_custom6:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _custom6 = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_custom7:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _custom7 = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_custom8:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _custom8 = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_custom9:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _custom9 = u.stringValue;
                    break;
                }
                case UMSCCP_TracePacket_Tag_data0:
                {
                    UMASN1OctetString *d = [[UMASN1OctetString alloc]initWithASN1Object:o context:context];
                    _data0 = d.value;
                    break;
                }
                case UMSCCP_TracePacket_Tag_data1:
                {
                    UMASN1OctetString *d = [[UMASN1OctetString alloc]initWithASN1Object:o context:context];
                    _data1 = d.value;
                    break;
                }
                case UMSCCP_TracePacket_Tag_data2:
                {
                    UMASN1OctetString *d = [[UMASN1OctetString alloc]initWithASN1Object:o context:context];
                    _data2 = d.value;
                    break;
                }
                case UMSCCP_TracePacket_Tag_data3:
                {
                    UMASN1OctetString *d = [[UMASN1OctetString alloc]initWithASN1Object:o context:context];
                    _data3 = d.value;
                    break;
                }
                case UMSCCP_TracePacket_Tag_data4:
                {
                    UMASN1OctetString *d = [[UMASN1OctetString alloc]initWithASN1Object:o context:context];
                    _data4 = d.value;
                    break;
                }
                case UMSCCP_TracePacket_Tag_data5:
                {
                    UMASN1OctetString *d = [[UMASN1OctetString alloc]initWithASN1Object:o context:context];
                    _data5 = d.value;
                    break;
                }
                case UMSCCP_TracePacket_Tag_data6:
                {
                    UMASN1OctetString *d = [[UMASN1OctetString alloc]initWithASN1Object:o context:context];
                    _data6 = d.value;
                    break;
                }
                case UMSCCP_TracePacket_Tag_data7:
                {
                    UMASN1OctetString *d = [[UMASN1OctetString alloc]initWithASN1Object:o context:context];
                    _data7 = d.value;
                    break;
                }
                case UMSCCP_TracePacket_Tag_data8:
                {
                    UMASN1OctetString *d = [[UMASN1OctetString alloc]initWithASN1Object:o context:context];
                    _data8 = d.value;
                    break;
                }
                case UMSCCP_TracePacket_Tag_data9:
                {
                    UMASN1OctetString *d = [[UMASN1OctetString alloc]initWithASN1Object:o context:context];
                    _data9 = d.value;
                    break;
                }
            }
        }
        o = [self getObjectAtPosition:p++];
    }
    return self;
}

- (UMSynchronizedSortedDictionary *)objectValue
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    if(_instanceName)
    {
        dict[@"instanceName"] = _instanceName; /* NSString */
    }
    if(_sccpInstanceName)
    {
        dict[@"sccpInstanceName"] = _sccpInstanceName; /* NSString */
    }
    if(_mtp3InstanceName)
    {
        dict[@"mtp3InstanceName"] = _mtp3InstanceName; /* NSString */
    }
    if(_created)
    {
        dict[@"created"] = _created; /* NSDate */
    }
    if(_linksetName)
    {
        dict[@"linksetName"] = _linksetName; /* NSString */
    }
    if(_variant)
    {
        dict[@"variant"] = _variant; /* NSString */
    }
    if(_networkIndicator)
    {
        dict[@"networkIndicator"] = _networkIndicator; /* NSNumber */
    }
    if(_opc)
    {
        dict[@"opc"] = _opc; /* NSNumber */
    }
    if(_dpc)
    {
        dict[@"dpc"] = _dpc; /* NSNumber */
    }
    if(_serviceClass)
    {
        dict[@"serviceClass"] = _serviceClass; /* NSString */
    }
    if(_serviceType)
    {
        dict[@"serviceType"] = _serviceType; /* NSString */
    }
    if(_handling)
    {
        dict[@"handling"] = _handling; /* NSString */
    }
    if(_maxHopCount)
    {
        dict[@"maxHopCount"] = _maxHopCount; /* NSNumber */
    }
    if(_callingPartyAddressBeforeTranslation)
    {
        dict[@"callingPartyAddressBeforeTranslation"] = _callingPartyAddressBeforeTranslation; /* SccpAddress */
    }
    if(_callingPartyAddress)
    {
        dict[@"callingPartyAddress"] = _callingPartyAddress; /* SccpAddress */
    }
    if(_callingPartyCountry)
    {
        dict[@"callingPartyCountry"] = _callingPartyCountry; /* NSString */
    }
    if(_callingPartyPrefix)
    {
        dict[@"callingPartyPrefix"] = _callingPartyPrefix; /* NSString */
    }
    if(_calledPartyAddressBeforeTranslation)
    {
        dict[@"calledPartyAddressBeforeTranslation"] = _calledPartyAddressBeforeTranslation; /* SccpAddress */
    }
    if(_calledPartyAddress)
    {
        dict[@"calledPartyAddress"] = _calledPartyAddress; /* SccpAddress */
    }
    if(_calledPartyCountry)
    {
        dict[@"calledPartyCountry"] = _calledPartyCountry; /* NSString */
    }
    if(_calledPartyPrefix)
    {
        dict[@"calledPartyPrefix"] = _calledPartyPrefix; /* NSString */
    }
    if(_mtp3Data)
    {
        dict[@"mtp3Data"] = _mtp3Data; /* NSData */
    }
    if(_sccpData)
    {
        dict[@"sccpData"] = _sccpData; /* NSData */
    }
    if(_optionalData)
    {
        dict[@"optionalData"] = _optionalData; /* NSData */
    }
    if(_returnCause)
    {
        dict[@"returnCause"] = _returnCause; /* NSString */
    }
    if(_tcapType)
    {
        dict[@"tcapType"] = _tcapType; /* NSString */
    }
    if(_applicationContext)
    {
        dict[@"applicationContext"] = _applicationContext; /* NSString */
    }
    if(_mapOperations)
    {
        dict[@"mapOperations"] = _mapOperations; /* NSString */
    }
    if(_tcap_oid)
    {
        dict[@"tcap_oid"] = _tcap_oid; /* NSString */
    }
    if(_tcap_did)
    {
        dict[@"tcap_did"] = _tcap_did; /* NSString */
    }
    if(_msisdn)
    {
        dict[@"msisdn"] = _msisdn; /* NSString */
    }
    if(_imsi)
    {
        dict[@"imsi"] = _imsi; /* NSString */
    }
    if(_smsc)
    {
        dict[@"smsc"] = _smsc; /* NSString */
    }
    if(_hlr)
    {
        dict[@"hlr"] = _hlr; /* NSString */
    }
    if(_msc)
    {
        dict[@"msc"] = _msc; /* NSString */
    }
    if(_partsInfo)
    {
        dict[@"partsInfo"] = _partsInfo; /* NSString */
    }
    if(_routingSelector)
    {
        dict[@"routingSelector"] = _routingSelector; /* NSString */
    }
    if(_error)
    {
        dict[@"error"] = _error; /* NSString */
    }

    if(_dropped)
    {
        dict[@"_dropped"] = @(_dropped); /* BOOL */
    }
    if(_fromLocal)
    {
        dict[@"_fromLocal"] = @(_fromLocal); /* BOOL */
    }
    if(_toLocal)
    {
        dict[@"_toLocal"] = @(_toLocal); /* BOOL */
    }
    if(_canNotDecode)
    {
        dict[@"_canNotDecode"] = @(_canNotDecode); /* BOOL */
    }
    if(_routingTest)
    {
        dict[@"_routingTest"] = @(_routingTest); /* BOOL */
    }
    if(_isIncoming)
    {
        dict[@"_isIncoming"] = @(_isIncoming); /* BOOL */
    }
    if(_custom0)
    {
        dict[@"custom0"] = _custom0; /* NSString */
    }
    if(_custom1)
    {
        dict[@"custom1"] = _custom1; /* NSString */
    }
    if(_custom2)
    {
        dict[@"custom2"] = _custom2; /* NSString */
    }
    if(_custom3)
    {
        dict[@"custom3"] = _custom3; /* NSString */
    }
    if(_custom4)
    {
        dict[@"custom4"] = _custom4; /* NSString */
    }
    if(_custom5)
    {
        dict[@"custom5"] = _custom5; /* NSString */
    }
    if(_custom6)
    {
        dict[@"custom6"] = _custom6; /* NSString */
    }
    if(_custom7)
    {
        dict[@"custom7"] = _custom7; /* NSString */
    }
    if(_custom8)
    {
        dict[@"custom8"] = _custom8; /* NSString */
    }
    if(_custom9)
    {
        dict[@"custom9"] = _custom9; /* NSString */
    }

    if(_data0)
    {
        dict[@"data0"] = _data0; /* NSData */
    }
    if(_data1)
    {
        dict[@"data1"] = _data1; /* NSData */
    }
    if(_data2)
    {
        dict[@"data2"] = _data2; /* NSData */
    }
    if(_data3)
    {
        dict[@"data3"] = _data3; /* NSData */
    }
    if(_data4)
    {
        dict[@"data4"] = _data4; /* NSData */
    }
    if(_data5)
    {
        dict[@"data5"] = _data5; /* NSData */
    }
    if(_data6)
    {
        dict[@"data6"] = _data6; /* NSData */
    }
    if(_data7)
    {
        dict[@"data7"] = _data7; /* NSData */
    }
    if(_data8)
    {
        dict[@"data8"] = _data8; /* NSData */
    }
    if(_data9)
    {
        dict[@"data9"] = _data9; /* NSData */
    }
    return dict;
}

@end

