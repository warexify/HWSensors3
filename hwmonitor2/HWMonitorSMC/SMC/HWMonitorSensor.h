//
//  NSSensor.h
//  HWSensors
//
//  Created by mozo,Navi on 22.10.11.
//  Copyright (c) 2011 mozo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISPSmartController.h"
#import "HWImageView.h"
#import "HWTextField.h"
enum {
  TemperatureSensorGroup      =   1,
  VoltageSensorGroup          =   2,
  TachometerSensorGroup       =   3,
  FrequencySensorGroup        =   4,
  MultiplierSensorGroup       =   5,
  HDSmartTempSensorGroup      =   6,
  BatterySensorsGroup         =   7,
  GenericBatterySensorsGroup  =   8,
  HDSmartLifeSensorGroup      =   9,
  
};
typedef NSUInteger SensorGroup;

@interface HWMonitorSensor : NSObject {
  NSString *    key;
  NSString *    type;
  SensorGroup   group;
  NSString *    caption;
  id            object;
  BOOL          favorite;
  
  // instance vars for the below @property
  NSString *    _key;
  NSString *    _type;
  SensorGroup   _group;
  NSString *    _caption;
  id            _object;
  BOOL          _favorite;
}

@property (readwrite, retain) NSString *    key;
@property (readwrite, retain) NSString *    type;
@property (readwrite, assign) SensorGroup   group;
@property (readwrite, retain) NSString *    caption;
@property (readwrite, retain) id            object;
@property (readwrite, retain) NSString *    stringValue;
@property (readwrite, assign) BOOL          favorite;

@property (nonatomic, assign) HWImageView *    stateView;
@property (nonatomic, assign) HWTextField *    keyField;
@property (nonatomic, assign) HWTextField *    valueField;

+ (unsigned int) swapBytes:(unsigned int) value;

+ (NSData *)readValueForKey:(NSString *)key;
+ (NSString* )getTypeOfKey:(NSString*)key;

- (HWMonitorSensor *)initWithKey:(NSString *)aKey
                         andType: aType
                        andGroup:(NSUInteger)aGroup
                     withCaption:(NSString *)aCaption;

- (NSString *)formatedValue:(NSData *)value;

@end

