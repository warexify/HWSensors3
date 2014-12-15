/* Written by Artem Falcon <lomka@gero.in> */

/* Analog ADT7470(A) sensor driver */
// rewritten for AnalogDevices ADT747x chips by Slice 2014

#include "ADT7470.h"

OSDefineMetaClassAndStructors(Analog, IOService) // FakeSMCPlugin)

bool Analog::init (OSDictionary* dict)
{
  bool res = super::init(dict);
  DbgPrint("init\n");
  
	if (!(sensors = OSDictionary::withCapacity(0)))
		return false;
  
  ADT7470_addr = 0; config.num_fan = config.start_fan = 0;
  config.fan_offset = -1;
  
  return res;
}


void Analog::free(void)
{
  DbgPrint("free\n");
  
  i2cNub->close(this);
  i2cNub->release();
  
  sensors->release();
  
  super::free();
}

IOService *Analog::probe (IOService* provider, SInt32* score)
{
  IOService *res = super::probe(provider, score);
  DbgPrint("probe\n");
  return res;
}

bool Analog::start(IOService *provider)
{
  int i;
  bool res;
  UInt8 cmd, data, addrs[] = ADT7470_ADDRS;
  /* Mapping common for Intel boards */
  struct MList list[] = {
    { ADT7470_TEMP1H, ADT7470_TEMP1L, {KEY_CPU_PROXIMITY_TEMPERATURE,TYPE_SP78,2,-1}, -1, 0, true },
    { ADT7470_TEMP2H, ADT7470_TEMP2L, {KEY_AMBIENT_TEMPERATURE,TYPE_SP78,2,-1}, -1, 0, true },
    { ADT7470_TEMP3H, ADT7470_TEMP3L, {KEY_DIMM_TEMPERATURE,TYPE_SP78,2,-1}, -1, 0, true },
    { ADT7470_TEMP4H, ADT7470_TEMP4L, {KEY_CPU_HEATSINK_TEMPERATURE,TYPE_SP78,2,-1}, -1, 0, true },
    
    { ADT7470_TACH1L, ADT7470_TACH1H, {"Fan 1",TYPE_FPE2,2,0}, true, 0, true },
    { ADT7470_TACH2L, ADT7470_TACH2H, {"Fan 2",TYPE_FPE2,2,1}, true, 0, true },
    { ADT7470_TACH3L, ADT7470_TACH3H, {"Fan 3",TYPE_FPE2,2,2}, true, 0, true },
    { ADT7470_TACH4L, ADT7470_TACH4H, {"Fan 4",TYPE_FPE2,2,2}, true, 0, true }
  };
  struct PList pwm[] = {
    { ADT7470_PWM1R, 0, -2 },
    { ADT7470_PWM2R, 0, -2 },
    { ADT7470_PWM3R, 0, -2 },
  };
  
  OSDictionary *conf = NULL, *sconf = OSDynamicCast(OSDictionary, getProperty("Sensors Configuration")), *dict;
  IOService *fRoot = getServiceRoot();
  OSString *str, *vendor = NULL;
  char *key;
  char tempkey[] = "_temp ", /* Ugly hack to keep keys in order for auto-generated plist */
  fankey[] = "tach ";
  
  
  res = super::start(provider);
  DbgPrint("start\n");
  
  if (!(i2cNub = OSDynamicCast(I2CDevice, provider))) {
    IOPrint("Failed to cast provider\n");
    return false;
  }
  
  if (!(fakeSMC = waitForService(serviceMatching(kFakeSMCDeviceService)))) {
    //		WarningLog("Can't locate fake SMC device, kext will not load");
		return false;
  }
  
  i2cNub->retain();
  i2cNub->open(this);
  
  for (i = 0; i < sizeof(addrs) / sizeof(addrs[0]); i++) {
    if (!i2cNub->ReadI2CBus(addrs[i], &(cmd = ADT7470_VID_REG), sizeof(cmd), &data, sizeof(data))) {
      if (data == ADT7470_VID) {
        if(!i2cNub->ReadI2CBus(addrs[i], &(cmd = ADT7470_DID_REG), sizeof(cmd), &data, sizeof(data)) &&
           ((data & 0xF0) == ADT7470_PID)) {
          ADT7470_addr = addrs[i];
          IOPrint("ADT DID=0x%x attached at 0x%x.\n", data, ADT7470_addr);
          break;
        } else {
          IOPrint("found chip DID %x\n", data);
        }
      } else {
        IOPrint("found chip VID %x\n", data);
      }
    }
  }
  if (!ADT7470_addr) {
    IOPrint("Device matching failed.\n");
    return false;
  }
  
  memcpy(&Measures, &list, sizeof(Measures));
  memcpy(&Pwm, &pwm, sizeof(Pwm));
  
  if (fRoot) {
    vendor = OSDynamicCast(OSString, fRoot->getProperty("OEMVendor"));
    str = OSDynamicCast(OSString, fRoot->getProperty("OEMBoard"));
    if (!str) {
      str = OSDynamicCast(OSString, fRoot->getProperty("OEMProduct"));
    }
  }
  if (vendor)
    if (OSDictionary *link = OSDynamicCast(OSDictionary, sconf->getObject(vendor)))
      if(str)
        conf = OSDynamicCast(OSDictionary, link->getObject(str));
  if (sconf && !conf)
    conf = OSDynamicCast(OSDictionary, sconf->getObject("Active"));
  
  i = 0;
  for (int s = 0, j = 0, k = 0; i < NUM_SENSORS; i++) {
    if (conf) {
      if (Measures[i].fan < 0) {
        snprintf(&tempkey[5], 2, "%d", j++);
        key = tempkey;
      } else {
        snprintf(&fankey[4], 2, "%d", k++);
        key = fankey;
      }
      if ((dict = OSDynamicCast(OSDictionary, conf->getObject(key)))) {
        str = OSDynamicCast(OSString, dict->getObject("id"));
        memcpy(Measures[i].hwsensor.key, str->getCStringNoCopy(), str->getLength()+1);
        if (Measures[i].fan > -1)
          Measures[i].hwsensor.pwm = ((OSNumber *)OSDynamicCast(OSNumber, dict->getObject("pwm")))->
          unsigned8BitValue();
        Measures[i].hwsensor.size = ((OSNumber *)OSDynamicCast(OSNumber, dict->getObject("size")))->
        unsigned8BitValue();
        str = OSDynamicCast(OSString, dict->getObject("type"));
        memcpy(Measures[i].hwsensor.type, str->getCStringNoCopy(), str->getLength()+1);
      }
    }
    
    if (Measures[i].hwsensor.key[0]) {
      if (Measures[i].fan < 0) {
        addSensor(Measures[i].hwsensor.key, Measures[i].hwsensor.type,
                  Measures[i].hwsensor.size, s);
        s++;
      } else {
        if (!config.start_fan)
          config.start_fan = i;
        addTachometer(&Measures[i], Measures[i].fan = config.num_fan);
        config.num_fan++;
      }
    }
  }
  config.num_fan++;
  addKey(KEY_FAN_FORCE, TYPE_UI16, 2, 0);
  
  GetConf();
  
  return res;
}

void Analog::stop(IOService *provider)
{
  DbgPrint("stop\n");
  
  sensors->flushCollection();
  if (kIOReturnSuccess != fakeSMC->callPlatformFunction(kFakeSMCRemoveKeyHandler, true, this, NULL, NULL, NULL)) {
    IOLog("Can't remove key handler");
    IOSleep(500);
  }
  
  super::stop(provider);
}

/* Temp: update 'em all et once */
void Analog::updateSensors()
{
	UInt8 hdata, ldata;
  UInt16 data;
  
  i2cNub->LockI2CBus();
  
  for (int i = 0; i < NUM_SENSORS; i++) {
    /* Skip sensors without keys */
    if (!Measures[i].hwsensor.key[0])
      continue;
    
    Measures[i].obsoleted = false;
    if (i2cNub->ReadI2CBus(ADT7470_addr, &Measures[i].hreg, sizeof Measures[i].hreg, &hdata, sizeof hdata) ||
        i2cNub->ReadI2CBus(ADT7470_addr, &Measures[i].lreg, sizeof Measures[i].lreg, &ldata, sizeof ldata)) {
			Measures[i].value = 0;
			continue;
		}
    
    if (Measures[i].fan < 0) {
      if (hdata == ADT7470_TEMP_NA)
        Measures[i].value = 0;
      else {
        Measures[i].value = ((hdata << 8 | ldata)) >> 6;
        Measures[i].value = (float) Measures[i].value * 0.25f;
      }
    } else {
      data = hdata + (ldata << 8);
      if (!data ||
          data == 0xffff /* alarm-less value */
          )
        Measures[i].value = 0;
      else
        Measures[i].value = 5400000 / data;
    }
  }
  
  i2cNub->UnlockI2CBus();
}

void Analog::GetConf()
{
	UInt8 conf, val;
  
  config.pwm_mode = 0;
  
  /* Ask for PWM mode statuses */
  for (int i = 0; i < NUM_PWM; i++) {
    i2cNub->ReadI2CBus(ADT7470_addr, &Pwm[i].reg[0], sizeof Pwm[i].reg[0], &conf, sizeof conf);
    val = ADT7470_FANCM(conf);
    
    if (!ADT7470_ALTBG(val) &&
        (val == 7 ||
         (val == 3 &&      /* PWM: 255 -> 0 */
          (conf |= 1 << ADT7470_PWM3B) &&
          ((conf &= ~(1 << ADT7470_PWM2B) & ~(1 << ADT7470_PWM1B)) != 0xFF) &&
          (i2cNub->WriteI2CBus(ADT7470_addr, &Pwm[i].reg[0], sizeof Pwm[i].reg[0], &conf, sizeof conf) != -1) )))
      for (int j = config.start_fan; j < NUM_SENSORS; j++)
        if (Measures[j].hwsensor.pwm == i && Measures[j].hwsensor.key[0])
          config.pwm_mode |= 1 << Measures[j].fan;
    
    Pwm[i].value = conf; /* store original conf */
  }
}

void Analog::SetPwmMode(UInt16 val)
{
  bool is_auto;
  bool init_pwm[NUM_PWM] = { false };
  char idx;
  UInt8 conf, zon;
  
	i2cNub->LockI2CBus();
  
  for (int i = 0, j = config.start_fan; i < config.num_fan; i++, j++)
    if ((is_auto = !(val & (1 << i))) != !(config.pwm_mode & (1 << i))) {
      while (j < NUM_SENSORS && !Measures[j].hwsensor.key[0]) j++;
      /* Can't control fan not assigned with PWM */
      if (Measures[j].hwsensor.pwm < 0)
        continue;
      
      config.pwm_mode = is_auto ? config.pwm_mode & ~(1 << i) : config.pwm_mode | 1 << i;
      idx = Measures[j].hwsensor.pwm;
      
      if (!init_pwm[idx]) {
        conf = Pwm[idx].value;
        if (is_auto) {
          zon = ADT7470_FANCM(conf);
          /* No auto mode info was obtained */
          if (!ADT7470_ALTBG(zon) && (zon == 4 || zon == 7)) {
            /* Thermal cruise mode */
            ADT7470_ALTBS(conf);
            conf &= ~(1 << ADT7470_PWM3B) & ~(1 << ADT7470_PWM2B);
            conf |= (1 << ADT7470_PWM1B);
          }
        } else {
          ADT7470_ALTBC(conf);
          conf |= 1 << ADT7470_PWM3B | 1 << ADT7470_PWM2B | 1 << ADT7470_PWM1B;
        }
        i2cNub->WriteI2CBus(ADT7470_addr, &Pwm[idx].reg[0], sizeof Pwm[idx].reg[0], &conf, sizeof conf);
        init_pwm[idx] = true;
      }
    }
  
  i2cNub->UnlockI2CBus();
}

void Analog::SetPwmDuty(char idx, UInt16 val)
{
	UInt8 data;
  
  if (val < 25)
    data = 0;
  else if (val < 50)
    data = 0x40;
  else if (val < 75)
    data = 0x80;
  else if (val < 100)
    data = 0xc0;
  else
    data = 0xff;
  
  if ((Pwm[idx].duty & 0xff) == data)
    return;
  
  i2cNub->LockI2CBus();
  i2cNub->WriteI2CBus(ADT7470_addr, &Pwm[idx].reg[1], sizeof Pwm[idx].reg[1], &data, sizeof data);
  i2cNub->UnlockI2CBus();
  
  Pwm[idx].duty = data;
}

void Analog::readSensor(int idx)
{
  if (Measures[idx].obsoleted)
    updateSensors();
  
  Measures[idx].obsoleted = true;
}

/* FakeSMC dependend methods */
bool Analog::addKey(const char* key, const char* type, unsigned char size, int index)
{
	if (kIOReturnSuccess == fakeSMC->callPlatformFunction(kFakeSMCAddKeyHandler, true, (void *)key,
                                                        (void *)type, (void *)size, (void *)this)) {
		if (sensors->setObject(key, OSNumber::withNumber(index, 32))) {
      return true;
    } else {
      IOPrint("%s key not set\n", key);
      return 0;
    }
  }
  
	IOPrint("%s key not added\n", key);
  
	return 0;
}

void Analog::addTachometer(struct MList *sensor, int index)
{
  UInt8 length = 0;
  void * data = 0;
  
  if (kIOReturnSuccess == fakeSMC->callPlatformFunction(kFakeSMCGetKeyValue, false, (void *)KEY_FAN_NUMBER,
                                                        (void *)&length, (void *)&data, 0))
  {
    length = 0;
    
    bcopy(data, &length, 1);
    
    char name[5];
    
    snprintf(name, 5, KEY_FORMAT_FAN_SPEED, length);
    
    if (addSensor(name, sensor->hwsensor.type, sensor->hwsensor.size, index)) {
      /*     snprintf(name, 5, KEY_FORMAT_FAN_ID, length);
       
       if (kIOReturnSuccess != fakeSMC->callPlatformFunction(kFakeSMCAddKeyValue, false, (void *)
       name, (void *)TYPE_CH8, (void *)
       ((UInt64)strlen(sensor->hwsensor.key)),
       (void *)sensor->hwsensor.key))
       IOPrint("ERROR adding tachometer id value!\n");
       */
      if (sensor->hwsensor.key) {
        FanTypeDescStruct fds;
        snprintf(name, 5, KEY_FORMAT_FAN_ID, length);
        fds.type = FAN_PWM_TACH;
        fds.ui8Zone = 1;
        fds.location = LEFT_LOWER_FRONT;
        strncpy(fds.strFunction, sensor->hwsensor.key, DIAG_FUNCTION_STR_LEN);
        
        if (kIOReturnSuccess != fakeSMC->callPlatformFunction(kFakeSMCAddKeyValue, false, (void *)name, (void *)TYPE_FDESC, (void *)((UInt64)sizeof(fds)), (void *)&fds)) {
          
          IOPrint("error adding tachometer id value");
        }
      }
      
      
      
      if (config.fan_offset < 0)
        config.fan_offset = length;
      
      length++;
      if (kIOReturnSuccess != fakeSMC->callPlatformFunction(kFakeSMCSetKeyValue, false, (void *)KEY_FAN_NUMBER,
                                                            (void *)1, (void *)&length, 0))
        IOPrint("ERROR updating FNum value!\n");
      length--;
    }
    
    snprintf(name, 5, KEY_FORMAT_FAN_MIN_SPEED, length);
    addKey(name, TYPE_FPE2, 2, length);
    snprintf(name, 5, KEY_FORMAT_FAN_MAX_SPEED, length);
    addKey(name, TYPE_FPE2, 2, length);
  }
  else IOPrint("ERROR reading FNum value!\n");
}
/* */

/* Exports for HWSensors4 */
IOReturn Analog::callPlatformFunction(const OSSymbol *functionName, bool waitForFunction,
                                      void *param1, void *param2, void *param3, void *param4 )
{
  int i, idx = -1;
  char fan = -1;
  
  if (functionName->isEqualTo(kFakeSMCGetValueCallback)) {
    const char* key = (const char*)param1;
		char * data = (char*)param2;
    
    if (key && data) {
      if (key[0] == 'T' || (key[0] == KEY_FORMAT_FAN_SPEED[0] &&
                            key[2] == KEY_FORMAT_FAN_SPEED[3] &&
                            (fan = strtol(&key[1], NULL, 10) - config.fan_offset) != -1)) {
        for (i = 0; i < NUM_SENSORS; i++)
          if (Measures[i].fan == fan && Measures[i].hwsensor.key[0])
            if (fan >= 0 || (Measures[i].hwsensor.key[1] == key[1] &&
                             Measures[i].hwsensor.key[2] == key[2] &&
                             Measures[i].hwsensor.key[3] == key[3])) {
              idx = i; break;
            }
        
        if (idx > -1) {
          readSensor(idx);
          if (fan >= 0 && (*((uint32_t*)&Measures[idx].hwsensor.type) == *((uint32_t*)TYPE_FPE2)))
            //      Measures[idx].value = Measures[idx].hwsensor->encodeValue(Measures[idx].value);
            Measures[idx].value = encode_fpe2(Measures[idx].value);
          memcpy(data, &Measures[idx].value, Measures[idx].hwsensor.size);
          return kIOReturnSuccess;
        }
      }
      else if (key[0] == 'F') {
        if (key[1] == KEY_FAN_FORCE[1]) {
          /* Return real states */
          memcpy(data, &(idx = swap_value(config.pwm_mode << config.fan_offset)), 2);
          return kIOReturnSuccess;
        } else if (key[2] == 'M' &&
                   (key[3] == KEY_FORMAT_FAN_MIN_SPEED[4] || key[3] == KEY_FORMAT_FAN_MAX_SPEED[4])) {
          fan = strtol(&key[1], NULL, 10) - config.fan_offset;
          for (i = config.start_fan; i < NUM_SENSORS; i++) {
            if (Measures[i].fan == fan && Measures[i].hwsensor.key[0]) {
              idx = i; break;
            }
          }
          if (idx > -1) {
            if (key[3] == KEY_FORMAT_FAN_MAX_SPEED[4]) {
              if (Measures[idx].hwsensor.pwm > -1)
                memcpy(data, &(idx = 0x9001), 2); /* PWM % */
            }
            else if (Measures[idx].hwsensor.pwm < 0) /* MIN_SPEED */
              memset(data, 0, 2);
          }
          return kIOReturnSuccess;
        }
      }
    }
    return kIOReturnBadArgument;
  }
  if (functionName->isEqualTo(kFakeSMCSetValueCallback)) {
    const char* key = (const char*)param1;
		char * data = (char*)param2;
    
    if (key[0] == 'F' && data) {
      if (key[2] == KEY_FORMAT_FAN_MIN_SPEED[3] && key[3] == KEY_FORMAT_FAN_MIN_SPEED[4]) {
        if (config.pwm_mode & (1 << (fan = strtol(&key[1], NULL, 10) - config.fan_offset))) {
          for (i = config.start_fan; i < NUM_SENSORS; i++) {
            if (Measures[i].fan == fan && Measures[i].hwsensor.key[0]) {
              idx = i; break;
            }
          };
          if (idx > -1 && Measures[idx].hwsensor.pwm > -1)
            SetPwmDuty(Measures[idx].hwsensor.pwm, decode_fpe2(*((UInt16 *) data)));
        }
        return kIOReturnSuccess;
      }
      else if(key[1] == KEY_FAN_FORCE[1]) {
        SetPwmMode(swap_value(*((UInt16 *) data)) >> config.fan_offset);
        return kIOReturnSuccess;
      }
    }
    return kIOReturnBadArgument;
  }
  return super::callPlatformFunction(functionName, waitForFunction, param1, param2, param3, param4);
}
/* */
