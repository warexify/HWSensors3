//
//  HWSensorsDelegate.m
//  HWMonitorSMC
//
//  Created by vector sigma on 24/02/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

#import "HWSensorsDelegate.h"
#include <sys/sysctl.h>
#import "NSString+TruncateToWidth.h"
#import "IOBatteryStatus.h"
#include "../../../utils/definitions.h"

#define LOG_NULL_VALUES 0

int countPhisycalCores(void);

int countPhisycalCores() {
  size_t l;
  int c;
  l = sizeof(c);
  sysctlbyname("machdep.cpu.core_count", &c, &l, NULL, 0);
  return c;
}

@implementation HWSensorsDelegate
@synthesize smartSupported;
#define SMART_UPDATE_INTERVAL 5*60
- (id) init {
  self = [super init];
  if (self) {
    [self awake];
  }
  return(self);
}

- (void)awake {
  lastcall = [NSDate date];
  smartController = [[ISPSmartController alloc] init];
  if (smartController) {
    smartSupported = YES;
    [smartController getPartitions];
    [smartController update];
    DisksList = [smartController getDataSet /*:1*/];
    SSDList = [smartController getSSDLife];
  }
}

- (NSArray *)getAllOtherTemperatures {
  NSMutableArray *arr = [NSMutableArray array];
  [self validateSensorWithKey:@KEY_CPU_PROXIMITY_TEMPERATURE
                       ofType:([HWMonitorSensor getTypeOfKey:@KEY_CPU_PROXIMITY_TEMPERATURE]) ? : @TYPE_SP78
                     forGroup:TemperatureSensorGroup
                   andCaption:NSLocalizedString(@"CPU Proximity", nil)
                     intoList:arr];
  
  [self validateSensorWithKey:@KEY_CPU_HEATSINK_TEMPERATURE
                       ofType:([HWMonitorSensor getTypeOfKey:@KEY_CPU_HEATSINK_TEMPERATURE]) ? : @TYPE_SP78
                     forGroup:TemperatureSensorGroup
                   andCaption:NSLocalizedString(@"CPU Heatsink", nil)
                     intoList:arr];
  
  [self validateSensorWithKey:@KEY_NORTHBRIDGE_TEMPERATURE
                       ofType:([HWMonitorSensor getTypeOfKey:@KEY_NORTHBRIDGE_TEMPERATURE]) ? : @TYPE_SP78
                     forGroup:TemperatureSensorGroup
                   andCaption:NSLocalizedString(@"Motherboard", nil)
                     intoList:arr];
  
  [self validateSensorWithKey:@KEY_DIMM_TEMPERATURE
                       ofType:([HWMonitorSensor getTypeOfKey:@KEY_DIMM_TEMPERATURE]) ? : @TYPE_SP78
                     forGroup:TemperatureSensorGroup
                   andCaption:NSLocalizedString(@"DIMM 0", nil)
                     intoList:arr];
  
  [self validateSensorWithKey:@KEY_DIMM2_TEMPERATURE
                       ofType:([HWMonitorSensor getTypeOfKey:@KEY_DIMM2_TEMPERATURE]) ? : @TYPE_SP78
                     forGroup:TemperatureSensorGroup
                   andCaption:NSLocalizedString(@"DIMM 1", nil)
                     intoList:arr];
  
  [self validateSensorWithKey:@KEY_AMBIENT_TEMPERATURE
                       ofType:([HWMonitorSensor getTypeOfKey:@KEY_AMBIENT_TEMPERATURE]) ? : @TYPE_SP78
                     forGroup:TemperatureSensorGroup
                   andCaption:NSLocalizedString(@"Ambient", nil)
                     intoList:arr];
  
  
  for (int i=0; i<0xA; i++) {
    [self validateSensorWithKey:[NSString stringWithFormat:@KEY_FORMAT_GPU_DIODE_TEMPERATURE, i]
                         ofType:([HWMonitorSensor getTypeOfKey:
                                  [NSString stringWithFormat:@KEY_FORMAT_GPU_DIODE_TEMPERATURE, i]]) ? : @TYPE_SP78
                       forGroup:TemperatureSensorGroup
                     andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %X Core",nil) ,i]
                       intoList:arr];
    
    [self validateSensorWithKey:[NSString stringWithFormat:@KEY_FORMAT_GPU_BOARD_TEMPERATURE, i]
                         ofType:([HWMonitorSensor getTypeOfKey:
                                  [NSString stringWithFormat:@KEY_FORMAT_GPU_BOARD_TEMPERATURE, i]]) ? : @TYPE_SP78
                       forGroup:TemperatureSensorGroup
                     andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %X Board",nil) ,i]
                       intoList:arr];
    
    [self validateSensorWithKey:[NSString stringWithFormat:@KEY_FORMAT_GPU_PROXIMITY_TEMPERATURE, i]
                         ofType:([HWMonitorSensor getTypeOfKey:
                                  [NSString stringWithFormat:@KEY_FORMAT_GPU_PROXIMITY_TEMPERATURE, i]]) ? : @TYPE_SP78
                       forGroup:TemperatureSensorGroup
                     andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %X Proximity",nil) ,i]
                       intoList:arr];
  }
  return arr;
}

- (NSArray *)getCPUTemperatures {
  NSMutableArray *arr = [NSMutableArray array];
  for (int i=0; i < countPhisycalCores(); i++) {
    [self validateSensorWithKey:[NSString stringWithFormat:@KEY_FORMAT_CPU_DIE_CORE_TEMPERATURE, i]
                         ofType:([HWMonitorSensor getTypeOfKey:
                                  [NSString stringWithFormat:@KEY_FORMAT_CPU_DIE_CORE_TEMPERATURE, i]]) ? : @TYPE_SP78
                       forGroup:TemperatureSensorGroup
                     andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"CPU %d Core", nil), i]
                       intoList:arr];
    
    [self validateSensorWithKey:[NSString stringWithFormat:@KEY_FORMAT_CPU_DIODE_TEMPERATURE, i]
                         ofType:([HWMonitorSensor getTypeOfKey:
                                  [NSString stringWithFormat:@KEY_FORMAT_CPU_DIODE_TEMPERATURE, i]]) ? : @TYPE_SP78
                       forGroup:TemperatureSensorGroup
                     andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"CPU %d Diode", nil), i]
                       intoList:arr];
  }
  return arr;
}

- (NSArray *)getCPUFrequencies {
  NSMutableArray *arr = [NSMutableArray array];
  for (int i=0; i < countPhisycalCores(); i++) {
    [self validateSensorWithKey:[NSString stringWithFormat:@KEY_FORMAT_NON_APPLE_CPU_FREQUENCY,i]
                         ofType:@TYPE_FREQ
                       forGroup:FrequencySensorGroup
                     andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"CPU %d",nil),i]
                       intoList:arr];
  }
  return arr;
}

- (NSArray *)getOtherFrequencies {
  NSMutableArray *arr = [NSMutableArray array];
  for (int i=0; i < countPhisycalCores(); i++) {
    [self validateSensorWithKey:[NSString stringWithFormat:@KEY_FAKESMC_FORMAT_GPU_FREQUENCY,i]
                         ofType:@TYPE_FREQ
                       forGroup:FrequencySensorGroup
                     andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %d Core",nil)]
                       intoList:arr];
    
    [self validateSensorWithKey:[NSString stringWithFormat:@KEY_FAKESMC_FORMAT_GPU_SHADER_FREQUENCY,i]
                         ofType:@TYPE_FREQ
                       forGroup:FrequencySensorGroup
                     andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %d Shaders",nil), i]
                       intoList:arr];
    
    [self validateSensorWithKey:[NSString stringWithFormat:@KEY_FAKESMC_FORMAT_GPU_MEMORY_FREQUENCY,i]
                         ofType:@TYPE_FREQ
                       forGroup:FrequencySensorGroup
                     andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %d Memory",nil), i]
                       intoList:arr];
  }
  return arr;
}

- (NSArray *)getMultiplers {
  NSMutableArray *arr = [NSMutableArray array];
  for (int i=0; i<0x2C; i++) {
    [self validateSensorWithKey:[NSString stringWithFormat:@KEY_FORMAT_NON_APPLE_CPU_MULTIPLIER,i]
                         ofType:@TYPE_FP4C
                       forGroup:MultiplierSensorGroup
                     andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"CPU %d Multiplier", nil),i]
                       intoList:arr];
  }
  
  [self validateSensorWithKey:@KEY_NON_APPLE_PACKAGE_MULTIPLIER
                       ofType:@TYPE_FP4C
                     forGroup:MultiplierSensorGroup
                   andCaption:NSLocalizedString(@"CPU Package Multiplier",nil)
                     intoList:arr];
  return arr;
}

- (NSArray *)getVoltages {
  NSMutableArray *arr = [NSMutableArray array];
  
  [self validateSensorWithKey:@KEY_CPU_VOLTAGE
                       ofType:([HWMonitorSensor getTypeOfKey:@KEY_CPU_VOLTAGE]) ? : @TYPE_FP2E
                     forGroup:VoltageSensorGroup
                   andCaption:NSLocalizedString(@"CPU Voltage",nil)
                     intoList:arr];
  
  [self validateSensorWithKey:@KEY_CPU_VRM_SUPPLY0
                       ofType:([HWMonitorSensor getTypeOfKey:@KEY_CPU_VRM_SUPPLY0]) ? : @TYPE_FP2E
                     forGroup:VoltageSensorGroup
                   andCaption:NSLocalizedString(@"CPU VRM Voltage",nil)
                     intoList:arr];
  
  [self validateSensorWithKey:@KEY_MEMORY_VOLTAGE
                       ofType:([HWMonitorSensor getTypeOfKey:@KEY_MEMORY_VOLTAGE]) ? : @TYPE_FP2E
                     forGroup:VoltageSensorGroup
                   andCaption:NSLocalizedString(@"DIMM Voltage",nil)
                     intoList:arr];
  
  [self validateSensorWithKey:@KEY_12V_VOLTAGE
                       ofType:([HWMonitorSensor getTypeOfKey:@KEY_12V_VOLTAGE]) ? : @TYPE_SP4B
                     forGroup:VoltageSensorGroup
                   andCaption:NSLocalizedString(@"+12V Bus Voltage",nil)
                     intoList:arr];
  
  [self validateSensorWithKey:@KEY_5VC_VOLTAGE
                       ofType:([HWMonitorSensor getTypeOfKey:@KEY_5VC_VOLTAGE]) ? : @TYPE_SP4B
                     forGroup:VoltageSensorGroup
                   andCaption:NSLocalizedString(@"+5V Bus Voltage",nil)
                     intoList:arr];
  
  [self validateSensorWithKey:@KEY_N12VC_VOLTAGE
                       ofType:([HWMonitorSensor getTypeOfKey:@KEY_N12VC_VOLTAGE]) ? : @TYPE_SP4B
                     forGroup:VoltageSensorGroup
                   andCaption:NSLocalizedString(@"-12V Bus Voltage",nil)
                     intoList:arr];
  
  [self validateSensorWithKey:@KEY_5VSB_VOLTAGE
                       ofType:([HWMonitorSensor getTypeOfKey:@KEY_5VSB_VOLTAGE]) ? : @TYPE_SP4B
                     forGroup:VoltageSensorGroup
                   andCaption:NSLocalizedString(@"-5V Bus Voltage",nil)
                     intoList:arr];
  
  
  [self validateSensorWithKey:@KEY_3VCC_VOLTAGE
                       ofType:([HWMonitorSensor getTypeOfKey:@KEY_3VCC_VOLTAGE]) ? : @TYPE_FP2E
                     forGroup:VoltageSensorGroup
                   andCaption:NSLocalizedString(@"3.3 VCC Voltage",nil)
                     intoList:arr];
  
  [self validateSensorWithKey:@KEY_3VSB_VOLTAGE
                       ofType:([HWMonitorSensor getTypeOfKey:@KEY_3VSB_VOLTAGE]) ? : @TYPE_FP2E
                     forGroup:VoltageSensorGroup
                   andCaption:NSLocalizedString(@"3.3 VSB Voltage",nil)
                     intoList:arr];
  
  [self validateSensorWithKey:@KEY_AVCC_VOLTAGE
                       ofType:([HWMonitorSensor getTypeOfKey:@KEY_AVCC_VOLTAGE]) ? : @TYPE_FP2E
                     forGroup:VoltageSensorGroup
                   andCaption:NSLocalizedString(@"3.3 AVCC Voltage",nil)
                     intoList:arr];
  
  for (int i=0; i<0xA; i++) {
    [self validateSensorWithKey:[NSString stringWithFormat:@KEY_FORMAT_GPU_VOLTAGE,i]
                         ofType:([HWMonitorSensor getTypeOfKey:[NSString stringWithFormat:@KEY_FORMAT_GPU_VOLTAGE,i]]) ? : @TYPE_FP2E
                       forGroup:VoltageSensorGroup
                     andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %d Voltage",nil),i]
                       intoList:arr];
  }
  return arr;
}

- (NSArray *)getFans {
  NSMutableArray *arr = [NSMutableArray array];
  for (int i=0; i<10; i++) {
    FanTypeDescStruct * fds;
    NSData * keydata = [HWMonitorSensor readValueForKey:[[NSString alloc] initWithFormat:@KEY_FORMAT_FAN_ID,i]];
    NSString * caption;
    if(keydata) {
      fds = (FanTypeDescStruct*)[keydata bytes];
      caption = [[[NSString alloc] initWithBytes:  fds->strFunction length: DIAG_FUNCTION_STR_LEN encoding: NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[[NSCharacterSet letterCharacterSet] invertedSet]];
    } else {
      caption = @"";
    }
    if([caption length] <= 0) {
      caption = [[NSString alloc] initWithFormat:NSLocalizedString(@"Fan %d", nil),i];
    }
    [self validateSensorWithKey:[NSString stringWithFormat:@KEY_FORMAT_FAN_SPEED,i]
                         ofType:([HWMonitorSensor getTypeOfKey:[NSString stringWithFormat:@KEY_FORMAT_FAN_SPEED,i]]) ? : @TYPE_FPE2
                       forGroup:TachometerSensorGroup
                     andCaption:caption
                       intoList:arr];
  }
  return arr;
}

- (NSArray *)getDisks {
  NSMutableArray *arr = [NSMutableArray array];
  if (self.smartSupported) {
      if (fabs([lastcall timeIntervalSinceNow]) > SMART_UPDATE_INTERVAL) {
        lastcall = [NSDate date];
        [smartController update];
        DisksList = [smartController getDataSet /*:1*/];
        SSDList = [smartController getSSDLife];
      }
    
    if (DisksList != nil && DisksList.allKeys.count > 0) {
      NSEnumerator * DisksEnumerator = [DisksList keyEnumerator];
      id nextDisk;
      while (nextDisk = [DisksEnumerator nextObject]) {
        HWMonitorSensor *sensor = [[HWMonitorSensor alloc] initWithKey:nextDisk
                                                               andType:@TYPE_FPE2
                                                              andGroup:HDSmartTempSensorGroup
                                                           withCaption:nextDisk];
        
        sensor.stringValue = [NSString stringWithFormat:@"%@", [sensor formatedValue: [DisksList objectForKey:nextDisk]]];
        [arr addObject:sensor];
        [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:sensor.key]];
        [[NSUserDefaults standardUserDefaults] synchronize];
      }
    }
    if (SSDList != nil && SSDList.allKeys.count > 0) {
      NSEnumerator * SSDEnumerator = [SSDList keyEnumerator];
      id nextSSD;
      while (nextSSD = [SSDEnumerator nextObject]) {
        HWMonitorSensor *sensor = [[HWMonitorSensor alloc] initWithKey:nextSSD
                                                               andType:@TYPE_FPE2
                                                              andGroup:HDSmartLifeSensorGroup
                                                           withCaption:nextSSD];

        sensor.stringValue = [NSString stringWithFormat:@"%@", [sensor formatedValue: [SSDList objectForKey:nextSSD]]];
        [arr addObject:sensor];
        [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:sensor.key]];
        [[NSUserDefaults standardUserDefaults] synchronize];
      }
    }
  }
  
  return arr;
}

- (NSArray *)getBattery {
  NSMutableArray *arr = [NSMutableArray array];
  
  NSDictionary *pb = [IOBatteryStatus getIOPMPowerSource];
  
  if (pb) {
    int voltage  = [IOBatteryStatus getBatteryVoltageFrom:pb];
    int amperage = [IOBatteryStatus getBatteryAmperageFrom:pb];
    if (voltage > BAT0_NOT_FOUND) {
      HWMonitorSensor *sensor = [[HWMonitorSensor alloc] initWithKey:@KEY_BAT0_VOLTAGE
                                                             andType:([HWMonitorSensor getTypeOfKey:@KEY_BAT0_VOLTAGE]) ? : @TYPE_UI16
                                                            andGroup:BatterySensorsGroup
                                                         withCaption:NSLocalizedString(@"Battery Voltage, mV",nil)];
      
      sensor.stringValue = [NSString stringWithFormat:@"%d", voltage];
      [arr addObject:sensor];
      [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:sensor.key]];
    }
    if (amperage > BAT0_NOT_FOUND) {
      HWMonitorSensor *sensor = [[HWMonitorSensor alloc] initWithKey:@KEY_BAT0_AMPERAGE
                                                             andType:([HWMonitorSensor getTypeOfKey:@KEY_BAT0_AMPERAGE]) ? : @TYPE_UI16
                                                            andGroup:BatterySensorsGroup
                                                         withCaption:NSLocalizedString(@"Battery Amperage, mA",nil)];
      sensor.stringValue = [NSString stringWithFormat:@"%d", amperage];
      [arr addObject:sensor];
      [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:sensor.key]];
    }
  }
  return arr;
}

- (NSArray *)getGenericBatteries {
  NSMutableArray *arr = [NSMutableArray array];
  BatteriesList = [IOBatteryStatus getAllBatteriesLevel];
  NSEnumerator * BatteryEnumerator = [BatteriesList keyEnumerator];
  id nextBattery;
  while (nextBattery = [BatteryEnumerator nextObject]) {
    [self validateSensorWithKey:nextBattery
                         ofType:@TYPE_FPE2
                       forGroup:GenericBatterySensorsGroup
                     andCaption:nextBattery
                       intoList:arr];
  }
  [[NSUserDefaults standardUserDefaults] synchronize];
  return arr;
}

- (void)validateSensorWithKey:(NSString *)key
                       ofType:(NSString *)type
                     forGroup:(SensorGroup)group
                   andCaption:(NSString *)caption
                     intoList:(NSMutableArray *)list {
  
  HWMonitorSensor *sensor = [[HWMonitorSensor alloc] initWithKey:key
                                                         andType:type
                                                        andGroup:VoltageSensorGroup
                                                     withCaption:caption];
  
  NSString *value = [sensor formatedValue:[HWMonitorSensor readValueForKey:sensor.key]];
  if ((group == HDSmartLifeSensorGroup || group == HDSmartTempSensorGroup) ||
      ((value != nil) && ![value isEqualToString:@""] && ![value isEqualToString:@"-"])) {
    sensor.group = group;
    [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:key]];
    [list addObject:sensor];
  }
}
@end
