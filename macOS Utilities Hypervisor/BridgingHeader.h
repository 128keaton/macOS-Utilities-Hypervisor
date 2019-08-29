//
//  BridgingHeader.h
//  macOS Utilities: Hypervisor
//
//  Created by Keaton Burleson on 8/28/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

#import "XLFacility.h"
#import "XLLogger.h"

#ifdef __OBJC__
#import "XLFacilityMacros.h"
#define NSLog(...) XLOG_INFO(__VA_ARGS__)
#endif
