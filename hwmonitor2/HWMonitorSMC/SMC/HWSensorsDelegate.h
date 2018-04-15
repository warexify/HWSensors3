//
//  HWSensorsDelegate.h
//  HWMonitorSMC
//
//  Created by vector sigma on 24/02/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "HWMonitorSensor.h"

@interface HWSensorsDelegate : NSObject {
  NSDictionary *          BatteriesList;
}

@property (readwrite, assign) BOOL smartSupported;

- (NSArray *)getMemory;
  
- (NSArray *)getAllOtherTemperatures;

- (NSArray *)getCPUTemperatures;

- (NSArray *)getCPUFrequencies;

- (NSArray *)getOtherFrequencies;

- (NSArray *)getMultipliers;

- (NSArray *)getVoltages;

- (NSArray *)getFans;

- (NSArray *)getBattery;

- (NSArray *)getGenericBatteries;
@end
