//
//  HWSensorsDelegate.h
//  HWMonitorSMC
//
//  Created by vector sigma on 24/02/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISPSmartController.h"
#include "HWMonitorSensor.h"

@interface HWSensorsDelegate : NSObject {
  NSDictionary *          DisksList;
  NSDictionary *          SSDList;
  NSDictionary *          BatteriesList;
  
  ISPSmartController *    smartController;
  BOOL                    smart;
  
  NSDate *                lastcall;
  
  NSStatusBar *           statusItem;
}

@property (readwrite, assign) BOOL smartSupported;

- (NSArray *)getMemory;
  
- (NSArray *)getAllOtherTemperatures;

- (NSArray *)getCPUTemperatures;

- (NSArray *)getCPUFrequencies;

- (NSArray *)getOtherFrequencies;

- (NSArray *)getMultiplers;

- (NSArray *)getVoltages;

- (NSArray *)getFans;

- (NSArray *)getDisks;

- (NSArray *)getBattery;

- (NSArray *)getGenericBatteries;
@end
