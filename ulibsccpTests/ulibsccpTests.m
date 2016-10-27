//
//  ulibsccpTests.m
//  ulibsccpTests
//
//  Created by Andreas Fink on 05/09/14.
//  Copyright (c) 2016 Andreas Fink
//

#import <XCTest/XCTest.h>
#import <ulib/ulib.h>
#import <ulibgt/ulibgt.h>

@interface ulibsccpTests : XCTestCase

@end

@implementation ulibsccpTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDecodeSccpAddress
{
    NSString *s = @"1208001204445723658140";
    NSData *d = [s unhexedData];
    SccpAddress *addr = [[SccpAddress alloc]initWithData:d];


    if(addr.ai.nationalReservedBit)
    {
        XCTFail(@"National bit should not be set \"%s\"", __PRETTY_FUNCTION__);
    }
    if(addr.ai.routingIndicatorBit)
    {
        XCTFail(@"routingIndicatorBit is wrong \"%s\"", __PRETTY_FUNCTION__);
    }
    if(addr.ai.globalTitleIndicator !=4)
    {
        XCTFail(@"gti is not 4 \"%s\"", __PRETTY_FUNCTION__);
    }
    if(addr.ssn.ssn !=8)
    {
        XCTFail(@"ssn is not 1 \"%s\"", __PRETTY_FUNCTION__);
    }
    if(addr.ai.pointCodeIndicator)
    {
        XCTFail(@"ai.pc is not 1 \"%s\"", __PRETTY_FUNCTION__);
    }
    if([addr.address isNotEqualTo:@"447532561804"])
    {
        XCTFail(@"address doesnt match, its %@ instead of %@", addr.address,@"447532561804" );
    }
}
@end
