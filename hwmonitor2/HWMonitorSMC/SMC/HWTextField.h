//
//  HWTextField.h
//  HWMonitorSMC
//
//  Created by vectorsigma on 02/01/18.
//

#import <Cocoa/Cocoa.h>

@interface HWTextField : NSTextField 
@property (nonatomic, assign) id representedObject;
@property  NSControlStateValue state;
@end
