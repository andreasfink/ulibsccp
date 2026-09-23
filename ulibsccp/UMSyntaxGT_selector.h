//
//  UMSyntaxGT_selector.h
//  ulibgt
//
//  Created by Andreas Fink on 28.03.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibmtp3/ulibmtp3.h>

@interface UMSyntaxGT_selector : UMSyntaxToken
{

}

- (UMSyntaxGT_selector *)initWithDelegate:(id<UMCommandActionProtocol>)delegate;


@end
