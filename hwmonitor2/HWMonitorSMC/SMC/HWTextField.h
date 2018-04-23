//
//  HWTextField.h
//  HWMonitorSMC
//
//  Created by vectorsigma on 02/01/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifdef OLD_XCODE
typedef NSInteger NSControlStateValue;
#endif

@interface HWTextField : NSTextField 
@property (nonatomic, assign) id representedObject;
@property NSInteger state;
//@property  NSControlStateValue state;
@end
