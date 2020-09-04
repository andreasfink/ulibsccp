//
//  UMSCCP_StatisticDb.m
//  ulibsccp
//
//  Created by Andreas Fink on 01.06.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSCCP_StatisticDb.h"
#import "UMSCCP_StatisticDbRecord.h"
#import "UMLayerSCCPApplicationContextProtocol.h"
#import "UMSCCP_Defs.h"

// #define UMSCCP_STATISTICS_DEBUG 1

static dbFieldDef UMSCCP_StatisticDb_fields[] =
{
    {"dbkey",               NULL,       NO,     DB_PRIMARY_INDEX,   DB_FIELD_TYPE_VARCHAR,             255,   0,NULL,NULL,1},
    {"ymdh",                NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             10,    0,NULL,NULL,2},
    {"instance",            NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             32,    0,NULL,NULL,3},
    {"incoming_linkset",    NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             32,    0,NULL,NULL,4},
    {"outgoing_linkset",    NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             32,    0,NULL,NULL,5},
    {"calling_prefix",      NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             32,    0,NULL,NULL,6},
    {"called_prefix",       NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             32,    0,NULL,NULL,7},
    {"gtt_selector",        NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             32,    0,NULL,NULL,8},
    {"sccp_operation",      NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             32,    0,NULL,NULL,9},
    {"msu_count",           NULL,       NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_INTEGER,             0,     0,NULL,NULL,10},
    {"bytes_count",         NULL,       NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_INTEGER,             0,     0,NULL,NULL,11},
    { "",                   NULL,       NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_END,                 0,     0,NULL,NULL,255},
};

@implementation UMSCCP_StatisticDb

- (UMSCCP_StatisticDb *)initWithPoolName:(NSString *)poolName
                              tableName:(NSString *)table
                             appContext:(id<UMLayerSCCPApplicationContextProtocol>)appContext
                             autocreate:(BOOL)autocreate
                               instance:(NSString *)instance
{
    self = [super init];
    if(self)
    {
        NSDictionary *config =@{ @"enable"     : @(YES),
                                   @"table-name" : table,
                                   @"autocreate" : @(autocreate),
                                   @"pool-name"  : poolName };
        _poolName = poolName;
        _pool = [appContext dbPools][_poolName];
        _table = [[UMDbTable alloc]initWithConfig:config andPools:appContext.dbPools];
        _lock = [[UMMutex alloc]initWithName:@"UMMTP3StatisticDb-lock"];
        _entries = [[UMSynchronizedDictionary alloc]init];
        _instance = instance;
        _e164 = [[UMSynchronizedDictionary alloc]init];
        _e212 = [[UMSynchronizedDictionary alloc]init];
        _e214 = [[UMSynchronizedDictionary alloc]init];
        _e164_dt = [[UMDigitTree alloc]init];
        _e212_dt = [[UMDigitTree alloc]init];
        _e214_dt = [[UMDigitTree alloc]init];

        [self addCountryPrefixesE164];
        [self addCountryPrefixesE214];
        [self addMncPrefixesE212];

        NSTimeZone *tz = [NSTimeZone timeZoneWithName:@"UTC"];
        _ymdhDateFormatter= [[NSDateFormatter alloc]init];
        NSLocale *ukLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
        [_ymdhDateFormatter setLocale:ukLocale];
        [_ymdhDateFormatter setDateFormat:@"yyyyMMddHH"];
        [_ymdhDateFormatter setTimeZone:tz];
    }
    return self;
}

- (void)doAutocreate
{
    if(_pool==NULL)
    {
        _pool = _table.pools[_poolName];
    }

    UMDbSession *session = [_pool grabSession:__FILE__ line:__LINE__ func:__func__];
    [_table autoCreate:UMSCCP_StatisticDb_fields session:session];
    [_pool returnSession:session file:__FILE__ line:__LINE__ func:__func__];
}


- (void)addByteCount:(int)byteCount
     incomingLinkset:(NSString *)incomingLinkset
     outgoingLinkset:(NSString *)outgoingLinkset
       callingPrefix:(NSString *)callingPrefix
        calledPrefix:(NSString *)calledPrefix
         gttSelector:(NSString *)selector
       sccpOperation:(SCCP_ServiceType)sccpOperation
   incomingPointCode:(NSString *)opc
   outgoingPointCode:(NSString *)dpc
         destination:(NSString *)dst
{
    @autoreleasepool
    {
#if defined (UMSCCP_STATISTICS_DEBUG)
            NSLog(@"UMSCCP_STATISTICS_DEBUG: addByteCount:%d\n"
                  @"                      incomingLinkset:%@\n"
                  @"                      outgoingLinkset:%@\n"
                  @"                        callingPrefix:%@\n"
                  @"                         calledPrefix:%@\n"
                  @"                             selector:%@\n"
                  @"                        sccpOperation:%d\n"
                  @"                    incomingPointCode:%@\n"
                  @"                    outgoingPointCode:%@\n"
                  @"                          destination:%@\n"
                  ,byteCount,incomingLinkset,outgoingLinkset,callingPrefix,calledPrefix,selector,sccpOperation.opc,dpc,dst);
#endif
        NSString *ymdh = [_ymdhDateFormatter stringFromDate:[NSDate date]];
        NSString *sccpOperationString = @"unknown";
        switch(sccpOperation)
        {
            case SCCP_UDT:
                sccpOperationString =@"UDT";
                break;
            case SCCP_UDTS:
                sccpOperationString =@"UDTS";
                break;
            case SCCP_XUDT:
                sccpOperationString =@"XUDT";
                break;
            case SCCP_XUDTS:
                sccpOperationString =@"XUDTS";
                break;
            case SCCP_LUDT:
                sccpOperationString =@"LUDT";
                break;
            case SCCP_LUDTS:
                sccpOperationString =@"LUDTS";
                break;
            default:
                sccpOperationString = [NSString stringWithFormat:@"%d",sccpOperation];
                break;
        }

        NSString *key = [UMSCCP_StatisticDbRecord keystringFor:ymdh
                                               incomingLinkset:incomingLinkset
                                               outgoingLinkset:outgoingLinkset
                                                 callingPrefix:callingPrefix
                                                  calledPrefix:calledPrefix
                                                   gttSelector:selector
                                                 sccpOperation:sccpOperationString
                                                      instance:_instance
                                             incomingPointCode:opc
                                             outgoingPointCode:dpc
                                                   destination:dst];
        [_lock lock];
        UMSCCP_StatisticDbRecord *rec = _entries[key];
        if(rec == NULL)
        {
            rec = [[UMSCCP_StatisticDbRecord alloc]init];
            rec.ymdh = ymdh;
            rec.incoming_linkset = incomingLinkset;
            rec.outgoing_linkset = outgoingLinkset;
            rec.calling_prefix = callingPrefix;
            rec.called_prefix = calledPrefix;
            rec.gtt_selector = selector;
            rec.sccp_operation = sccpOperationString;
            rec.instance = _instance;
            rec.incoming_pc = opc;
            rec.outgoing_pc = UMSCCP_StatisticDbRecorddpc;
            rec.destination = dst;
            _entries[key] = rec;
        }
        [_lock unlock];
        [rec increaseMsuCount:1 byteCount:byteCount];
    }
}

- (void)flush
{
    @autoreleasepool
    {
        [_lock lock];
        UMSynchronizedDictionary *tmp = _entries;
        _entries = [[UMSynchronizedDictionary alloc]init];
        [_lock unlock];
        
        NSArray *keys = [tmp allKeys];
        for(NSString *key in keys)
        {
            UMSCCP_StatisticDbRecord *rec = tmp[key];
            [rec flushToPool:_pool table:_table];
        }
    }
}


- (void)addE164prefix:(NSString *)prefix
{
    _e164[prefix] = prefix;
    [_e164_dt addEntry:prefix forDigits:prefix];
}

- (void)addE212prefix:(NSString *)prefix
{
    _e212[prefix] = prefix;
    [_e212_dt addEntry:prefix forDigits:prefix];
}

- (void)addE214prefix:(NSString *)prefix
{
    _e214[prefix] = prefix;
    [_e214_dt addEntry:prefix forDigits:prefix];

}

- (NSArray *)listPrefixesE164
{
    NSArray *a = [_e164 allKeys];
    a = [a sortedArrayUsingSelector:@selector(compare:)];
    return a;
}

- (NSArray *)listPrefixesE212
{
    NSArray *a = [_e212 allKeys];
    a = [a sortedArrayUsingSelector:@selector(compare:)];
    return a;
}


- (NSArray *)listPrefixesE214
{
    NSArray *a = [_e214 allKeys];
    a = [a sortedArrayUsingSelector:@selector(compare:)];
    return a;
}

- (NSString *)prefixOf:(NSString *)in
                  dict:(UMSynchronizedDictionary *)dict
{
    NSInteger n = in.length;
    for(NSInteger i=n;i>0;i--)
    {
        NSString *sub = [in substringToIndex:i];
        if(dict[sub])
        {
            return sub;
        }
    }
    return @"";
}


- (NSString *)e164prefixOf:(NSString *)in
{
    return [self prefixOf:in dict:_e164];
}

- (NSString *)e212prefixOf:(NSString *)in
{
    return [self prefixOf:in dict:_e212];

}

- (NSString *)e214prefixOf:(NSString *)in
{
    return [self prefixOf:in dict:_e214];
}


- (void)addMncPrefixesE212
{
    for(int i=0;i<1000;i++)
    {
        NSString *s = [NSString stringWithFormat:@"%03d",i];
        [self e212prefixOf:s];
    }
}

- (void)addCountryPrefixesE164
{
    [self addE164prefix:@"1"];
    [self addE164prefix:@"1201"];
    [self addE164prefix:@"1202"];
    [self addE164prefix:@"1203"];
    [self addE164prefix:@"1204"];
    [self addE164prefix:@"1205"];
    [self addE164prefix:@"1206"];
    [self addE164prefix:@"1207"];
    [self addE164prefix:@"1208"];
    [self addE164prefix:@"1209"];
    [self addE164prefix:@"1210"];
    [self addE164prefix:@"1212"];
    [self addE164prefix:@"1213"];
    [self addE164prefix:@"1214"];
    [self addE164prefix:@"1215"];
    [self addE164prefix:@"1216"];
    [self addE164prefix:@"1217"];
    [self addE164prefix:@"1218"];
    [self addE164prefix:@"1219"];
    [self addE164prefix:@"1220"];
    [self addE164prefix:@"1223"];
    [self addE164prefix:@"1224"];
    [self addE164prefix:@"1225"];
    [self addE164prefix:@"1226"];
    [self addE164prefix:@"1228"];
    [self addE164prefix:@"1229"];
    [self addE164prefix:@"1231"];
    [self addE164prefix:@"1234"];
    [self addE164prefix:@"1236"];
    [self addE164prefix:@"1239"];
    [self addE164prefix:@"1240"];
    [self addE164prefix:@"1242"];
    [self addE164prefix:@"1246"];
    [self addE164prefix:@"1248"];
    [self addE164prefix:@"1249"];
    [self addE164prefix:@"1250"];
    [self addE164prefix:@"1251"];
    [self addE164prefix:@"1252"];
    [self addE164prefix:@"1253"];
    [self addE164prefix:@"1254"];
    [self addE164prefix:@"1256"];
    [self addE164prefix:@"1260"];
    [self addE164prefix:@"1262"];
    [self addE164prefix:@"1264"];
    [self addE164prefix:@"1267"];
    [self addE164prefix:@"1268"];
    [self addE164prefix:@"1270"];
    [self addE164prefix:@"1272"];
    [self addE164prefix:@"1276"];
    [self addE164prefix:@"1279"];
    [self addE164prefix:@"1281"];
    [self addE164prefix:@"1284"];
    [self addE164prefix:@"1289"];
    [self addE164prefix:@"1301"];
    [self addE164prefix:@"1304"];
    [self addE164prefix:@"1305"];
    [self addE164prefix:@"1306"];
    [self addE164prefix:@"1307"];
    [self addE164prefix:@"1308"];
    [self addE164prefix:@"1309"];
    [self addE164prefix:@"1312"];
    [self addE164prefix:@"1313"];
    [self addE164prefix:@"1314"];
    [self addE164prefix:@"1315"];
    [self addE164prefix:@"1316"];
    [self addE164prefix:@"1317"];
    [self addE164prefix:@"1318"];
    [self addE164prefix:@"1319"];
    [self addE164prefix:@"1320"];
    [self addE164prefix:@"1321"];
    [self addE164prefix:@"1323"];
    [self addE164prefix:@"1325"];
    [self addE164prefix:@"1330"];
    [self addE164prefix:@"1331"];
    [self addE164prefix:@"1332"];
    [self addE164prefix:@"1334"];
    [self addE164prefix:@"1336"];
    [self addE164prefix:@"1337"];
    [self addE164prefix:@"1339"];
    [self addE164prefix:@"1343"];
    [self addE164prefix:@"1345"];
    [self addE164prefix:@"1346"];
    [self addE164prefix:@"1347"];
    [self addE164prefix:@"1351"];
    [self addE164prefix:@"1352"];
    [self addE164prefix:@"1365"];
    [self addE164prefix:@"1367"];
    [self addE164prefix:@"1380"];
    [self addE164prefix:@"1385"];
    [self addE164prefix:@"1386"];
    [self addE164prefix:@"1401"];
    [self addE164prefix:@"1402"];
    [self addE164prefix:@"1403"];
    [self addE164prefix:@"1404"];
    [self addE164prefix:@"1405"];
    [self addE164prefix:@"1406"];
    [self addE164prefix:@"1407"];
    [self addE164prefix:@"1408"];
    [self addE164prefix:@"1409"];
    [self addE164prefix:@"1410"];
    [self addE164prefix:@"1412"];
    [self addE164prefix:@"1413"];
    [self addE164prefix:@"1414"];
    [self addE164prefix:@"1415"];
    [self addE164prefix:@"1416"];
    [self addE164prefix:@"1417"];
    [self addE164prefix:@"1418"];
    [self addE164prefix:@"1419"];
    [self addE164prefix:@"1423"];
    [self addE164prefix:@"1424"];
    [self addE164prefix:@"1425"];
    [self addE164prefix:@"1428"];
    [self addE164prefix:@"1430"];
    [self addE164prefix:@"1431"];
    [self addE164prefix:@"1432"];
    [self addE164prefix:@"1434"];
    [self addE164prefix:@"1435"];
    [self addE164prefix:@"1437"];
    [self addE164prefix:@"1438"];
    [self addE164prefix:@"1440"];
    [self addE164prefix:@"1441"];
    [self addE164prefix:@"1442"];
    [self addE164prefix:@"1443"];
    [self addE164prefix:@"1445"];
    [self addE164prefix:@"1450"];
    [self addE164prefix:@"1458"];
    [self addE164prefix:@"1463"];
    [self addE164prefix:@"1469"];
    [self addE164prefix:@"1470"];
    [self addE164prefix:@"1475"];
    [self addE164prefix:@"1478"];
    [self addE164prefix:@"1479"];
    [self addE164prefix:@"1480"];
    [self addE164prefix:@"1484"];
    [self addE164prefix:@"1501"];
    [self addE164prefix:@"1502"];
    [self addE164prefix:@"1503"];
    [self addE164prefix:@"1504"];
    [self addE164prefix:@"1505"];
    [self addE164prefix:@"1506"];
    [self addE164prefix:@"1507"];
    [self addE164prefix:@"1508"];
    [self addE164prefix:@"1509"];
    [self addE164prefix:@"1510"];
    [self addE164prefix:@"1512"];
    [self addE164prefix:@"1513"];
    [self addE164prefix:@"1514"];
    [self addE164prefix:@"1515"];
    [self addE164prefix:@"1516"];
    [self addE164prefix:@"1517"];
    [self addE164prefix:@"1518"];
    [self addE164prefix:@"1519"];
    [self addE164prefix:@"1520"];
    [self addE164prefix:@"1530"];
    [self addE164prefix:@"1531"];
    [self addE164prefix:@"1534"];
    [self addE164prefix:@"1539"];
    [self addE164prefix:@"1540"];
    [self addE164prefix:@"1541"];
    [self addE164prefix:@"1548"];
    [self addE164prefix:@"1551"];
    [self addE164prefix:@"1559"];
    [self addE164prefix:@"1561"];
    [self addE164prefix:@"1562"];
    [self addE164prefix:@"1563"];
    [self addE164prefix:@"1564"];
    [self addE164prefix:@"1567"];
    [self addE164prefix:@"1570"];
    [self addE164prefix:@"1571"];
    [self addE164prefix:@"1573"];
    [self addE164prefix:@"1574"];
    [self addE164prefix:@"1575"];
    [self addE164prefix:@"1579"];
    [self addE164prefix:@"1580"];
    [self addE164prefix:@"1581"];
    [self addE164prefix:@"1585"];
    [self addE164prefix:@"1586"];
    [self addE164prefix:@"1587"];
    [self addE164prefix:@"1601"];
    [self addE164prefix:@"1602"];
    [self addE164prefix:@"1603"];
    [self addE164prefix:@"1604"];
    [self addE164prefix:@"1605"];
    [self addE164prefix:@"1606"];
    [self addE164prefix:@"1607"];
    [self addE164prefix:@"1608"];
    [self addE164prefix:@"1609"];
    [self addE164prefix:@"1610"];
    [self addE164prefix:@"1612"];
    [self addE164prefix:@"1613"];
    [self addE164prefix:@"1614"];
    [self addE164prefix:@"1615"];
    [self addE164prefix:@"1616"];
    [self addE164prefix:@"1617"];
    [self addE164prefix:@"1618"];
    [self addE164prefix:@"1619"];
    [self addE164prefix:@"1620"];
    [self addE164prefix:@"1623"];
    [self addE164prefix:@"1626"];
    [self addE164prefix:@"1628"];
    [self addE164prefix:@"1629"];
    [self addE164prefix:@"1630"];
    [self addE164prefix:@"1631"];
    [self addE164prefix:@"1636"];
    [self addE164prefix:@"1639"];
    [self addE164prefix:@"1641"];
    [self addE164prefix:@"1646"];
    [self addE164prefix:@"1647"];
    [self addE164prefix:@"1650"];
    [self addE164prefix:@"1651"];
    [self addE164prefix:@"1657"];
    [self addE164prefix:@"1660"];
    [self addE164prefix:@"1661"];
    [self addE164prefix:@"1662"];
    [self addE164prefix:@"1667"];
    [self addE164prefix:@"1669"];
    [self addE164prefix:@"1671"];
    [self addE164prefix:@"1672"];
    [self addE164prefix:@"1678"];
    [self addE164prefix:@"1680"];
    [self addE164prefix:@"1681"];
    [self addE164prefix:@"1682"];
    [self addE164prefix:@"1684"];
    [self addE164prefix:@"1701"];
    [self addE164prefix:@"1702"];
    [self addE164prefix:@"1703"];
    [self addE164prefix:@"1704"];
    [self addE164prefix:@"1705"];
    [self addE164prefix:@"1706"];
    [self addE164prefix:@"1707"];
    [self addE164prefix:@"1708"];
    [self addE164prefix:@"1709"];
    [self addE164prefix:@"1712"];
    [self addE164prefix:@"1713"];
    [self addE164prefix:@"1714"];
    [self addE164prefix:@"1715"];
    [self addE164prefix:@"1716"];
    [self addE164prefix:@"1717"];
    [self addE164prefix:@"1718"];
    [self addE164prefix:@"1719"];
    [self addE164prefix:@"1720"];
    [self addE164prefix:@"1724"];
    [self addE164prefix:@"1725"];
    [self addE164prefix:@"1726"];
    [self addE164prefix:@"1727"];
    [self addE164prefix:@"1731"];
    [self addE164prefix:@"1732"];
    [self addE164prefix:@"1734"];
    [self addE164prefix:@"1737"];
    [self addE164prefix:@"1740"];
    [self addE164prefix:@"1743"];
    [self addE164prefix:@"1747"];
    [self addE164prefix:@"1754"];
    [self addE164prefix:@"1757"];
    [self addE164prefix:@"1760"];
    [self addE164prefix:@"1762"];
    [self addE164prefix:@"1763"];
    [self addE164prefix:@"1765"];
    [self addE164prefix:@"1769"];
    [self addE164prefix:@"1770"];
    [self addE164prefix:@"1772"];
    [self addE164prefix:@"1773"];
    [self addE164prefix:@"1774"];
    [self addE164prefix:@"1775"];
    [self addE164prefix:@"1778"];
    [self addE164prefix:@"1779"];
    [self addE164prefix:@"1780"];
    [self addE164prefix:@"1781"];
    [self addE164prefix:@"1782"];
    [self addE164prefix:@"1785"];
    [self addE164prefix:@"1786"];
    [self addE164prefix:@"1801"];
    [self addE164prefix:@"1802"];
    [self addE164prefix:@"1803"];
    [self addE164prefix:@"1804"];
    [self addE164prefix:@"1805"];
    [self addE164prefix:@"1806"];
    [self addE164prefix:@"1807"];
    [self addE164prefix:@"1808"];
    [self addE164prefix:@"1810"];
    [self addE164prefix:@"1812"];
    [self addE164prefix:@"1813"];
    [self addE164prefix:@"1814"];
    [self addE164prefix:@"1815"];
    [self addE164prefix:@"1816"];
    [self addE164prefix:@"1817"];
    [self addE164prefix:@"1818"];
    [self addE164prefix:@"1819"];
    [self addE164prefix:@"1820"];
    [self addE164prefix:@"1825"];
    [self addE164prefix:@"1828"];
    [self addE164prefix:@"1830"];
    [self addE164prefix:@"1831"];
    [self addE164prefix:@"1832"];
    [self addE164prefix:@"1838"];
    [self addE164prefix:@"1843"];
    [self addE164prefix:@"1845"];
    [self addE164prefix:@"1847"];
    [self addE164prefix:@"1848"];
    [self addE164prefix:@"1850"];
    [self addE164prefix:@"1854"];
    [self addE164prefix:@"1856"];
    [self addE164prefix:@"1857"];
    [self addE164prefix:@"1858"];
    [self addE164prefix:@"1859"];
    [self addE164prefix:@"1860"];
    [self addE164prefix:@"1862"];
    [self addE164prefix:@"1863"];
    [self addE164prefix:@"1864"];
    [self addE164prefix:@"1865"];
    [self addE164prefix:@"1867"];
    [self addE164prefix:@"1870"];
    [self addE164prefix:@"1872"];
    [self addE164prefix:@"1873"];
    [self addE164prefix:@"1878"];
    [self addE164prefix:@"1879"];
    [self addE164prefix:@"1901"];
    [self addE164prefix:@"1902"];
    [self addE164prefix:@"1903"];
    [self addE164prefix:@"1904"];
    [self addE164prefix:@"1905"];
    [self addE164prefix:@"1906"];
    [self addE164prefix:@"1907"];
    [self addE164prefix:@"1908"];
    [self addE164prefix:@"1909"];
    [self addE164prefix:@"1910"];
    [self addE164prefix:@"1912"];
    [self addE164prefix:@"1913"];
    [self addE164prefix:@"1914"];
    [self addE164prefix:@"1915"];
    [self addE164prefix:@"1916"];
    [self addE164prefix:@"1917"];
    [self addE164prefix:@"1918"];
    [self addE164prefix:@"1919"];
    [self addE164prefix:@"1920"];
    [self addE164prefix:@"1925"];
    [self addE164prefix:@"1928"];
    [self addE164prefix:@"1929"];
    [self addE164prefix:@"1930"];
    [self addE164prefix:@"1931"];
    [self addE164prefix:@"1934"];
    [self addE164prefix:@"1936"];
    [self addE164prefix:@"1937"];
    [self addE164prefix:@"1938"];
    [self addE164prefix:@"1940"];
    [self addE164prefix:@"1941"];
    [self addE164prefix:@"1947"];
    [self addE164prefix:@"1949"];
    [self addE164prefix:@"1951"];
    [self addE164prefix:@"1952"];
    [self addE164prefix:@"1954"];
    [self addE164prefix:@"1956"];
    [self addE164prefix:@"1959"];
    [self addE164prefix:@"1970"];
    [self addE164prefix:@"1971"];
    [self addE164prefix:@"1972"];
    [self addE164prefix:@"1973"];
    [self addE164prefix:@"1978"];
    [self addE164prefix:@"1979"];
    [self addE164prefix:@"1980"];
    [self addE164prefix:@"1984"];
    [self addE164prefix:@"1985"];
    [self addE164prefix:@"1986"];
    [self addE164prefix:@"1989"];
    [self addE164prefix:@"20"];
    [self addE164prefix:@"211"];
    [self addE164prefix:@"212"];
    [self addE164prefix:@"213"];
    [self addE164prefix:@"216"];
    [self addE164prefix:@"218"];
    [self addE164prefix:@"220"];
    [self addE164prefix:@"221"];
    [self addE164prefix:@"222"];
    [self addE164prefix:@"223"];
    [self addE164prefix:@"224"];
    [self addE164prefix:@"225"];
    [self addE164prefix:@"226"];
    [self addE164prefix:@"227"];
    [self addE164prefix:@"228"];
    [self addE164prefix:@"229"];
    [self addE164prefix:@"230"];
    [self addE164prefix:@"231"];
    [self addE164prefix:@"232"];
    [self addE164prefix:@"233"];
    [self addE164prefix:@"234"];
    [self addE164prefix:@"235"];
    [self addE164prefix:@"236"];
    [self addE164prefix:@"237"];
    [self addE164prefix:@"238"];
    [self addE164prefix:@"239"];
    [self addE164prefix:@"240"];
    [self addE164prefix:@"241"];
    [self addE164prefix:@"242"];
    [self addE164prefix:@"243"];
    [self addE164prefix:@"244"];
    [self addE164prefix:@"245"];
    [self addE164prefix:@"246"];
    [self addE164prefix:@"248"];
    [self addE164prefix:@"249"];
    [self addE164prefix:@"250"];
    [self addE164prefix:@"251"];
    [self addE164prefix:@"252"];
    [self addE164prefix:@"253"];
    [self addE164prefix:@"254"];
    [self addE164prefix:@"255"];
    [self addE164prefix:@"256"];
    [self addE164prefix:@"257"];
    [self addE164prefix:@"258"];
    [self addE164prefix:@"260"];
    [self addE164prefix:@"261"];
    [self addE164prefix:@"262"];
    [self addE164prefix:@"263"];
    [self addE164prefix:@"264"];
    [self addE164prefix:@"265"];
    [self addE164prefix:@"266"];
    [self addE164prefix:@"267"];
    [self addE164prefix:@"268"];
    [self addE164prefix:@"269"];
    [self addE164prefix:@"27"];
    [self addE164prefix:@"290"];
    [self addE164prefix:@"291"];
    [self addE164prefix:@"297"];
    [self addE164prefix:@"298"];
    [self addE164prefix:@"299"];
    [self addE164prefix:@"30"];
    [self addE164prefix:@"31"];
    [self addE164prefix:@"32"];
    [self addE164prefix:@"33"];
    [self addE164prefix:@"34"];
    [self addE164prefix:@"350"];
    [self addE164prefix:@"351"];
    [self addE164prefix:@"352"];
    [self addE164prefix:@"353"];
    [self addE164prefix:@"354"];
    [self addE164prefix:@"355"];
    [self addE164prefix:@"356"];
    [self addE164prefix:@"357"];
    [self addE164prefix:@"358"];
    [self addE164prefix:@"359"];
    [self addE164prefix:@"36"];
    [self addE164prefix:@"370"];
    [self addE164prefix:@"371"];
    [self addE164prefix:@"372"];
    [self addE164prefix:@"373"];
    [self addE164prefix:@"374"];
    [self addE164prefix:@"375"];
    [self addE164prefix:@"376"];
    [self addE164prefix:@"377"];
    [self addE164prefix:@"378"];
    [self addE164prefix:@"379"];
    [self addE164prefix:@"380"];
    [self addE164prefix:@"381"];
    [self addE164prefix:@"382"];
    [self addE164prefix:@"383"];
    [self addE164prefix:@"385"];
    [self addE164prefix:@"386"];
    [self addE164prefix:@"387"];
    [self addE164prefix:@"389"];
    [self addE164prefix:@"39"];
    [self addE164prefix:@"40"];
    [self addE164prefix:@"41"];
    [self addE164prefix:@"420"];
    [self addE164prefix:@"421"];
    [self addE164prefix:@"423"];
    [self addE164prefix:@"43"];
    [self addE164prefix:@"44"];
    [self addE164prefix:@"441481"];
    [self addE164prefix:@"441534"];
    [self addE164prefix:@"441624"];
    [self addE164prefix:@"45"];
    [self addE164prefix:@"46"];
    [self addE164prefix:@"47"];
    [self addE164prefix:@"48"];
    [self addE164prefix:@"49"];
    [self addE164prefix:@"500"];
    [self addE164prefix:@"501"];
    [self addE164prefix:@"502"];
    [self addE164prefix:@"503"];
    [self addE164prefix:@"504"];
    [self addE164prefix:@"505"];
    [self addE164prefix:@"506"];
    [self addE164prefix:@"507"];
    [self addE164prefix:@"508"];
    [self addE164prefix:@"509"];
    [self addE164prefix:@"51"];
    [self addE164prefix:@"52"];
    [self addE164prefix:@"53"];
    [self addE164prefix:@"54"];
    [self addE164prefix:@"55"];
    [self addE164prefix:@"56"];
    [self addE164prefix:@"57"];
    [self addE164prefix:@"58"];
    [self addE164prefix:@"590"];
    [self addE164prefix:@"591"];
    [self addE164prefix:@"592"];
    [self addE164prefix:@"593"];
    [self addE164prefix:@"595"];
    [self addE164prefix:@"597"];
    [self addE164prefix:@"598"];
    [self addE164prefix:@"599"];
    [self addE164prefix:@"60"];
    [self addE164prefix:@"61"];
    [self addE164prefix:@"62"];
    [self addE164prefix:@"63"];
    [self addE164prefix:@"64"];
    [self addE164prefix:@"65"];
    [self addE164prefix:@"66"];
    [self addE164prefix:@"670"];
    [self addE164prefix:@"672"];
    [self addE164prefix:@"673"];
    [self addE164prefix:@"674"];
    [self addE164prefix:@"675"];
    [self addE164prefix:@"676"];
    [self addE164prefix:@"677"];
    [self addE164prefix:@"678"];
    [self addE164prefix:@"679"];
    [self addE164prefix:@"680"];
    [self addE164prefix:@"681"];
    [self addE164prefix:@"682"];
    [self addE164prefix:@"683"];
    [self addE164prefix:@"685"];
    [self addE164prefix:@"686"];
    [self addE164prefix:@"687"];
    [self addE164prefix:@"688"];
    [self addE164prefix:@"689"];
    [self addE164prefix:@"690"];
    [self addE164prefix:@"691"];
    [self addE164prefix:@"692"];
    [self addE164prefix:@"7"];
    [self addE164prefix:@"8"];
    [self addE164prefix:@"800"];
    [self addE164prefix:@"81"];
    [self addE164prefix:@"82"];
    [self addE164prefix:@"84"];
    [self addE164prefix:@"850"];
    [self addE164prefix:@"852"];
    [self addE164prefix:@"853"];
    [self addE164prefix:@"855"];
    [self addE164prefix:@"856"];
    [self addE164prefix:@"86"];
    [self addE164prefix:@"880"];
    [self addE164prefix:@"882"];
    [self addE164prefix:@"886"];
    [self addE164prefix:@"9"];
    [self addE164prefix:@"90"];
    [self addE164prefix:@"91"];
    [self addE164prefix:@"92"];
    [self addE164prefix:@"93"];
    [self addE164prefix:@"94"];
    [self addE164prefix:@"95"];
    [self addE164prefix:@"960"];
    [self addE164prefix:@"961"];
    [self addE164prefix:@"962"];
    [self addE164prefix:@"963"];
    [self addE164prefix:@"964"];
    [self addE164prefix:@"965"];
    [self addE164prefix:@"966"];
    [self addE164prefix:@"967"];
    [self addE164prefix:@"968"];
    [self addE164prefix:@"970"];
    [self addE164prefix:@"971"];
    [self addE164prefix:@"972"];
    [self addE164prefix:@"973"];
    [self addE164prefix:@"974"];
    [self addE164prefix:@"975"];
    [self addE164prefix:@"976"];
    [self addE164prefix:@"977"];
    [self addE164prefix:@"979"];
    [self addE164prefix:@"98"];
    [self addE164prefix:@"992"];
    [self addE164prefix:@"993"];
    [self addE164prefix:@"994"];
    [self addE164prefix:@"995"];
    [self addE164prefix:@"996"];
    [self addE164prefix:@"998"];
}

- (void)addCountryPrefixesE214
{
    [self addE214prefix:@"1"];
    [self addE214prefix:@"1201"];
    [self addE214prefix:@"1202"];
    [self addE214prefix:@"1203"];
    [self addE214prefix:@"1204"];
    [self addE214prefix:@"1205"];
    [self addE214prefix:@"1206"];
    [self addE214prefix:@"1207"];
    [self addE214prefix:@"1208"];
    [self addE214prefix:@"1209"];
    [self addE214prefix:@"1210"];
    [self addE214prefix:@"1212"];
    [self addE214prefix:@"1213"];
    [self addE214prefix:@"1214"];
    [self addE214prefix:@"1215"];
    [self addE214prefix:@"1216"];
    [self addE214prefix:@"1217"];
    [self addE214prefix:@"1218"];
    [self addE214prefix:@"1219"];
    [self addE214prefix:@"1220"];
    [self addE214prefix:@"1223"];
    [self addE214prefix:@"1224"];
    [self addE214prefix:@"1225"];
    [self addE214prefix:@"1226"];
    [self addE214prefix:@"1228"];
    [self addE214prefix:@"1229"];
    [self addE214prefix:@"1231"];
    [self addE214prefix:@"1234"];
    [self addE214prefix:@"1236"];
    [self addE214prefix:@"1239"];
    [self addE214prefix:@"1240"];
    [self addE214prefix:@"1242"];
    [self addE214prefix:@"1246"];
    [self addE214prefix:@"1248"];
    [self addE214prefix:@"1249"];
    [self addE214prefix:@"1250"];
    [self addE214prefix:@"1251"];
    [self addE214prefix:@"1252"];
    [self addE214prefix:@"1253"];
    [self addE214prefix:@"1254"];
    [self addE214prefix:@"1256"];
    [self addE214prefix:@"1260"];
    [self addE214prefix:@"1262"];
    [self addE214prefix:@"1264"];
    [self addE214prefix:@"1267"];
    [self addE214prefix:@"1268"];
    [self addE214prefix:@"1270"];
    [self addE214prefix:@"1272"];
    [self addE214prefix:@"1276"];
    [self addE214prefix:@"1279"];
    [self addE214prefix:@"1281"];
    [self addE214prefix:@"1284"];
    [self addE214prefix:@"1289"];
    [self addE214prefix:@"1301"];
    [self addE214prefix:@"1304"];
    [self addE214prefix:@"1305"];
    [self addE214prefix:@"1306"];
    [self addE214prefix:@"1307"];
    [self addE214prefix:@"1308"];
    [self addE214prefix:@"1309"];
    [self addE214prefix:@"1312"];
    [self addE214prefix:@"1313"];
    [self addE214prefix:@"1314"];
    [self addE214prefix:@"1315"];
    [self addE214prefix:@"1316"];
    [self addE214prefix:@"1317"];
    [self addE214prefix:@"1318"];
    [self addE214prefix:@"1319"];
    [self addE214prefix:@"1320"];
    [self addE214prefix:@"1321"];
    [self addE214prefix:@"1323"];
    [self addE214prefix:@"1325"];
    [self addE214prefix:@"1330"];
    [self addE214prefix:@"1331"];
    [self addE214prefix:@"1332"];
    [self addE214prefix:@"1334"];
    [self addE214prefix:@"1336"];
    [self addE214prefix:@"1337"];
    [self addE214prefix:@"1339"];
    [self addE214prefix:@"1343"];
    [self addE214prefix:@"1345"];
    [self addE214prefix:@"1346"];
    [self addE214prefix:@"1347"];
    [self addE214prefix:@"1351"];
    [self addE214prefix:@"1352"];
    [self addE214prefix:@"1365"];
    [self addE214prefix:@"1367"];
    [self addE214prefix:@"1380"];
    [self addE214prefix:@"1385"];
    [self addE214prefix:@"1386"];
    [self addE214prefix:@"1401"];
    [self addE214prefix:@"1402"];
    [self addE214prefix:@"1403"];
    [self addE214prefix:@"1404"];
    [self addE214prefix:@"1405"];
    [self addE214prefix:@"1406"];
    [self addE214prefix:@"1407"];
    [self addE214prefix:@"1408"];
    [self addE214prefix:@"1409"];
    [self addE214prefix:@"1410"];
    [self addE214prefix:@"1412"];
    [self addE214prefix:@"1413"];
    [self addE214prefix:@"1414"];
    [self addE214prefix:@"1415"];
    [self addE214prefix:@"1416"];
    [self addE214prefix:@"1417"];
    [self addE214prefix:@"1418"];
    [self addE214prefix:@"1419"];
    [self addE214prefix:@"1423"];
    [self addE214prefix:@"1424"];
    [self addE214prefix:@"1425"];
    [self addE214prefix:@"1428"];
    [self addE214prefix:@"1430"];
    [self addE214prefix:@"1431"];
    [self addE214prefix:@"1432"];
    [self addE214prefix:@"1434"];
    [self addE214prefix:@"1435"];
    [self addE214prefix:@"1437"];
    [self addE214prefix:@"1438"];
    [self addE214prefix:@"1440"];
    [self addE214prefix:@"1441"];
    [self addE214prefix:@"1442"];
    [self addE214prefix:@"1443"];
    [self addE214prefix:@"1445"];
    [self addE214prefix:@"1450"];
    [self addE214prefix:@"1458"];
    [self addE214prefix:@"1463"];
    [self addE214prefix:@"1469"];
    [self addE214prefix:@"1470"];
    [self addE214prefix:@"1475"];
    [self addE214prefix:@"1478"];
    [self addE214prefix:@"1479"];
    [self addE214prefix:@"1480"];
    [self addE214prefix:@"1484"];
    [self addE214prefix:@"1501"];
    [self addE214prefix:@"1502"];
    [self addE214prefix:@"1503"];
    [self addE214prefix:@"1504"];
    [self addE214prefix:@"1505"];
    [self addE214prefix:@"1506"];
    [self addE214prefix:@"1507"];
    [self addE214prefix:@"1508"];
    [self addE214prefix:@"1509"];
    [self addE214prefix:@"1510"];
    [self addE214prefix:@"1512"];
    [self addE214prefix:@"1513"];
    [self addE214prefix:@"1514"];
    [self addE214prefix:@"1515"];
    [self addE214prefix:@"1516"];
    [self addE214prefix:@"1517"];
    [self addE214prefix:@"1518"];
    [self addE214prefix:@"1519"];
    [self addE214prefix:@"1520"];
    [self addE214prefix:@"1530"];
    [self addE214prefix:@"1531"];
    [self addE214prefix:@"1534"];
    [self addE214prefix:@"1539"];
    [self addE214prefix:@"1540"];
    [self addE214prefix:@"1541"];
    [self addE214prefix:@"1548"];
    [self addE214prefix:@"1551"];
    [self addE214prefix:@"1559"];
    [self addE214prefix:@"1561"];
    [self addE214prefix:@"1562"];
    [self addE214prefix:@"1563"];
    [self addE214prefix:@"1564"];
    [self addE214prefix:@"1567"];
    [self addE214prefix:@"1570"];
    [self addE214prefix:@"1571"];
    [self addE214prefix:@"1573"];
    [self addE214prefix:@"1574"];
    [self addE214prefix:@"1575"];
    [self addE214prefix:@"1579"];
    [self addE214prefix:@"1580"];
    [self addE214prefix:@"1581"];
    [self addE214prefix:@"1585"];
    [self addE214prefix:@"1586"];
    [self addE214prefix:@"1587"];
    [self addE214prefix:@"1601"];
    [self addE214prefix:@"1602"];
    [self addE214prefix:@"1603"];
    [self addE214prefix:@"1604"];
    [self addE214prefix:@"1605"];
    [self addE214prefix:@"1606"];
    [self addE214prefix:@"1607"];
    [self addE214prefix:@"1608"];
    [self addE214prefix:@"1609"];
    [self addE214prefix:@"1610"];
    [self addE214prefix:@"1612"];
    [self addE214prefix:@"1613"];
    [self addE214prefix:@"1614"];
    [self addE214prefix:@"1615"];
    [self addE214prefix:@"1616"];
    [self addE214prefix:@"1617"];
    [self addE214prefix:@"1618"];
    [self addE214prefix:@"1619"];
    [self addE214prefix:@"1620"];
    [self addE214prefix:@"1623"];
    [self addE214prefix:@"1626"];
    [self addE214prefix:@"1628"];
    [self addE214prefix:@"1629"];
    [self addE214prefix:@"1630"];
    [self addE214prefix:@"1631"];
    [self addE214prefix:@"1636"];
    [self addE214prefix:@"1639"];
    [self addE214prefix:@"1641"];
    [self addE214prefix:@"1646"];
    [self addE214prefix:@"1647"];
    [self addE214prefix:@"1650"];
    [self addE214prefix:@"1651"];
    [self addE214prefix:@"1657"];
    [self addE214prefix:@"1660"];
    [self addE214prefix:@"1661"];
    [self addE214prefix:@"1662"];
    [self addE214prefix:@"1667"];
    [self addE214prefix:@"1669"];
    [self addE214prefix:@"1671"];
    [self addE214prefix:@"1672"];
    [self addE214prefix:@"1678"];
    [self addE214prefix:@"1680"];
    [self addE214prefix:@"1681"];
    [self addE214prefix:@"1682"];
    [self addE214prefix:@"1684"];
    [self addE214prefix:@"1701"];
    [self addE214prefix:@"1702"];
    [self addE214prefix:@"1703"];
    [self addE214prefix:@"1704"];
    [self addE214prefix:@"1705"];
    [self addE214prefix:@"1706"];
    [self addE214prefix:@"1707"];
    [self addE214prefix:@"1708"];
    [self addE214prefix:@"1709"];
    [self addE214prefix:@"1712"];
    [self addE214prefix:@"1713"];
    [self addE214prefix:@"1714"];
    [self addE214prefix:@"1715"];
    [self addE214prefix:@"1716"];
    [self addE214prefix:@"1717"];
    [self addE214prefix:@"1718"];
    [self addE214prefix:@"1719"];
    [self addE214prefix:@"1720"];
    [self addE214prefix:@"1724"];
    [self addE214prefix:@"1725"];
    [self addE214prefix:@"1726"];
    [self addE214prefix:@"1727"];
    [self addE214prefix:@"1731"];
    [self addE214prefix:@"1732"];
    [self addE214prefix:@"1734"];
    [self addE214prefix:@"1737"];
    [self addE214prefix:@"1740"];
    [self addE214prefix:@"1743"];
    [self addE214prefix:@"1747"];
    [self addE214prefix:@"1754"];
    [self addE214prefix:@"1757"];
    [self addE214prefix:@"1760"];
    [self addE214prefix:@"1762"];
    [self addE214prefix:@"1763"];
    [self addE214prefix:@"1765"];
    [self addE214prefix:@"1769"];
    [self addE214prefix:@"1770"];
    [self addE214prefix:@"1772"];
    [self addE214prefix:@"1773"];
    [self addE214prefix:@"1774"];
    [self addE214prefix:@"1775"];
    [self addE214prefix:@"1778"];
    [self addE214prefix:@"1779"];
    [self addE214prefix:@"1780"];
    [self addE214prefix:@"1781"];
    [self addE214prefix:@"1782"];
    [self addE214prefix:@"1785"];
    [self addE214prefix:@"1786"];
    [self addE214prefix:@"1801"];
    [self addE214prefix:@"1802"];
    [self addE214prefix:@"1803"];
    [self addE214prefix:@"1804"];
    [self addE214prefix:@"1805"];
    [self addE214prefix:@"1806"];
    [self addE214prefix:@"1807"];
    [self addE214prefix:@"1808"];
    [self addE214prefix:@"1810"];
    [self addE214prefix:@"1812"];
    [self addE214prefix:@"1813"];
    [self addE214prefix:@"1814"];
    [self addE214prefix:@"1815"];
    [self addE214prefix:@"1816"];
    [self addE214prefix:@"1817"];
    [self addE214prefix:@"1818"];
    [self addE214prefix:@"1819"];
    [self addE214prefix:@"1820"];
    [self addE214prefix:@"1825"];
    [self addE214prefix:@"1828"];
    [self addE214prefix:@"1830"];
    [self addE214prefix:@"1831"];
    [self addE214prefix:@"1832"];
    [self addE214prefix:@"1838"];
    [self addE214prefix:@"1843"];
    [self addE214prefix:@"1845"];
    [self addE214prefix:@"1847"];
    [self addE214prefix:@"1848"];
    [self addE214prefix:@"1850"];
    [self addE214prefix:@"1854"];
    [self addE214prefix:@"1856"];
    [self addE214prefix:@"1857"];
    [self addE214prefix:@"1858"];
    [self addE214prefix:@"1859"];
    [self addE214prefix:@"1860"];
    [self addE214prefix:@"1862"];
    [self addE214prefix:@"1863"];
    [self addE214prefix:@"1864"];
    [self addE214prefix:@"1865"];
    [self addE214prefix:@"1867"];
    [self addE214prefix:@"1870"];
    [self addE214prefix:@"1872"];
    [self addE214prefix:@"1873"];
    [self addE214prefix:@"1878"];
    [self addE214prefix:@"1879"];
    [self addE214prefix:@"1901"];
    [self addE214prefix:@"1902"];
    [self addE214prefix:@"1903"];
    [self addE214prefix:@"1904"];
    [self addE214prefix:@"1905"];
    [self addE214prefix:@"1906"];
    [self addE214prefix:@"1907"];
    [self addE214prefix:@"1908"];
    [self addE214prefix:@"1909"];
    [self addE214prefix:@"1910"];
    [self addE214prefix:@"1912"];
    [self addE214prefix:@"1913"];
    [self addE214prefix:@"1914"];
    [self addE214prefix:@"1915"];
    [self addE214prefix:@"1916"];
    [self addE214prefix:@"1917"];
    [self addE214prefix:@"1918"];
    [self addE214prefix:@"1919"];
    [self addE214prefix:@"1920"];
    [self addE214prefix:@"1925"];
    [self addE214prefix:@"1928"];
    [self addE214prefix:@"1929"];
    [self addE214prefix:@"1930"];
    [self addE214prefix:@"1931"];
    [self addE214prefix:@"1934"];
    [self addE214prefix:@"1936"];
    [self addE214prefix:@"1937"];
    [self addE214prefix:@"1938"];
    [self addE214prefix:@"1940"];
    [self addE214prefix:@"1941"];
    [self addE214prefix:@"1947"];
    [self addE214prefix:@"1949"];
    [self addE214prefix:@"1951"];
    [self addE214prefix:@"1952"];
    [self addE214prefix:@"1954"];
    [self addE214prefix:@"1956"];
    [self addE214prefix:@"1959"];
    [self addE214prefix:@"1970"];
    [self addE214prefix:@"1971"];
    [self addE214prefix:@"1972"];
    [self addE214prefix:@"1973"];
    [self addE214prefix:@"1978"];
    [self addE214prefix:@"1979"];
    [self addE214prefix:@"1980"];
    [self addE214prefix:@"1984"];
    [self addE214prefix:@"1985"];
    [self addE214prefix:@"1986"];
    [self addE214prefix:@"1989"];
    [self addE214prefix:@"20"];
    [self addE214prefix:@"211"];
    [self addE214prefix:@"212"];
    [self addE214prefix:@"213"];
    [self addE214prefix:@"216"];
    [self addE214prefix:@"218"];
    [self addE214prefix:@"220"];
    [self addE214prefix:@"221"];
    [self addE214prefix:@"222"];
    [self addE214prefix:@"223"];
    [self addE214prefix:@"224"];
    [self addE214prefix:@"225"];
    [self addE214prefix:@"226"];
    [self addE214prefix:@"227"];
    [self addE214prefix:@"228"];
    [self addE214prefix:@"229"];
    [self addE214prefix:@"230"];
    [self addE214prefix:@"231"];
    [self addE214prefix:@"232"];
    [self addE214prefix:@"233"];
    [self addE214prefix:@"234"];
    [self addE214prefix:@"235"];
    [self addE214prefix:@"236"];
    [self addE214prefix:@"237"];
    [self addE214prefix:@"238"];
    [self addE214prefix:@"239"];
    [self addE214prefix:@"240"];
    [self addE214prefix:@"241"];
    [self addE214prefix:@"242"];
    [self addE214prefix:@"243"];
    [self addE214prefix:@"244"];
    [self addE214prefix:@"245"];
    [self addE214prefix:@"246"];
    [self addE214prefix:@"248"];
    [self addE214prefix:@"249"];
    [self addE214prefix:@"250"];
    [self addE214prefix:@"251"];
    [self addE214prefix:@"252"];
    [self addE214prefix:@"253"];
    [self addE214prefix:@"254"];
    [self addE214prefix:@"255"];
    [self addE214prefix:@"256"];
    [self addE214prefix:@"257"];
    [self addE214prefix:@"258"];
    [self addE214prefix:@"260"];
    [self addE214prefix:@"261"];
    [self addE214prefix:@"262"];
    [self addE214prefix:@"263"];
    [self addE214prefix:@"264"];
    [self addE214prefix:@"265"];
    [self addE214prefix:@"266"];
    [self addE214prefix:@"267"];
    [self addE214prefix:@"268"];
    [self addE214prefix:@"269"];
    [self addE214prefix:@"27"];
    [self addE214prefix:@"290"];
    [self addE214prefix:@"291"];
    [self addE214prefix:@"297"];
    [self addE214prefix:@"298"];
    [self addE214prefix:@"299"];
    [self addE214prefix:@"30"];
    [self addE214prefix:@"31"];
    [self addE214prefix:@"32"];
    [self addE214prefix:@"33"];
    [self addE214prefix:@"34"];
    [self addE214prefix:@"350"];
    [self addE214prefix:@"351"];
    [self addE214prefix:@"352"];
    [self addE214prefix:@"353"];
    [self addE214prefix:@"354"];
    [self addE214prefix:@"355"];
    [self addE214prefix:@"356"];
    [self addE214prefix:@"357"];
    [self addE214prefix:@"358"];
    [self addE214prefix:@"359"];
    [self addE214prefix:@"36"];
    [self addE214prefix:@"370"];
    [self addE214prefix:@"371"];
    [self addE214prefix:@"372"];
    [self addE214prefix:@"373"];
    [self addE214prefix:@"374"];
    [self addE214prefix:@"375"];
    [self addE214prefix:@"376"];
    [self addE214prefix:@"377"];
    [self addE214prefix:@"378"];
    [self addE214prefix:@"379"];
    [self addE214prefix:@"380"];
    [self addE214prefix:@"381"];
    [self addE214prefix:@"382"];
    [self addE214prefix:@"383"];
    [self addE214prefix:@"385"];
    [self addE214prefix:@"386"];
    [self addE214prefix:@"387"];
    [self addE214prefix:@"389"];
    [self addE214prefix:@"39"];
    [self addE214prefix:@"40"];
    [self addE214prefix:@"41"];
    [self addE214prefix:@"420"];
    [self addE214prefix:@"421"];
    [self addE214prefix:@"423"];
    [self addE214prefix:@"43"];
    [self addE214prefix:@"44"];
    [self addE214prefix:@"441481"];
    [self addE214prefix:@"441534"];
    [self addE214prefix:@"441624"];
    [self addE214prefix:@"45"];
    [self addE214prefix:@"46"];
    [self addE214prefix:@"47"];
    [self addE214prefix:@"48"];
    [self addE214prefix:@"49"];
    [self addE214prefix:@"500"];
    [self addE214prefix:@"501"];
    [self addE214prefix:@"502"];
    [self addE214prefix:@"503"];
    [self addE214prefix:@"504"];
    [self addE214prefix:@"505"];
    [self addE214prefix:@"506"];
    [self addE214prefix:@"507"];
    [self addE214prefix:@"508"];
    [self addE214prefix:@"509"];
    [self addE214prefix:@"51"];
    [self addE214prefix:@"52"];
    [self addE214prefix:@"53"];
    [self addE214prefix:@"54"];
    [self addE214prefix:@"55"];
    [self addE214prefix:@"56"];
    [self addE214prefix:@"57"];
    [self addE214prefix:@"58"];
    [self addE214prefix:@"590"];
    [self addE214prefix:@"591"];
    [self addE214prefix:@"592"];
    [self addE214prefix:@"593"];
    [self addE214prefix:@"595"];
    [self addE214prefix:@"597"];
    [self addE214prefix:@"598"];
    [self addE214prefix:@"599"];
    [self addE214prefix:@"60"];
    [self addE214prefix:@"61"];
    [self addE214prefix:@"62"];
    [self addE214prefix:@"63"];
    [self addE214prefix:@"64"];
    [self addE214prefix:@"65"];
    [self addE214prefix:@"66"];
    [self addE214prefix:@"670"];
    [self addE214prefix:@"672"];
    [self addE214prefix:@"673"];
    [self addE214prefix:@"674"];
    [self addE214prefix:@"675"];
    [self addE214prefix:@"676"];
    [self addE214prefix:@"677"];
    [self addE214prefix:@"678"];
    [self addE214prefix:@"679"];
    [self addE214prefix:@"680"];
    [self addE214prefix:@"681"];
    [self addE214prefix:@"682"];
    [self addE214prefix:@"683"];
    [self addE214prefix:@"685"];
    [self addE214prefix:@"686"];
    [self addE214prefix:@"687"];
    [self addE214prefix:@"688"];
    [self addE214prefix:@"689"];
    [self addE214prefix:@"690"];
    [self addE214prefix:@"691"];
    [self addE214prefix:@"692"];
    [self addE214prefix:@"7"];
    [self addE214prefix:@"8"];
    [self addE214prefix:@"81"];
    [self addE214prefix:@"82"];
    [self addE214prefix:@"84"];
    [self addE214prefix:@"850"];
    [self addE214prefix:@"852"];
    [self addE214prefix:@"853"];
    [self addE214prefix:@"855"];
    [self addE214prefix:@"856"];
    [self addE214prefix:@"86"];
    [self addE214prefix:@"880"];
    [self addE214prefix:@"886"];
    [self addE214prefix:@"882"];
    [self addE214prefix:@"9"];
    [self addE214prefix:@"90"];
    [self addE214prefix:@"91"];
    [self addE214prefix:@"92"];
    [self addE214prefix:@"93"];
    [self addE214prefix:@"94"];
    [self addE214prefix:@"95"];
    [self addE214prefix:@"960"];
    [self addE214prefix:@"961"];
    [self addE214prefix:@"962"];
    [self addE214prefix:@"963"];
    [self addE214prefix:@"964"];
    [self addE214prefix:@"965"];
    [self addE214prefix:@"966"];
    [self addE214prefix:@"967"];
    [self addE214prefix:@"968"];
    [self addE214prefix:@"970"];
    [self addE214prefix:@"971"];
    [self addE214prefix:@"972"];
    [self addE214prefix:@"973"];
    [self addE214prefix:@"974"];
    [self addE214prefix:@"975"];
    [self addE214prefix:@"976"];
    [self addE214prefix:@"977"];
    [self addE214prefix:@"979"];
    [self addE214prefix:@"98"];
    [self addE214prefix:@"992"];
    [self addE214prefix:@"993"];
    [self addE214prefix:@"994"];
    [self addE214prefix:@"995"];
    [self addE214prefix:@"996"];
    [self addE214prefix:@"998"];
}

@end
