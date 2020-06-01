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


static dbFieldDef UMSCCP_StatisticDb_fields[] =
{
    {"key",                 NULL,       NO,     DB_PRIMARY_INDEX,   DB_FIELD_TYPE_STRING,              255,   0,NULL,NULL,1},
    {"ymdh",                NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              10,    0,NULL,NULL,2},
    {"instance",            NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,    0,NULL,NULL,3},
    {"incoming_linkset",    NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,    0,NULL,NULL,4},
    {"outgoing_linkset",    NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,    0,NULL,NULL,5},
    {"calling_prefix",      NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,    0,NULL,NULL,6},
    {"called_prefix",       NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,    0,NULL,NULL,7},
    {"called_prefix",       NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,    0,NULL,NULL,8},
    {"gtt_selector",        NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,    0,NULL,NULL,9},
    {"sccp_operation",      NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_INTEGER,             0,     0,NULL,NULL,10},
    {"msu_count",           NULL,       NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_INTEGER,             0,     0,NULL,NULL,11},
    {"bytes_count",         NULL,       NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_INTEGER,             0,     0,NULL,NULL,12},
    { "",                   NULL,       NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_END,                 0,     0,NULL,NULL,13},
};

@implementation UMSCCP_StatisticDb

- (UMSCCP_StatisticDb *)initWithPoolName:(NSString *)pool
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
                                   @"pool-name"  : pool };
        _table = [[UMDbTable alloc]initWithConfig:config andPools:appContext.dbPools];
        _lock = [[UMMutex alloc]initWithName:@"UMMTP3StatisticDb-lock"];
        _entries = [[UMSynchronizedDictionary alloc]init];
        _instance = instance;
        _e164 = [[UMSynchronizedDictionary alloc]init];
        _e212 = [[UMSynchronizedDictionary alloc]init];
        _e214 = [[UMSynchronizedDictionary alloc]init];
        [self addCountryPrefixes:_e164];
        [self addCountryPrefixes:_e214];
        [self addMncPrefixes:_e212];

        NSTimeZone *tz = [NSTimeZone timeZoneWithName:@"UTC"];
        NSDateFormatter *_ymdhDateFormatter= [[NSDateFormatter alloc]init];
        NSLocale *ukLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_UK"];
        [_ymdhDateFormatter setLocale:ukLocale];
        [_ymdhDateFormatter setDateFormat:@"yyyyMMddHH"];
        [_ymdhDateFormatter setTimeZone:tz];
    }
    return self;
}

- (void)doAutocreate
{
    UMDbSession *session = [_table.pool grabSession:__FILE__ line:__LINE__ func:__func__];
    [_table autoCreate:UMSCCP_StatisticDb_fields session:session];
    [_table.pool returnSession:session file:__FILE__ line:__LINE__ func:__func__];
}


- (void)addByteCount:(int)byteCount
     incomingLinkset:(NSString *)incomingLinkset
     outgoingLinkset:(NSString *)outgoingLinkset
       callingPrefix:(NSString *)callingPrefix
        calledPrefix:(NSString *)calledPrefix
         gttSelector:(NSString *)selector
       sccpOperation:(int)sccpOperation
{
    NSString *ymdh = [_ymdhDateFormatter stringFromDate:[NSDate date]];

    NSString *key = [UMSCCP_StatisticDbRecord keystringFor:ymdh
                                           incomingLinkset:incomingLinkset
                                           outgoingLinkset:outgoingLinkset
                                             callingPrefix:callingPrefix
                                              calledPrefix:calledPrefix
                                               gttSelector:selector
                                             sccpOperation:sccpOperation
                                                  instance:_instance];
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
        rec.instance = _instance;
        _entries[key] = rec;
    }
    [_lock unlock];
    [rec increaseMsuCount:1 byteCount:byteCount];
}

- (void)flush
{
    [_lock lock];
    UMSynchronizedDictionary *tmp = _entries;
    _entries = [[UMSynchronizedDictionary alloc]init];
    [_lock unlock];
    
    NSArray *keys = [tmp allKeys];
    for(NSString *key in keys)
    {
        UMMTP3StatisticDbRecord *rec = tmp[key];
        [rec flushToPool:_table.pool table:_table];
    }
}


- (void)addE164prefix:(NSString *)prefix
{
    _e164[prefix] = prefix;
}

- (void)addE212prefix:(NSString *)prefix
{
    
}

- (void)addE214prefix:(NSString *)prefix
{
    
}

- (NSString *)prefixOf:(NSString *)in  dict:(UMSynchronizedDictionary *)dict
{
    NSInteger n = in.length;
    for(NSInteger i=(n-1);i>0;i--)
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


- (void)addMncPrefixes:(UMSynchronizedDictionary *)dict
{
    for(int i=0;i<1000;i++)
    {
        NSString *s = [NSString stringWithFormat:@"%03d",i];
        dict[s] = s;
    }
}
- (void)addCountryPrefixes:(UMSynchronizedDictionary *)dict
{
    dict[@"1"]=@"1";
    dict[@"1201"]=@"1201";
    dict[@"1202"]=@"1202";
    dict[@"1203"]=@"1203";
    dict[@"1204"]=@"1204";
    dict[@"1205"]=@"1205";
    dict[@"1206"]=@"1206";
    dict[@"1207"]=@"1207";
    dict[@"1208"]=@"1208";
    dict[@"1209"]=@"1209";
    dict[@"1210"]=@"1210";
    dict[@"1212"]=@"1212";
    dict[@"1213"]=@"1213";
    dict[@"1214"]=@"1214";
    dict[@"1215"]=@"1215";
    dict[@"1216"]=@"1216";
    dict[@"1217"]=@"1217";
    dict[@"1218"]=@"1218";
    dict[@"1219"]=@"1219";
    dict[@"1220"]=@"1220";
    dict[@"1223"]=@"1223";
    dict[@"1224"]=@"1224";
    dict[@"1225"]=@"1225";
    dict[@"1226"]=@"1226";
    dict[@"1228"]=@"1228";
    dict[@"1229"]=@"1229";
    dict[@"1231"]=@"1231";
    dict[@"1234"]=@"1234";
    dict[@"1236"]=@"1236";
    dict[@"1239"]=@"1239";
    dict[@"1240"]=@"1240";
    dict[@"1242"]=@"1242";
    dict[@"1246"]=@"1246";
    dict[@"1248"]=@"1248";
    dict[@"1249"]=@"1249";
    dict[@"1250"]=@"1250";
    dict[@"1251"]=@"1251";
    dict[@"1252"]=@"1252";
    dict[@"1253"]=@"1253";
    dict[@"1254"]=@"1254";
    dict[@"1256"]=@"1256";
    dict[@"1260"]=@"1260";
    dict[@"1262"]=@"1262";
    dict[@"1264"]=@"1264";
    dict[@"1267"]=@"1267";
    dict[@"1268"]=@"1268";
    dict[@"1270"]=@"1270";
    dict[@"1272"]=@"1272";
    dict[@"1276"]=@"1276";
    dict[@"1279"]=@"1279";
    dict[@"1281"]=@"1281";
    dict[@"1284"]=@"1284";
    dict[@"1289"]=@"1289";
    dict[@"1301"]=@"1301";
    dict[@"1304"]=@"1304";
    dict[@"1305"]=@"1305";
    dict[@"1306"]=@"1306";
    dict[@"1307"]=@"1307";
    dict[@"1308"]=@"1308";
    dict[@"1309"]=@"1309";
    dict[@"1312"]=@"1312";
    dict[@"1313"]=@"1313";
    dict[@"1314"]=@"1314";
    dict[@"1315"]=@"1315";
    dict[@"1316"]=@"1316";
    dict[@"1317"]=@"1317";
    dict[@"1318"]=@"1318";
    dict[@"1319"]=@"1319";
    dict[@"1320"]=@"1320";
    dict[@"1321"]=@"1321";
    dict[@"1323"]=@"1323";
    dict[@"1325"]=@"1325";
    dict[@"1330"]=@"1330";
    dict[@"1331"]=@"1331";
    dict[@"1332"]=@"1332";
    dict[@"1334"]=@"1334";
    dict[@"1336"]=@"1336";
    dict[@"1337"]=@"1337";
    dict[@"1339"]=@"1339";
    dict[@"1343"]=@"1343";
    dict[@"1345"]=@"1345";
    dict[@"1346"]=@"1346";
    dict[@"1347"]=@"1347";
    dict[@"1351"]=@"1351";
    dict[@"1352"]=@"1352";
    dict[@"1365"]=@"1365";
    dict[@"1367"]=@"1367";
    dict[@"1380"]=@"1380";
    dict[@"1385"]=@"1385";
    dict[@"1386"]=@"1386";
    dict[@"1401"]=@"1401";
    dict[@"1402"]=@"1402";
    dict[@"1403"]=@"1403";
    dict[@"1404"]=@"1404";
    dict[@"1405"]=@"1405";
    dict[@"1406"]=@"1406";
    dict[@"1407"]=@"1407";
    dict[@"1408"]=@"1408";
    dict[@"1409"]=@"1409";
    dict[@"1410"]=@"1410";
    dict[@"1412"]=@"1412";
    dict[@"1413"]=@"1413";
    dict[@"1414"]=@"1414";
    dict[@"1415"]=@"1415";
    dict[@"1416"]=@"1416";
    dict[@"1417"]=@"1417";
    dict[@"1418"]=@"1418";
    dict[@"1419"]=@"1419";
    dict[@"1423"]=@"1423";
    dict[@"1424"]=@"1424";
    dict[@"1425"]=@"1425";
    dict[@"1428"]=@"1428";
    dict[@"1430"]=@"1430";
    dict[@"1431"]=@"1431";
    dict[@"1432"]=@"1432";
    dict[@"1434"]=@"1434";
    dict[@"1435"]=@"1435";
    dict[@"1437"]=@"1437";
    dict[@"1438"]=@"1438";
    dict[@"1440"]=@"1440";
    dict[@"1441"]=@"1441";
    dict[@"1442"]=@"1442";
    dict[@"1443"]=@"1443";
    dict[@"1445"]=@"1445";
    dict[@"1450"]=@"1450";
    dict[@"1458"]=@"1458";
    dict[@"1463"]=@"1463";
    dict[@"1469"]=@"1469";
    dict[@"1470"]=@"1470";
    dict[@"1475"]=@"1475";
    dict[@"1478"]=@"1478";
    dict[@"1479"]=@"1479";
    dict[@"1480"]=@"1480";
    dict[@"1484"]=@"1484";
    dict[@"1501"]=@"1501";
    dict[@"1502"]=@"1502";
    dict[@"1503"]=@"1503";
    dict[@"1504"]=@"1504";
    dict[@"1505"]=@"1505";
    dict[@"1506"]=@"1506";
    dict[@"1507"]=@"1507";
    dict[@"1508"]=@"1508";
    dict[@"1509"]=@"1509";
    dict[@"1510"]=@"1510";
    dict[@"1512"]=@"1512";
    dict[@"1513"]=@"1513";
    dict[@"1514"]=@"1514";
    dict[@"1515"]=@"1515";
    dict[@"1516"]=@"1516";
    dict[@"1517"]=@"1517";
    dict[@"1518"]=@"1518";
    dict[@"1519"]=@"1519";
    dict[@"1520"]=@"1520";
    dict[@"1530"]=@"1530";
    dict[@"1531"]=@"1531";
    dict[@"1534"]=@"1534";
    dict[@"1539"]=@"1539";
    dict[@"1540"]=@"1540";
    dict[@"1541"]=@"1541";
    dict[@"1548"]=@"1548";
    dict[@"1551"]=@"1551";
    dict[@"1559"]=@"1559";
    dict[@"1561"]=@"1561";
    dict[@"1562"]=@"1562";
    dict[@"1563"]=@"1563";
    dict[@"1564"]=@"1564";
    dict[@"1567"]=@"1567";
    dict[@"1570"]=@"1570";
    dict[@"1571"]=@"1571";
    dict[@"1573"]=@"1573";
    dict[@"1574"]=@"1574";
    dict[@"1575"]=@"1575";
    dict[@"1579"]=@"1579";
    dict[@"1580"]=@"1580";
    dict[@"1581"]=@"1581";
    dict[@"1585"]=@"1585";
    dict[@"1586"]=@"1586";
    dict[@"1587"]=@"1587";
    dict[@"1601"]=@"1601";
    dict[@"1602"]=@"1602";
    dict[@"1603"]=@"1603";
    dict[@"1604"]=@"1604";
    dict[@"1605"]=@"1605";
    dict[@"1606"]=@"1606";
    dict[@"1607"]=@"1607";
    dict[@"1608"]=@"1608";
    dict[@"1609"]=@"1609";
    dict[@"1610"]=@"1610";
    dict[@"1612"]=@"1612";
    dict[@"1613"]=@"1613";
    dict[@"1614"]=@"1614";
    dict[@"1615"]=@"1615";
    dict[@"1616"]=@"1616";
    dict[@"1617"]=@"1617";
    dict[@"1618"]=@"1618";
    dict[@"1619"]=@"1619";
    dict[@"1620"]=@"1620";
    dict[@"1623"]=@"1623";
    dict[@"1626"]=@"1626";
    dict[@"1628"]=@"1628";
    dict[@"1629"]=@"1629";
    dict[@"1630"]=@"1630";
    dict[@"1631"]=@"1631";
    dict[@"1636"]=@"1636";
    dict[@"1639"]=@"1639";
    dict[@"1641"]=@"1641";
    dict[@"1646"]=@"1646";
    dict[@"1647"]=@"1647";
    dict[@"1650"]=@"1650";
    dict[@"1651"]=@"1651";
    dict[@"1657"]=@"1657";
    dict[@"1660"]=@"1660";
    dict[@"1661"]=@"1661";
    dict[@"1662"]=@"1662";
    dict[@"1667"]=@"1667";
    dict[@"1669"]=@"1669";
    dict[@"1671"]=@"1671";
    dict[@"1672"]=@"1672";
    dict[@"1678"]=@"1678";
    dict[@"1680"]=@"1680";
    dict[@"1681"]=@"1681";
    dict[@"1682"]=@"1682";
    dict[@"1684"]=@"1684";
    dict[@"1701"]=@"1701";
    dict[@"1702"]=@"1702";
    dict[@"1703"]=@"1703";
    dict[@"1704"]=@"1704";
    dict[@"1705"]=@"1705";
    dict[@"1706"]=@"1706";
    dict[@"1707"]=@"1707";
    dict[@"1708"]=@"1708";
    dict[@"1709"]=@"1709";
    dict[@"1712"]=@"1712";
    dict[@"1713"]=@"1713";
    dict[@"1714"]=@"1714";
    dict[@"1715"]=@"1715";
    dict[@"1716"]=@"1716";
    dict[@"1717"]=@"1717";
    dict[@"1718"]=@"1718";
    dict[@"1719"]=@"1719";
    dict[@"1720"]=@"1720";
    dict[@"1724"]=@"1724";
    dict[@"1725"]=@"1725";
    dict[@"1726"]=@"1726";
    dict[@"1727"]=@"1727";
    dict[@"1731"]=@"1731";
    dict[@"1732"]=@"1732";
    dict[@"1734"]=@"1734";
    dict[@"1737"]=@"1737";
    dict[@"1740"]=@"1740";
    dict[@"1743"]=@"1743";
    dict[@"1747"]=@"1747";
    dict[@"1754"]=@"1754";
    dict[@"1757"]=@"1757";
    dict[@"1760"]=@"1760";
    dict[@"1762"]=@"1762";
    dict[@"1763"]=@"1763";
    dict[@"1765"]=@"1765";
    dict[@"1769"]=@"1769";
    dict[@"1770"]=@"1770";
    dict[@"1772"]=@"1772";
    dict[@"1773"]=@"1773";
    dict[@"1774"]=@"1774";
    dict[@"1775"]=@"1775";
    dict[@"1778"]=@"1778";
    dict[@"1779"]=@"1779";
    dict[@"1780"]=@"1780";
    dict[@"1781"]=@"1781";
    dict[@"1782"]=@"1782";
    dict[@"1785"]=@"1785";
    dict[@"1786"]=@"1786";
    dict[@"1801"]=@"1801";
    dict[@"1802"]=@"1802";
    dict[@"1803"]=@"1803";
    dict[@"1804"]=@"1804";
    dict[@"1805"]=@"1805";
    dict[@"1806"]=@"1806";
    dict[@"1807"]=@"1807";
    dict[@"1808"]=@"1808";
    dict[@"1810"]=@"1810";
    dict[@"1812"]=@"1812";
    dict[@"1813"]=@"1813";
    dict[@"1814"]=@"1814";
    dict[@"1815"]=@"1815";
    dict[@"1816"]=@"1816";
    dict[@"1817"]=@"1817";
    dict[@"1818"]=@"1818";
    dict[@"1819"]=@"1819";
    dict[@"1820"]=@"1820";
    dict[@"1825"]=@"1825";
    dict[@"1828"]=@"1828";
    dict[@"1830"]=@"1830";
    dict[@"1831"]=@"1831";
    dict[@"1832"]=@"1832";
    dict[@"1838"]=@"1838";
    dict[@"1843"]=@"1843";
    dict[@"1845"]=@"1845";
    dict[@"1847"]=@"1847";
    dict[@"1848"]=@"1848";
    dict[@"1850"]=@"1850";
    dict[@"1854"]=@"1854";
    dict[@"1856"]=@"1856";
    dict[@"1857"]=@"1857";
    dict[@"1858"]=@"1858";
    dict[@"1859"]=@"1859";
    dict[@"1860"]=@"1860";
    dict[@"1862"]=@"1862";
    dict[@"1863"]=@"1863";
    dict[@"1864"]=@"1864";
    dict[@"1865"]=@"1865";
    dict[@"1867"]=@"1867";
    dict[@"1870"]=@"1870";
    dict[@"1872"]=@"1872";
    dict[@"1873"]=@"1873";
    dict[@"1878"]=@"1878";
    dict[@"1879"]=@"1879";
    dict[@"1901"]=@"1901";
    dict[@"1902"]=@"1902";
    dict[@"1903"]=@"1903";
    dict[@"1904"]=@"1904";
    dict[@"1905"]=@"1905";
    dict[@"1906"]=@"1906";
    dict[@"1907"]=@"1907";
    dict[@"1908"]=@"1908";
    dict[@"1909"]=@"1909";
    dict[@"1910"]=@"1910";
    dict[@"1912"]=@"1912";
    dict[@"1913"]=@"1913";
    dict[@"1914"]=@"1914";
    dict[@"1915"]=@"1915";
    dict[@"1916"]=@"1916";
    dict[@"1917"]=@"1917";
    dict[@"1918"]=@"1918";
    dict[@"1919"]=@"1919";
    dict[@"1920"]=@"1920";
    dict[@"1925"]=@"1925";
    dict[@"1928"]=@"1928";
    dict[@"1929"]=@"1929";
    dict[@"1930"]=@"1930";
    dict[@"1931"]=@"1931";
    dict[@"1934"]=@"1934";
    dict[@"1936"]=@"1936";
    dict[@"1937"]=@"1937";
    dict[@"1938"]=@"1938";
    dict[@"1940"]=@"1940";
    dict[@"1941"]=@"1941";
    dict[@"1947"]=@"1947";
    dict[@"1949"]=@"1949";
    dict[@"1951"]=@"1951";
    dict[@"1952"]=@"1952";
    dict[@"1954"]=@"1954";
    dict[@"1956"]=@"1956";
    dict[@"1959"]=@"1959";
    dict[@"1970"]=@"1970";
    dict[@"1971"]=@"1971";
    dict[@"1972"]=@"1972";
    dict[@"1973"]=@"1973";
    dict[@"1978"]=@"1978";
    dict[@"1979"]=@"1979";
    dict[@"1980"]=@"1980";
    dict[@"1984"]=@"1984";
    dict[@"1985"]=@"1985";
    dict[@"1986"]=@"1986";
    dict[@"1989"]=@"1989";
    dict[@"20"]=@"20";
    dict[@"211"]=@"211";
    dict[@"212"]=@"212";
    dict[@"213"]=@"213";
    dict[@"216"]=@"216";
    dict[@"218"]=@"218";
    dict[@"220"]=@"220";
    dict[@"221"]=@"221";
    dict[@"222"]=@"222";
    dict[@"223"]=@"223";
    dict[@"224"]=@"224";
    dict[@"225"]=@"225";
    dict[@"226"]=@"226";
    dict[@"227"]=@"227";
    dict[@"228"]=@"228";
    dict[@"229"]=@"229";
    dict[@"230"]=@"230";
    dict[@"231"]=@"231";
    dict[@"232"]=@"232";
    dict[@"233"]=@"233";
    dict[@"234"]=@"234";
    dict[@"235"]=@"235";
    dict[@"236"]=@"236";
    dict[@"237"]=@"237";
    dict[@"238"]=@"238";
    dict[@"239"]=@"239";
    dict[@"240"]=@"240";
    dict[@"241"]=@"241";
    dict[@"242"]=@"242";
    dict[@"243"]=@"243";
    dict[@"244"]=@"244";
    dict[@"245"]=@"245";
    dict[@"246"]=@"246";
    dict[@"248"]=@"248";
    dict[@"249"]=@"249";
    dict[@"250"]=@"250";
    dict[@"251"]=@"251";
    dict[@"252"]=@"252";
    dict[@"253"]=@"253";
    dict[@"254"]=@"254";
    dict[@"255"]=@"255";
    dict[@"256"]=@"256";
    dict[@"257"]=@"257";
    dict[@"258"]=@"258";
    dict[@"260"]=@"260";
    dict[@"261"]=@"261";
    dict[@"262"]=@"262";
    dict[@"263"]=@"263";
    dict[@"264"]=@"264";
    dict[@"265"]=@"265";
    dict[@"266"]=@"266";
    dict[@"267"]=@"267";
    dict[@"268"]=@"268";
    dict[@"269"]=@"269";
    dict[@"27"]=@"27";
    dict[@"290"]=@"290";
    dict[@"291"]=@"291";
    dict[@"297"]=@"297";
    dict[@"298"]=@"298";
    dict[@"299"]=@"299";
    dict[@"30"]=@"30";
    dict[@"31"]=@"31";
    dict[@"32"]=@"32";
    dict[@"33"]=@"33";
    dict[@"34"]=@"34";
    dict[@"350"]=@"350";
    dict[@"351"]=@"351";
    dict[@"352"]=@"352";
    dict[@"353"]=@"353";
    dict[@"354"]=@"354";
    dict[@"355"]=@"355";
    dict[@"356"]=@"356";
    dict[@"357"]=@"357";
    dict[@"358"]=@"358";
    dict[@"359"]=@"359";
    dict[@"36"]=@"36";
    dict[@"370"]=@"370";
    dict[@"371"]=@"371";
    dict[@"372"]=@"372";
    dict[@"373"]=@"373";
    dict[@"374"]=@"374";
    dict[@"375"]=@"375";
    dict[@"376"]=@"376";
    dict[@"377"]=@"377";
    dict[@"378"]=@"378";
    dict[@"379"]=@"379";
    dict[@"380"]=@"380";
    dict[@"381"]=@"381";
    dict[@"382"]=@"382";
    dict[@"383"]=@"383";
    dict[@"385"]=@"385";
    dict[@"386"]=@"386";
    dict[@"387"]=@"387";
    dict[@"389"]=@"389";
    dict[@"39"]=@"39";
    dict[@"40"]=@"40";
    dict[@"41"]=@"41";
    dict[@"420"]=@"420";
    dict[@"421"]=@"421";
    dict[@"423"]=@"423";
    dict[@"43"]=@"43";
    dict[@"44"]=@"44";
    dict[@"441481"]=@"441481";
    dict[@"441534"]=@"441534";
    dict[@"441624"]=@"441624";
    dict[@"45"]=@"45";
    dict[@"46"]=@"46";
    dict[@"47"]=@"47";
    dict[@"48"]=@"48";
    dict[@"49"]=@"49";
    dict[@"500"]=@"500";
    dict[@"501"]=@"501";
    dict[@"502"]=@"502";
    dict[@"503"]=@"503";
    dict[@"504"]=@"504";
    dict[@"505"]=@"505";
    dict[@"506"]=@"506";
    dict[@"507"]=@"507";
    dict[@"508"]=@"508";
    dict[@"509"]=@"509";
    dict[@"51"]=@"51";
    dict[@"52"]=@"52";
    dict[@"53"]=@"53";
    dict[@"54"]=@"54";
    dict[@"55"]=@"55";
    dict[@"56"]=@"56";
    dict[@"57"]=@"57";
    dict[@"58"]=@"58";
    dict[@"590"]=@"590";
    dict[@"591"]=@"591";
    dict[@"592"]=@"592";
    dict[@"593"]=@"593";
    dict[@"595"]=@"595";
    dict[@"597"]=@"597";
    dict[@"598"]=@"598";
    dict[@"599"]=@"599";
    dict[@"60"]=@"60";
    dict[@"61"]=@"61";
    dict[@"62"]=@"62";
    dict[@"63"]=@"63";
    dict[@"64"]=@"64";
    dict[@"65"]=@"65";
    dict[@"66"]=@"66";
    dict[@"670"]=@"670";
    dict[@"672"]=@"672";
    dict[@"673"]=@"673";
    dict[@"674"]=@"674";
    dict[@"675"]=@"675";
    dict[@"676"]=@"676";
    dict[@"677"]=@"677";
    dict[@"678"]=@"678";
    dict[@"679"]=@"679";
    dict[@"680"]=@"680";
    dict[@"681"]=@"681";
    dict[@"682"]=@"682";
    dict[@"683"]=@"683";
    dict[@"685"]=@"685";
    dict[@"686"]=@"686";
    dict[@"687"]=@"687";
    dict[@"688"]=@"688";
    dict[@"689"]=@"689";
    dict[@"690"]=@"690";
    dict[@"691"]=@"691";
    dict[@"692"]=@"692";
    dict[@"7"]=@"7";
    dict[@"81"]=@"81";
    dict[@"82"]=@"82";
    dict[@"84"]=@"84";
    dict[@"850"]=@"850";
    dict[@"852"]=@"852";
    dict[@"853"]=@"853";
    dict[@"855"]=@"855";
    dict[@"856"]=@"856";
    dict[@"86"]=@"86";
    dict[@"880"]=@"880";
    dict[@"886"]=@"886";
    dict[@"90"]=@"90";
    dict[@"91"]=@"91";
    dict[@"92"]=@"92";
    dict[@"93"]=@"93";
    dict[@"94"]=@"94";
    dict[@"95"]=@"95";
    dict[@"960"]=@"960";
    dict[@"961"]=@"961";
    dict[@"962"]=@"962";
    dict[@"963"]=@"963";
    dict[@"964"]=@"964";
    dict[@"965"]=@"965";
    dict[@"966"]=@"966";
    dict[@"967"]=@"967";
    dict[@"968"]=@"968";
    dict[@"970"]=@"970";
    dict[@"971"]=@"971";
    dict[@"972"]=@"972";
    dict[@"973"]=@"973";
    dict[@"974"]=@"974";
    dict[@"975"]=@"975";
    dict[@"976"]=@"976";
    dict[@"977"]=@"977";
    dict[@"98"]=@"98";
    dict[@"992"]=@"992";
    dict[@"993"]=@"993";
    dict[@"994"]=@"994";
    dict[@"995"]=@"995";
    dict[@"996"]=@"996";
    dict[@"998"]=@"998";
}


@end
