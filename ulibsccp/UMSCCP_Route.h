//
//  UMSCCP_Route.h
//  ulibsccp
//
//  Created by Andreas Fink on 15.07.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>


@interface UMSCCP_Route : UMObject
{
    BOOL                    _deliverLocal;
    SccpDestinationGroup    *destinationGroup;

}
@end

NS_ASSUME_NONNULL_END
