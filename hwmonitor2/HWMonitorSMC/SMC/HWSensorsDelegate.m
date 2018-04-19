//
//  HWSensorsDelegate.m
//  HWMonitorSMC
//
//  Created by vector sigma on 24/02/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

#import "HWSensorsDelegate.h"
#include <sys/sysctl.h>
#import "NSString+TruncateToWidth.h"
#import "IOBatteryStatus.h"
#import "SSMemoryInfo.h"
#include "../../../utils/definitions.h"

#import <mach/host_info.h>
#import <mach/mach_host.h>
#import <mach/task_info.h>
#import <mach/task.h>

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
}
  
- (NSArray *)getMemory {
  NSMutableArray *arr = [NSMutableArray array];
  HWMonitorSensor *sensor;
  BOOL showPercentage = [[NSUserDefaults standardUserDefaults] boolForKey:@"useMemoryPercentage"];
  NSString *format;
  if (showPercentage) {
    format = @"%3.1f%%";
  } else {
    format = @"%3.1f%MB";
  }

  sensor = [[HWMonitorSensor alloc] initWithKey:@"RAM TOTAL"
                                        andType:@"RAM"
                                       andGroup:MemorySensorGroup
                                    withCaption:NSLocalizedString(@"Total", nil)];
  
  sensor.stringValue = [NSString stringWithFormat:@"%3.0fMB", [SSMemoryInfo totalMemory]];
  [arr addObject:sensor];
  [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:sensor.key]];
  
  sensor = [[HWMonitorSensor alloc] initWithKey:@"RAM ACTIVE"
                                        andType:@"RAM"
                                       andGroup:MemorySensorGroup
                                    withCaption:NSLocalizedString(@"Active", nil)];
  
  sensor.stringValue = [NSString stringWithFormat:format, [SSMemoryInfo activeMemory:showPercentage]];
  [arr addObject:sensor];
  [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:sensor.key]];
  
  sensor = [[HWMonitorSensor alloc] initWithKey:@"RAM INACTIVE"
                                        andType:@"RAM"
                                       andGroup:MemorySensorGroup
                                    withCaption:NSLocalizedString(@"Inactive", nil)];
  
  sensor.stringValue = [NSString stringWithFormat:format, [SSMemoryInfo inactiveMemory:showPercentage]];
  [arr addObject:sensor];
  [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:sensor.key]];
  
  sensor = [[HWMonitorSensor alloc] initWithKey:@"RAM FREE"
                                        andType:@"RAM"
                                       andGroup:MemorySensorGroup
                                    withCaption:NSLocalizedString(@"Free", nil)];
  
  sensor.stringValue = [NSString stringWithFormat:format, [SSMemoryInfo freeMemory:showPercentage]];
  [arr addObject:sensor];
  [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:sensor.key]];
  
  sensor = [[HWMonitorSensor alloc] initWithKey:@"RAM USED"
                                        andType:@"RAM"
                                       andGroup:MemorySensorGroup
                                    withCaption:NSLocalizedString(@"Used", nil)];
  
  sensor.stringValue = [NSString stringWithFormat:format, [SSMemoryInfo usedMemory:showPercentage]];
  [arr addObject:sensor];
  [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:sensor.key]];
  
  sensor = [[HWMonitorSensor alloc] initWithKey:@"RAM PURGEABLE"
                                        andType:@"RAM"
                                       andGroup:MemorySensorGroup
                                    withCaption:NSLocalizedString(@"Purgeable", nil)];
  
  sensor.stringValue = [NSString stringWithFormat:format, [SSMemoryInfo purgableMemory:showPercentage]];
  [arr addObject:sensor];
  [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:sensor.key]];
  
  sensor = [[HWMonitorSensor alloc] initWithKey:@"RAM WIRED"
                                        andType:@"RAM"
                                       andGroup:MemorySensorGroup
                                    withCaption:NSLocalizedString(@"Wired", nil)];
  
  sensor.stringValue = [NSString stringWithFormat:format, [SSMemoryInfo wiredMemory:showPercentage]];
  [arr addObject:sensor];
  [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:sensor.key]];
  
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  return arr;
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
                     andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %d Core",nil) ,i]
                       intoList:arr];
    
    [self validateSensorWithKey:[NSString stringWithFormat:@KEY_FORMAT_GPU_BOARD_TEMPERATURE, i]
                         ofType:([HWMonitorSensor getTypeOfKey:
                                  [NSString stringWithFormat:@KEY_FORMAT_GPU_BOARD_TEMPERATURE, i]]) ? : @TYPE_SP78
                       forGroup:TemperatureSensorGroup
                     andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %d Board",nil) ,i]
                       intoList:arr];
    
    [self validateSensorWithKey:[NSString stringWithFormat:@KEY_FORMAT_GPU_PROXIMITY_TEMPERATURE, i]
                         ofType:([HWMonitorSensor getTypeOfKey:
                                  [NSString stringWithFormat:@KEY_FORMAT_GPU_PROXIMITY_TEMPERATURE, i]]) ? : @TYPE_SP78
                       forGroup:TemperatureSensorGroup
                     andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %d Proximity",nil) ,i]
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

- (NSArray *)getMultipliers {
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
                                                         withCaption:NSLocalizedString(@"Battery Voltage",nil)];
      
      sensor.stringValue = [NSString stringWithFormat:@"%d", voltage];
      [arr addObject:sensor];
      [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:sensor.key]];
    }
    if (amperage > BAT0_NOT_FOUND) {
      HWMonitorSensor *sensor = [[HWMonitorSensor alloc] initWithKey:@KEY_BAT0_AMPERAGE
                                                             andType:([HWMonitorSensor getTypeOfKey:@KEY_BAT0_AMPERAGE]) ? : @TYPE_UI16
                                                            andGroup:BatterySensorsGroup
                                                         withCaption:NSLocalizedString(@"Battery Amperage",nil)];
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
  /*if ((group == HDSmartLifeSensorGroup || group == HDSmartTempSensorGroup) ||
      ((value != nil) && ![value isEqualToString:@""] && ![value isEqualToString:@"-"])) {*/
  if ((value != nil) && ![value isEqualToString:@""] && ![value isEqualToString:@"-"]) {
    sensor.group = group;
    [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:key]];
    [list addObject:sensor];
  }
}
@end
