/*
 *  W836x.cpp
 *  HWSensors
 *
 *  Based on code from Open Hardware Monitor project by Michael Möller (C) 2011
 *
 *  Created by mozo on 14/10/10.
 *  Copyright 2010 mozodojo. All rights reserved.
 *
 */

/*
 
 Version: MPL 1.1/GPL 2.0/LGPL 2.1
 
 The contents of this file are subject to the Mozilla Public License Version
 1.1 (the "License"); you may not use this file except in compliance with
 the License. You may obtain a copy of the License at
 
 http://www.mozilla.org/MPL/
 
 Software distributed under the License is distributed on an "AS IS" basis,
 WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 for the specific language governing rights and limitations under the License.
 
 The Original Code is the Open Hardware Monitor code.
 
 The Initial Developer of the Original Code is
 Michael Möller <m.moeller@gmx.ch>.
 Portions created by the Initial Developer are Copyright (C) 2011
 the Initial Developer. All Rights Reserved.
 
 Contributor(s):
 
 Alternatively, the contents of this file may be used under the terms of
 either the GNU General Public License Version 2 or later (the "GPL"), or
 the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 in which case the provisions of the GPL or the LGPL are applicable instead
 of those above. If you wish to allow use of your version of this file only
 under the terms of either the GPL or the LGPL, and not to allow others to
 use your version of this file under the terms of the MPL, indicate your
 decision by deleting the provisions above and replace them with the notice
 and other provisions required by the GPL or the LGPL. If you do not delete
 the provisions above, a recipient may use your version of this file under
 the terms of any one of the MPL, the GPL or the LGPL.
 
 */

#include "WinbondW836x.h"
#include "Chips.h"
#include "NuvotonConf.h"
#include "WindbondConf.h"

#include <architecture/i386/pio.h>
//#include "cpuid.h"
#include "FakeSMC.h"
#include "../../../utils/utils.h"

//#define Debug false

#include <IOKit/pwr_mgt/IOPM.h>

#define LogPrefix "W836x: "
#define DebugLog(string, args...)	do { if (Debug) { IOLog (LogPrefix "[Debug] " string "\n", ## args); } } while(0)
#define WarningLog(string, args...) do { IOLog (LogPrefix "[Warning] " string "\n", ## args); } while(0)
#define InfoLog(string, args...)	do { IOLog (LogPrefix string "\n", ## args); } while(0)

#define kUnknownModel "unknown"

// Power states
#define kIOPMPowerOff 0
#define kStateOff     0
#define kStateOn      1

static IOPMPowerState powerStates[] =
{
  {1, kIOPMPowerOff, kIOPMPowerOff, kIOPMPowerOff, 0, 0, 0, 0, 0, 0, 0, 0},
  {1, kIOPMPowerOn,  kIOPMPowerOn,  kIOPMPowerOn,  0, 0, 0, 0, 0, 0, 0, 0}
};

#pragma mark W836xSensor implementation
#define super SuperIOMonitor
OSDefineMetaClassAndStructors(W836x, SuperIOMonitor)

OSDefineMetaClassAndStructors(W836xSensor, SuperIOSensor)

#pragma mark sensor handling
long W836xSensor::getValue()
{
  UInt16 value = 0;
  switch (group)
  {
    case kSuperIOTemperatureSensor:
      value = owner->readTemperature(index);
      break;
    case kSuperIOVoltageSensor:
      value = owner->readVoltage(index);
      break;
    case kSuperIOTachometerSensor:
      value = owner->readTachometer(index);
      break;
    case kSuperIOTachometerMinSensor:
      value = owner->readTachometerMin(index);
      break;
    case kSuperIOTachometerMaxSensor:
      value = owner->readTachometerMax(index);
      break;
    case kSuperIOTachometerTargetSensor:
      value = owner->readTachometerTarget(index);
      break;
    case kSuperIOTachometerControlSensor:
      value = owner->readTachometerControl(index);
      break;
    default:
      break;
  }
  
  if (Rf == 0)
  {
    Rf = 1;
    Ri = 0;
    Vf = 0;
    WarningLog("Rf == 0 when getValue index=%d value=%04x", (int)index, value);
  }
  //  DebugLog("value = %ld Ri=%ld Rf=%ld", (long)value, Ri, Rf);
  value =  value + ((value - Vf) * Ri)/Rf;
  
  if (*((uint32_t*)type) == *((uint32_t*)TYPE_FP2E))
  {
    value = encode_fp2e(value);
  }
  else if (*((uint32_t*)type) == *((uint32_t*)TYPE_SP4B))
  {
    value = encode_sp4b(value);
  }
  else if (*((uint32_t*)type) == *((uint32_t*)TYPE_FPE2))
  {
    value = encode_fpe2(value);
  }
  
  return value;
}

void W836xSensor::setValue(UInt16 value)
{
  switch (group) {
    default:
      break;
  }
}

SuperIOSensor * W836xSensor::withOwner(SuperIOMonitor *aOwner, const char* aKey, const char* aType, unsigned char aSize, SuperIOSensorGroup aGroup, unsigned long aIndex, long aRi, long aRf, long aVf)
{
	SuperIOSensor *me = new W836xSensor;
    //  DebugLog("with owner mults = %ld", aRi);
    if (me && !me->initWithOwner(aOwner, aKey, aType, aSize, aGroup, aIndex ,aRi,aRf,aVf)) {
        me->release();
        return 0;
    }
	
    return me;
}

SuperIOSensor * W836x::addSensor(const char* name, const char* type, unsigned int size, SuperIOSensorGroup group, unsigned long index, long aRi, long aRf, long aVf)
{
  if (NULL != getSensor(name))
    return 0;
  DebugLog("mults = %ld, %ld", aRi, aRf);
  SuperIOSensor *sensor = W836xSensor::withOwner(this, name, type, size, group, index, aRi, aRf, aVf);
  
  if (sensor && sensors->setObject(sensor))
    if(kIOReturnSuccess == fakeSMC->callPlatformFunction(kFakeSMCAddKeyHandler, false, (void *)name, (void *)type, (void *)(long long)size, (void *)this))
      return sensor;
  
  return 0;
}

IOReturn W836x::callPlatformFunction(const OSSymbol *functionName, bool waitForFunction, void *param1, void *param2, void *param3, void *param4 )
{
  if (functionName->isEqualTo(kFakeSMCGetValueCallback))
  {
    const char* name = (const char*)param1;
    void * data = param2;
    //UInt32 size = (UInt64)param3;
    
    if (name && data)
    {
      SuperIOSensor * sensor = getSensor(name);
      if (sensor)
      {
        UInt16 value = sensor->getValue();
        bcopy(&value, data, 2);
        return kIOReturnSuccess;
      }
    }
    return kIOReturnBadArgument;
  }/*
  else  if (functionName->isEqualTo(kFakeSMCSetValueCallback)) {
    const char* name = (const char*)param1;
    void * data = param2;
    //UInt32 size = (UInt64)param3;
    
    if (name && data) {
      W836xSensor *sensor = OSDynamicCast(W836xSensor, getSensor(name));
      if (sensor) {
        UInt16 value;
        bcopy(data, &value, 2);
        sensor->setValue(value);
        return kIOReturnSuccess;
      }
    }
    return kIOReturnBadArgument;
  }*/
  
  return super::callPlatformFunction(functionName, waitForFunction, param1, param2, param3, param4);
}

#pragma mark kext life cicle
bool W836x::init(OSDictionary *properties)
{
	DebugLog("initialising...");
  bzero(nvram_data, 44);
  if (!super::init(properties))
		return false;
  
	return true;
}

IOService* W836x::probe(IOService *provider, SInt32 *score)
{
	DebugLog("probing...");
  
	if (super::probe(provider, score) != this)
		return 0;
  
	return this;
}

void W836x::stop (IOService* provider)
{
	DebugLog("stoping...");
  if (fanControl && timer)
  {
    timer->cancelTimeout();
    workLoop->removeEventSource(timer);
    timer = NULL;
  }
  
  PMstop();
  if (kIOReturnSuccess != fakeSMC->callPlatformFunction(kFakeSMCRemoveKeyHandler,
                                                        true,
                                                        this,
                                                        NULL,
                                                        NULL,
                                                        NULL)) {
    WarningLog("Can't remove key handler");
    IOSleep(500);
  }
  if (lock)
    IOLockFree(lock);

	super::stop(provider);
}

void W836x::free ()
{
	DebugLog("freeing...");
  
	super::free();
}

bool W836x::start(IOService * provider)
{
  DebugLog("starting ...");

  if (!super::start(provider))
    return false;
  lock = IOLockAlloc();
  PMinit();
  registerPowerDriver(this, powerStates, sizeof(powerStates) / sizeof(IOPMPowerState));
  provider->joinPMtree(this);
  
  char modelStr[7];
  snprintf(modelStr, 7, "0x%04x", model);
  IOService::setProperty("model", OSString::withCString(modelStr));

  InfoLog("found %s", getModelName());
  OSDictionary* list = OSDynamicCast(OSDictionary, getProperty("Sensors Configuration"));
  OSDictionary *configuration=NULL;
  IORegistryEntry * rootNode;

  rootNode = fromPath("/efi/platform", gIODTPlane);

  if(rootNode)
  {
    OSData *data = OSDynamicCast(OSData, rootNode->getProperty("OEMVendor"));
    if (data) {
      bcopy(data->getBytesNoCopy(), vendor, data->getLength());
      OSString * VendorNick = vendorID(OSString::withCString(vendor));
      if (VendorNick)
      {
        data = OSDynamicCast(OSData, rootNode->getProperty("OEMBoard"));
        if (!data) {
          WarningLog("no OEMBoard");
          data = OSDynamicCast(OSData, rootNode->getProperty("OEMProduct"));
        }
        if (data)
        {
          bcopy(data->getBytesNoCopy(), product, data->getLength());
          OSDictionary *link = OSDynamicCast(OSDictionary, list->getObject(VendorNick));
          if (link){
            configuration = OSDynamicCast(OSDictionary, link->getObject(OSString::withCString(product)));
            InfoLog(" mother vendor=%s product=%s", vendor, product);
          }
        }
      }
      else
      {
        WarningLog("unknown OEMVendor %s", vendor);
      }
    }
    else
    {
      WarningLog("no OEMVendor");
    }
  }

  if (list && !configuration)
  {
    configuration = OSDynamicCast(OSDictionary, list->getObject("Default"));
    WarningLog("set default configuration");
  }

  if(configuration)
    this->setProperty("Current Configuration", configuration);

  OSBoolean* tempin0forced = configuration ? OSDynamicCast(OSBoolean, configuration->getObject("TEMPIN0FORCED")) : 0;
  OSBoolean* tempin1forced = configuration ? OSDynamicCast(OSBoolean, configuration->getObject("TEMPIN1FORCED")) : 0;

  if (OSNumber* fanlimit = configuration ? OSDynamicCast(OSNumber, configuration->getObject("FANINLIMIT")) : 0)
    fanLimit = fanlimit->unsigned8BitValue();
  
  safeToWrite = true;

  //  cpuid_update_generic_info();

  bool isCpuCore_i = false;

  /*  if (strcmp(cpuid_info()->cpuid_vendor, CPUID_VID_INTEL) == 0)
   {
   switch (cpuid_info()->cpuid_family)
   {
   case 0x6:
   {
   switch (cpuid_info()->cpuid_model)
   {
   case 0x1A: // Intel Core i7 LGA1366 (45nm)
   case 0x1E: // Intel Core i5, i7 LGA1156 (45nm)
   case 0x25: // Intel Core i3, i5, i7 LGA1156 (32nm)
   case 0x2C: // Intel Core i7 LGA1366 (32nm) 6 Core
   isCpuCore_i = true;
   break;
   }
   }  break;
   }
   isCpuCore_i = (cpuid_info()->cpuid_model >= 0x1A);
   } */

  if (isCpuCore_i)
  {
    // Heatsink
    if (!addSensor(KEY_CPU_HEATSINK_TEMPERATURE, TYPE_SP78, 2, kSuperIOTemperatureSensor, 2))
      return false;
  }
  else
  {
    switch (model)
    {
      case W83667HG:
      case W83667HGB:
      {
        // do not add temperature sensor registers that read PECI
        UInt8 flag = readByte(0, WINBOND_TEMPERATURE_SOURCE_SELECT_REG);

        if ((flag & 0x04) == 0 || (tempin0forced && tempin0forced->getValue()))
        {
          // Heatsink
          if (!addSensor(KEY_CPU_HEATSINK_TEMPERATURE, TYPE_SP78, 2, kSuperIOTemperatureSensor, 0))
            WarningLog("error adding heatsink temperature sensor");
        }
        else if ((flag & 0x40) == 0 || (tempin1forced && tempin1forced->getValue()))
        {
          // Ambient
          if (!addSensor(KEY_AMBIENT_TEMPERATURE, TYPE_SP78, 2, kSuperIOTemperatureSensor, 1))
            WarningLog("error adding ambient temperature sensor");
        }

        // Northbridge
        if (!addSensor(KEY_NORTHBRIDGE_TEMPERATURE, TYPE_SP78, 2, kSuperIOTemperatureSensor, 2))
          WarningLog("error adding system temperature sensor");

        break;
      }

      case W83627DHG:
      case W83627DHGP:
      {
        // do not add temperature sensor registers that read PECI
        UInt8 sel = readByte(0, WINBOND_TEMPERATURE_SOURCE_SELECT_REG);

        if ((sel & 0x07) == 0 || (tempin0forced && tempin0forced->getValue()))
        {
          // Heatsink
          if (!addSensor(KEY_CPU_HEATSINK_TEMPERATURE, TYPE_SP78, 2, kSuperIOTemperatureSensor, 0))
            WarningLog("error adding heatsink temperature sensor");
        }
        else if ((sel & 0x70) == 0 || (tempin1forced && tempin1forced->getValue()))
        {
          // Ambient
          if (!addSensor(KEY_AMBIENT_TEMPERATURE, TYPE_SP78, 2, kSuperIOTemperatureSensor, 1))
            WarningLog("error adding ambient temperature sensor");
        }

        // Northbridge
        if (!addSensor(KEY_NORTHBRIDGE_TEMPERATURE, TYPE_SP78, 2, kSuperIOTemperatureSensor, 2))
          WarningLog("error adding system temperature sensor");

        break;
      }

      default:
      {
        // no PECI support, add all sensors

        // Heatsink
        if (!addSensor(KEY_CPU_HEATSINK_TEMPERATURE, TYPE_SP78, 2, kSuperIOTemperatureSensor, 0))
          WarningLog("error adding heatsink temperature sensor");

        // Ambient
        if (!addSensor(KEY_AMBIENT_TEMPERATURE, TYPE_SP78, 2, kSuperIOTemperatureSensor, 1))
          WarningLog("error adding ambient temperature sensor");

        // Northbridge
        if (!addSensor(KEY_NORTHBRIDGE_TEMPERATURE, TYPE_SP78, 2, kSuperIOTemperatureSensor, 2))
          WarningLog("error adding system temperature sensor");

        if (model >= NCT6771F)
        {
          if (!addSensor(KEY_DIMM_TEMPERATURE, TYPE_SP78, 2, kSuperIOTemperatureSensor, 3))
            WarningLog("error adding system temperature sensor");
        }

        break;
      }
    }
  }

  // Voltage
  if (configuration)
  {
    for (int i = 0; i < voltagesCount; i++)
    {
      char key[6];
      long Ri=0;
      long Rf=1;
      long Vf=0;
      OSString * name;

      snprintf(key, 6, "VIN%X", i);

      if (process_sensor_entry(configuration->getObject(key), &name, &Ri, &Rf, &Vf))
      {
        if (name->isEqualTo("CPU"))
        {
          if (!addSensor(KEY_CPU_VRM_SUPPLY0, TYPE_FP2E, 2, kSuperIOVoltageSensor, i,Ri,Rf,Vf))
            WarningLog("error adding CPU voltage sensor");
        }
        else if (name->isEqualTo("Memory"))
        {
          if (!addSensor(KEY_MEMORY_VOLTAGE, TYPE_FP2E, 2, kSuperIOVoltageSensor, i, Ri, Rf, Vf))
            WarningLog("error adding memory voltage sensor");
        }
        else if (name->isEqualTo("+5VC"))
        {
          if (Ri == 0)
          {
            Ri = 20; //Rodion
            Rf = 10;
          }
          if (!addSensor(KEY_5VC_VOLTAGE, TYPE_SP4B, 2, kSuperIOVoltageSensor, i, Ri, Rf, Vf))
            WarningLog("ERROR Adding AVCC Voltage Sensor!");
        }
        else if (name->isEqualTo("+5VSB"))
        {
          if (Ri == 0)
          {
            Ri = 20; //Rodion
            Rf = 10;
          }
          if (!addSensor(KEY_5VSB_VOLTAGE, TYPE_SP4B, 2, kSuperIOVoltageSensor, i, Ri, Rf, Vf))
            WarningLog("ERROR Adding AVCC Voltage Sensor!");
        }
        else if (name->isEqualTo("+12VC"))
        {
          if (Ri == 0)
          {
            Ri = 60;  //Rodion - 60, Datasheet 56 (?)
            Rf = 10;
          }
          if (!addSensor(KEY_12V_VOLTAGE, TYPE_SP4B, 2, kSuperIOVoltageSensor, i, Ri, Rf, Vf))
            WarningLog("ERROR Adding 12V Voltage Sensor!");
        }
        else if (name->isEqualTo("-12VC"))
        {
          if (Ri == 0)
          {
            Ri = 232; // Rodion - у меня нет такого. в datasheet 232 (?)
            Rf = 10;
            Vf = 2048;
          }
          if (!addSensor(KEY_N12VC_VOLTAGE, TYPE_SP4B, 2, kSuperIOVoltageSensor, i, Ri, Rf, Vf))
            WarningLog("ERROR Adding 12V Voltage Sensor!");
        }
        else if (name->isEqualTo("3VCC"))
        {
          if (Ri == 0)
          {
//            Ri = 34; Rodion
//            Rf = 34;  оно уже посчитано здесь { 8,     8,     16,    16,    8,     8,     8,     16,    16 };
          }
          if (!addSensor(KEY_3VCC_VOLTAGE, TYPE_FP2E, 2, kSuperIOVoltageSensor, i, Ri, Rf, Vf))
            WarningLog("ERROR Adding 3VCC Voltage Sensor!");
        }

        else if (name->isEqualTo("3VSB"))
        {
          if (Ri == 0)
          {
//            Ri = 34;
//            Rf = 34;
          }
          if (!addSensor(KEY_3VSB_VOLTAGE, TYPE_FP2E, 2, kSuperIOVoltageSensor, i, Ri, Rf, Vf))
            WarningLog("ERROR Adding 3VSB Voltage Sensor!");
        }
        else if (name->isEqualTo("VBAT"))
        {
          if (Ri == 0)
          {
//            Ri = 34; Rodion - проверить не могу...но, по аналогии ))
//            Rf = 34;
          }
          if (!addSensor(KEY_VBAT_VOLTAGE, TYPE_FP2E, 2, kSuperIOVoltageSensor, i, Ri, Rf, Vf))
            WarningLog("ERROR Adding VBAT Voltage Sensor!");
        }
        else if (name->isEqualTo("AVCC"))
        {
          if (Ri == 0)
          {
//            Ri = 34;
//            Rf = 34;
          }
          if (!addSensor(KEY_AVCC_VOLTAGE, TYPE_FP2E, 2, kSuperIOVoltageSensor, i, Ri, Rf, Vf))
            WarningLog("ERROR Adding AVCC Voltage Sensor!");
        }
      }
    }
  }
  
  
  // FANs
  for (int i = 0; i < fanLimit; i++)
  {
    fanValueObsolete[i] = true;
    saveDefaultFanControl(i);
  }
  
  updateTachometers();
  
  for (int i = 0; i < fanLimit; i++)
  {
    OSString* name = 0;
    char key[7];
    if (configuration)
    {
      snprintf(key, 7, "FANIN%X", i);
      name = OSDynamicCast(OSString, configuration->getObject(key));
      
    }
    if (!name || name->getLength() == 0)
    {
      snprintf(key, 6, "Fan %X", i);
      name = OSString::withCString(key);
    }
    
    long rpm = readTachometer(i);
    if (rpm >= minFanRPM && rpm <= maxFanRPM)
    {
      if (!addTachometer(i, name->getCStringNoCopy()))
        WarningLog("error adding tachometer sensor %d", i);
    }
    
  }
  /* doing that in the pm call
  timer = IOTimerEventSource::timerEventSource(this,
                                               OSMemberFunctionCast(IOTimerEventSource::Action,
                                                                    this,
                                                                    &W836x::readNVRAMFansControl));
  
  workLoop = getWorkLoop();
  workLoop->addEventSource(timer);
  timer->setTimeoutMS(nvramTimeOutms);
*/
  return true;
}

#pragma mark W836x hardware probing/enter/exit
void W836x::enter()
{
  outb(registerPort, 0x87);
  outb(registerPort, 0x87);
}

void W836x::exit()
{
  outb(registerPort, 0xAA);
  //outb(registerPort, SUPERIO_CONFIGURATION_CONTROL_REGISTER);
  //outb(valuePort, 0x02);
}

bool W836x::probePort()
{
  model = 0;
  
  UInt8 id =listenPortByte(SUPERIO_CHIP_ID_REGISTER);
  
  IOSleep(50);
  
  UInt8 revision = listenPortByte(SUPERIO_CHIP_REVISION_REGISTER);
  
  if (id == 0 || id == 0xff || revision == 0 || revision == 0xff)
    return false;
  
  fanLimit = 6;
  switch (id)
  {
    case 0x52:
    {
      switch (revision & 0xf0)
      {
        case 0x10:
        case 0x30:
        case 0x40:
        case 0x41:
          model = W83627HF;
          fanLimit = 3;
          fanMaxCount = 3;
          fanControlsCount = 3;
          break;
          /*case 0x70:
           model = W83977CTF;
           break;
           case 0xf0:
           model = W83977EF;
           break;*/
          
      }
    }
    case 0x59:
    {
      switch (revision & 0xf0)
      {
        case 0x50:
          model = W83627SF;
          fanLimit = 3;
          fanMaxCount = 3;
          fanControlsCount = 3;
          break;
      }
      break;
    }
      
    case 0x60:
    {
      switch (revision & 0xf0)
      {
        case 0x10:
          model = W83697HF;
          fanLimit = 2;
          fanMaxCount = 2;
          fanControlsCount = 2;
          break;
      }
      break;
    }
      
      /*case 0x61:
       {
       switch (revision & 0xf0)
       {
       case 0x00:
       model = W83L517D;
       break;
       }
       break;
       }*/
      
    case 0x68:
    {
      switch (revision & 0xf0)
      {
        case 0x10:
          model = W83697SF;
          fanLimit = 2;
          fanMaxCount = 2;
          fanControlsCount = 2;
          break;
      }
      break;
    }
      
    case 0x70:
    {
      switch (revision & 0xf0)
      {
        case 0x80:
          model = W83637HF;
          fanLimit = 5;
          fanMaxCount = 5;
          fanControlsCount = 4;
          break;
      }
      break;
    }
      
      
    case 0x82:
    {
      switch (revision & 0xF0)
      {
        case 0x80:
          model = W83627THF;
          fanLimit = 3;
          fanMaxCount = 3;
          fanControlsCount = 3;
          break;
      }
      break;
    }
      
    case 0x85:
    {
      switch (revision)
      {
        case 0x41:
          model = W83687THF;
          fanLimit = 3;
          fanMaxCount = 3;
          fanControlsCount = 3;
          // No datasheet
          break;
      }
      break;
    }
      
    case 0x88:
    {
      switch (revision & 0xF0)
      {
        case 0x50:
        case 0x60:
          model = W83627EHF;
          fanLimit = 3;
          fanMaxCount = 3;
          fanControlsCount = 3;
          break;
      }
      break;
    }
      
      /*case 0x97:
       {
       switch (revision)
       {
       case 0x71:
       model = W83977FA;
       break;
       case 0x73:
       model = W83977TF;
       break;
       case 0x74:
       model = W83977ATF;
       break;
       case 0x77:
       model = W83977AF;
       break;
       }
       break;
       }*/
      
    case 0xA0:
    {
      switch (revision & 0xF0)
      {
        case 0x20:
          model = W83627DHG;
          fanLimit = 3;
          fanMaxCount = 3;
          fanControlsCount = 3;
          break;
      }
      break;
    }
      
    case 0xA2:
    {
      switch (revision & 0xF0)
      {
        case 0x30:
          model = W83627UHG;
          fanLimit = 2;
          fanMaxCount = 2;
          fanControlsCount = 2;
          break;
      }
      break;
    }
      
    case 0xA5:
    {
      switch (revision & 0xF0)
      {
        case 0x10:
          model = W83667HG;
          fanLimit = 2;
          fanMaxCount = 2;
          fanControlsCount = 2;
          break;
      }
      break;
    }
      
    case 0xB0:
    {
      switch (revision & 0xF0)
      {
        case 0x70:
          model = W83627DHGP;
          fanLimit = 5;
          fanMaxCount = 5;
          fanControlsCount = 4;
          break;
      }
      break;
    }
      
    case 0xB3:
    {
      switch (revision & 0xF0)
      {
        case 0x50:
          model = W83667HGB;
          fanLimit = 4;
          fanMaxCount = 4;
          fanControlsCount = 4;
          break;
      }
      break;
    }
    case 0xC2:
      model = NCT6681;
      fanLimit = 5;
      fanMaxCount = 5;
      voltagesCount = 9;
      voltageRegisters = (UInt16*)WINBOND_VOLTAGE_REG;
      vBatMonitorControlRegister = 0x005D;
      voltageVBatRegister = WINBOND_VOLTAGE_VBAT_REG;
      temperatureRegisters = (UInt16*)WINBOND_TEMPERATURE;
      fanRpmBaseRegister = NCT6791D_conf.fanRpmBaseRegister;
      fanControlPWMOut = NCT6791D_conf.FAN_PWM_OUT_REG;
      fanControlsCount = fanMaxCount;
      fanControl = true;
      break;
    case 0xB4:
      switch (revision & 0xF0)
    {
      case 0x70:
        model = NCT6771F;
        //          minFanRPM = (int)(1.35e6 / 0xFFFF);
        voltagesCount = NCT6771F_conf.voltagesCount;
        voltageRegisters = NCT6771F_conf.voltageRegisters;
        vBatMonitorControlRegister = NCT6771F_conf.vBatMonitorControlRegister;
        voltageVBatRegister = NCT6771F_conf.voltageVBatRegister;
        fanRpmBaseRegister = NCT6771F_conf.fanRpmBaseRegister;
        fanControlMode = (UInt16*)NCT6771F_conf.FAN_CONTROL_MODE_REG;
        fanControlPWMCommand = (UInt16*)NCT6771F_conf.FAN_PWM_COMMAND_REG;
        fanMaxCount = NCT6771F_conf.fansCount;
        fanControlPWMOut = NCT6771F_conf.FAN_PWM_OUT_REG;
        fanControlsCount = NCT6771F_conf.controlsCount;
        fanControl = true;
        break;
    } break;
    case 0xC3:
      switch (revision & 0xF0)
    {
      case 0x30:
        model = NCT6776F;
        //          minFanRPM = (int)(1.35e6 / 0x1FFF);
        voltagesCount = NCT6776F_conf.voltagesCount;
        voltageRegisters = NCT6776F_conf.voltageRegisters;
        vBatMonitorControlRegister = NCT6776F_conf.vBatMonitorControlRegister;
        voltageVBatRegister = NCT6776F_conf.voltageVBatRegister;
        fanRpmBaseRegister = NCT6776F_conf.fanRpmBaseRegister;
        fanControlMode = (UInt16*)NCT6776F_conf.FAN_CONTROL_MODE_REG;
        fanControlPWMCommand = (UInt16*)NCT6776F_conf.FAN_PWM_COMMAND_REG;
        fanControlPWMOut = NCT6776F_conf.FAN_PWM_OUT_REG;
        fanMaxCount = NCT6776F_conf.fansCount;
        fanControlsCount = NCT6776F_conf.controlsCount;
        fanControl = true;
        break;
    } break;
    case 0xC4:
      model = NCT610X;
      voltagesCount = NCT610X_conf.voltagesCount;
      voltageRegisters = NCT610X_conf.voltageRegisters;
      vBatMonitorControlRegister = NCT610X_conf.vBatMonitorControlRegister;
      voltageVBatRegister = NCT610X_conf.voltageVBatRegister;
      temperatureRegisters = NCT610X_conf.temperatureRegisters;
      fanRpmBaseRegister = NCT610X_conf.fanRpmBaseRegister;
      fanControlMode = (UInt16*)NCT610X_conf.FAN_CONTROL_MODE_REG;
      fanControlPWMCommand = (UInt16*)NCT610X_conf.FAN_PWM_COMMAND_REG;
      fanControlPWMOut = NCT610X_conf.FAN_PWM_OUT_REG;
      fanMaxCount = NCT610X_conf.fansCount;
      fanControlsCount = NCT610X_conf.controlsCount;
      fanControl = true;
      break;
    case 0xC5:
      switch (revision & 0xF0)
    {
      case 0x60:
        model = NCT6779D;
        //          minFanRPM = (int)(1.35e6 / 0x1FFF);
        voltagesCount = NCT6779D_conf.voltagesCount;
        voltageRegisters = NCT6779D_conf.voltageRegisters;
        vBatMonitorControlRegister = NCT6779D_conf.vBatMonitorControlRegister;
        voltageVBatRegister = NCT6779D_conf.voltageVBatRegister;
        temperatureRegisters = NCT6779D_conf.temperatureRegisters;
        fanRpmBaseRegister = NCT6779D_conf.fanRpmBaseRegister;
        fanControlMode = (UInt16*)NCT6779D_conf.FAN_CONTROL_MODE_REG;
        fanControlPWMCommand = (UInt16*)NCT6779D_conf.FAN_PWM_COMMAND_REG;
        fanControlPWMOut = NCT6779D_conf.FAN_PWM_OUT_REG;
        fanMaxCount = NCT6779D_conf.fansCount;
        fanControlsCount = NCT6779D_conf.controlsCount;
        fanControl = true;
        break;
    } break;
    case 0xC7:
      model = NCT6683;
      fanLimit = 5;
      fanMaxCount = 5;
      voltagesCount = 9;
      voltageRegisters = (UInt16*)WINBOND_VOLTAGE_REG;
      vBatMonitorControlRegister = 0x005D;
      voltageVBatRegister = WINBOND_VOLTAGE_VBAT_REG;
      temperatureRegisters = (UInt16*)WINBOND_TEMPERATURE;
      fanRpmBaseRegister = NCT6791D_conf.fanRpmBaseRegister;
      fanControlPWMOut = NCT6791D_conf.FAN_PWM_OUT_REG;
      fanControlsCount = fanMaxCount;
      fanControl = true;
      break;
    case 0xC8:
      switch (revision & 0xFF)
    {
      case 0x03:
        model = NCT6791D;
        voltagesCount = NCT6791D_conf.voltagesCount;
        voltageRegisters = NCT6791D_conf.voltageRegisters;
        vBatMonitorControlRegister = NCT6791D_conf.vBatMonitorControlRegister;
        voltageVBatRegister = NCT6791D_conf.voltageVBatRegister;
        temperatureRegisters = NCT6791D_conf.temperatureRegisters;
        fanRpmBaseRegister = NCT6791D_conf.fanRpmBaseRegister;
        fanControlMode = (UInt16*)NCT6791D_conf.FAN_CONTROL_MODE_REG;
        fanControlPWMCommand = (UInt16*)NCT6791D_conf.FAN_PWM_COMMAND_REG;
        fanControlPWMOut = NCT6791D_conf.FAN_PWM_OUT_REG;
        fanMaxCount = NCT6791D_conf.fansCount;
        fanControlsCount = NCT6791D_conf.controlsCount;
        fanControl = true;
        break;
    } break;
    case 0xC9:
      switch (revision & 0xFF)
    {
      case 0x11:
        model = NCT6792D;
        voltagesCount = NCT6791D_conf.voltagesCount;
        voltageRegisters = NCT6791D_conf.voltageRegisters;
        vBatMonitorControlRegister = NCT6791D_conf.vBatMonitorControlRegister;
        voltageVBatRegister = NCT6791D_conf.voltageVBatRegister;
        temperatureRegisters = NCT6791D_conf.temperatureRegisters;
        fanRpmBaseRegister = NCT6791D_conf.fanRpmBaseRegister;
        fanControlMode = (UInt16*)NCT6791D_conf.FAN_CONTROL_MODE_REG;
        fanControlPWMCommand = (UInt16*)NCT6791D_conf.FAN_PWM_COMMAND_REG;
        fanControlPWMOut = NCT6791D_conf.FAN_PWM_OUT_REG;
        fanMaxCount = NCT6791D_conf.fansCount;
        fanControlsCount = NCT6791D_conf.controlsCount;
        fanControl = true;
        break;
    } break;
    case 0xD1:
      switch (revision & 0xFF)
    {
      case 0x21:
        model = NCT6793D;
        voltagesCount = NCT6791D_conf.voltagesCount;
        voltageRegisters = NCT6791D_conf.voltageRegisters;
        vBatMonitorControlRegister = NCT6791D_conf.vBatMonitorControlRegister;
        voltageVBatRegister = NCT6791D_conf.voltageVBatRegister;
        temperatureRegisters = NCT6791D_conf.temperatureRegisters;
        fanRpmBaseRegister = NCT6791D_conf.fanRpmBaseRegister;
        fanControlMode = (UInt16*)NCT6791D_conf.FAN_CONTROL_MODE_REG;
        fanControlPWMCommand = (UInt16*)NCT6791D_conf.FAN_PWM_COMMAND_REG;
        fanControlPWMOut = NCT6791D_conf.FAN_PWM_OUT_REG;
        fanMaxCount = NCT6791D_conf.fansCount;
        fanControlsCount = NCT6791D_conf.controlsCount;
        fanControl = true;
        break;
    } break;
    case 0xD3:
      switch (revision & 0xFF)
    {
      case 0x52:
        model = NCT6795D;
        voltagesCount = NCT6791D_conf.voltagesCount;
        voltageRegisters = NCT6791D_conf.voltageRegisters;
        vBatMonitorControlRegister = NCT6791D_conf.vBatMonitorControlRegister;
        voltageVBatRegister = NCT6791D_conf.voltageVBatRegister;
        temperatureRegisters = NCT6791D_conf.temperatureRegisters;
        fanRpmBaseRegister = NCT6791D_conf.fanRpmBaseRegister;
        fanControlMode = (UInt16*)NCT6791D_conf.FAN_CONTROL_MODE_REG;
        fanControlPWMCommand = (UInt16*)NCT6791D_conf.FAN_PWM_COMMAND_REG;
        fanControlPWMOut = NCT6791D_conf.FAN_PWM_OUT_REG;
        fanMaxCount = NCT6791D_conf.fansCount;
        fanControlsCount = NCT6791D_conf.controlsCount;
        fanControl = true;
        break;
    } break;
    case 0xD4:
      fanControl = true;
      switch (revision & 0xFF)
    {
      case 0x2B:
        model = NCT6796D;
        voltagesCount = NCT6796D_conf.voltagesCount;
        voltageRegisters = NCT6796D_conf.voltageRegisters;
        vBatMonitorControlRegister = NCT6796D_conf.vBatMonitorControlRegister;
        voltageVBatRegister = NCT6796D_conf.voltageVBatRegister;
        temperatureRegisters = NCT6796D_conf.temperatureRegisters;
        fanRpmBaseRegister = NCT6796D_conf.fanRpmBaseRegister;
        fanControlMode = (UInt16*)NCT6796D_conf.FAN_CONTROL_MODE_REG;
        fanControlPWMCommand = (UInt16*)NCT6796D_conf.FAN_PWM_COMMAND_REG;
        fanControlPWMOut = NCT6796D_conf.FAN_PWM_OUT_REG;
        fanMaxCount = NCT6796D_conf.fansCount;
        fanControlsCount = NCT6796D_conf.controlsCount;
        fanControl = true;
        break;
      case 0x23:
        model = NCT679BD;
        voltagesCount = NCT6796D_conf.voltagesCount;
        voltageRegisters = NCT6796D_conf.voltageRegisters;
        vBatMonitorControlRegister = NCT6796D_conf.vBatMonitorControlRegister;
        voltageVBatRegister = NCT6796D_conf.voltageVBatRegister;
        temperatureRegisters = NCT6796D_conf.temperatureRegisters;
        fanRpmBaseRegister = NCT6796D_conf.fanRpmBaseRegister;
        fanControlMode = (UInt16*)NCT6796D_conf.FAN_CONTROL_MODE_REG;
        fanControlPWMCommand = (UInt16*)NCT6796D_conf.FAN_PWM_COMMAND_REG;
        fanControlPWMOut = NCT6796D_conf.FAN_PWM_OUT_REG;
        fanMaxCount = NCT6796D_conf.fansCount;
        fanControlsCount = NCT6796D_conf.controlsCount;
        fanControl = true;
        break;
      case 0x28:
      case 0x58:
        model = NCT6798D;
        voltagesCount = NCT6796D_conf.voltagesCount;
        voltageRegisters = NCT6796D_conf.voltageRegisters;
        vBatMonitorControlRegister = NCT6796D_conf.vBatMonitorControlRegister;
        voltageVBatRegister = NCT6796D_conf.voltageVBatRegister;
        temperatureRegisters = NCT6796D_conf.temperatureRegisters;
        fanRpmBaseRegister = NCT6796D_conf.fanRpmBaseRegister;
        fanControlMode = (UInt16*)NCT6796D_conf.FAN_CONTROL_MODE_REG;
        fanControlPWMCommand = (UInt16*)NCT6796D_conf.FAN_PWM_COMMAND_REG;
        fanControlPWMOut = NCT6796D_conf.FAN_PWM_OUT_REG;
        fanMaxCount = NCT6796D_conf.fansCount;
        fanControlsCount = NCT6796D_conf.controlsCount;
        fanControl = true;
        break;
      case 0x50:
        model = NCT6797D;
        voltagesCount = NCT6796D_conf.voltagesCount;
        voltageRegisters = NCT6796D_conf.voltageRegisters;
        vBatMonitorControlRegister = NCT6796D_conf.vBatMonitorControlRegister;
        voltageVBatRegister = NCT6796D_conf.voltageVBatRegister;
        temperatureRegisters = NCT6796D_conf.temperatureRegisters;
        fanRpmBaseRegister = NCT6796D_conf.fanRpmBaseRegister;
        fanControlMode = (UInt16*)NCT6796D_conf.FAN_CONTROL_MODE_REG;
        fanControlPWMCommand = (UInt16*)NCT6796D_conf.FAN_PWM_COMMAND_REG;
        fanControlPWMOut = NCT6796D_conf.FAN_PWM_OUT_REG;
        fanMaxCount = NCT6796D_conf.fansCount;
        fanControlsCount = NCT6796D_conf.controlsCount;
        fanControl = true;
        break;
    } break;
    default:
      break;
  }
  
  const char *name = getModelName();
  isNuvoton = (name[0] == 'N');
  
  if (!isNuvoton)
  {
    voltagesCount = 9;
    voltageRegisters = (UInt16*)WINBOND_VOLTAGE_REG;
    vBatMonitorControlRegister = 0x005D;
    voltageVBatRegister = WINBOND_VOLTAGE_VBAT_REG;
    temperatureRegisters = (UInt16*)WINBOND_TEMPERATURE;
  }
  
  if (fanLimit > fanMaxCount) fanLimit = fanMaxCount;
  
  if (!model)
  {
    WarningLog("found unsupported chip ID=0x%x REVISION=0x%x", id, revision);
    char modelStr[7];
    snprintf(modelStr, 7, "0x%02x%02x", id, revision);
    IOService::setProperty("model", OSString::withCString(modelStr));
    return false;
  }
  
  selectLogicalDevice(HARDWARE_MONITOR_LDN);
  
  IOSleep(50);
  //    UInt16 vendor = (UInt16)(readByte(0x80, WINBOND_VENDOR_ID_REGISTER) << 8) | readByte(0, WINBOND_VENDOR_ID_REGISTER);
  //
  //    if (vendor != WINBOND_VENDOR_ID)
  //    {
  //        DebugLog("wrong vendor ID=0x%x", vendor);
  //        return false;
  //    }
  //
  //    IOSleep(50);
  
  if (!getLogicalDeviceAddress())
  {
    DebugLog("can't get monitoring logical device address");
    return false;
  }
  
  disableIOSpaceLock();
  
  // user is responsible to play with fans
  if (fanControl)
    fanControl = PE_parse_boot_argn(kFanControlFlag, gArgBuf, sizeof(gArgBuf));
  
  return true;
}


const char *W836x::getModelName()
{
  switch (model)
  {
    case W83627DHG:     return "W83627DHG";
    case W83627DHGP:    return "W83627DHG-P";
    case W83627EHF:     return "W83627EHF";
    case W83627HF:      return "W83627HF";
    case W83627THF:     return "W83627THF";
    case W83667HG:      return "W83667HG";
    case W83667HGB:     return "W83667HG-B";
    case W83687THF:     return "W83687THF";
    case W83627SF:      return "W83627SF";
    case W83697HF:      return "W83697HF";
    case W83637HF:      return "W83637HF";
    case W83627UHG:     return "W83627UHG";
    case W83697SF:      return "W83697SF";
    case NCT6681:       return "NCT6681";
    case NCT6683:       return "NCT6683";
    case NCT6771F:      return "NCT6771F";
    case NCT610X:       return "NCT610X";
    case NCT6776F:      return "NCT6776F";
    case NCT6779D:      return "NCT6779D";
    case NCT6791D:      return "NCT6791D/NCT5538D";
    case NCT6792D:      return "NCT6792D";
    case NCT6793D:      return "NCT6793D";
    case NCT6795D:      return "NCT6795D";
    case NCT6796D:      return "NCT6796D";
    case NCT6797D:      return "NCT6797D";
    case NCT6798D:      return "NCT6798D";
    case NCT679BD:      return "NCT679BD";
  }

  return "unknown";
}

#pragma mark power management
IOReturn W836x::setPowerState(unsigned long powerStateOrdinal, IOService *whatDevice)
{
  switch (powerStateOrdinal)
  {
    case kStateOff:
      // sleep
      safeToWrite = false;
      if (fanControl && timer)
      {
        timer->cancelTimeout();
        workLoop->removeEventSource(timer);
        timer = NULL;
      }
      exit();
      break;
    case kStateOn:
      // wake
      safeToWrite = true;
      dumplogged = false;
      if (fanControl) {
        if (timer == NULL) {
          timer = IOTimerEventSource::timerEventSource(this,
                                                       OSMemberFunctionCast(IOTimerEventSource::Action,
                                                                            this,
                                                                            &W836x::readNVRAMFansControl));
          if (workLoop == NULL)
            workLoop = getWorkLoop();
          
          workLoop->addEventSource(timer);
          timer->setTimeoutMS(nvramTimeOutms);
        }
      }

      enter();
      disableIOSpaceLock();
      safeToWrite = true;
      break;
  }
  return IOPMAckImplied;
}

#pragma mark readings
/*
 Read registers
 */
UInt8 W836x::readByte(UInt8 bank, UInt8 reg)
{
  outb((UInt16)(address + ADDRESS_REGISTER_OFFSET), BANK_SELECT_REGISTER);
  outb((UInt16)(address + DATA_REGISTER_OFFSET), bank);
  outb((UInt16)(address + ADDRESS_REGISTER_OFFSET), reg);
  return inb((UInt16)(address + DATA_REGISTER_OFFSET));
}

/*
 Write registers
 */
void W836x::writeByte(UInt8 bank, UInt8 reg, UInt8 value)
{
  outb((UInt16)(address + ADDRESS_REGISTER_OFFSET), BANK_SELECT_REGISTER);
  outb((UInt16)(address + DATA_REGISTER_OFFSET), bank);
  outb((UInt16)(address + ADDRESS_REGISTER_OFFSET), reg);
  outb((UInt16)(address + DATA_REGISTER_OFFSET), value);
}

/*
 Set a bit
 */
UInt64 W836x::setBit(UInt64 target, UInt16 bit, UInt32 value)
{
  if (((value & 1) == value) && bit <= 63)
  {
    UInt64 mask = (((UInt64)1) << bit);
    return value > 0 ? target | mask : target & ~mask;
  }
  
  return value;
}

/*
 Read temperature for a specific sensor at index.
 Used for new Nuvoton chips
 */
long W836x::readNuvotonTemperature(UInt16 temperatureRegister)
{
  UInt8 bank = temperatureRegister >> 8;
  UInt8 reg = temperatureRegister & 0xFF;
  UInt8 value = readByte(bank, reg) << 1;
  float temperature = 0.5f * value;
  return (temperature >= -55 && temperature <= 125) ? temperature : 0;
}

/*
 Read temperature for a specific sensor at index.
 */
long W836x::readTemperature(unsigned long index)
{
  UInt8 bank, reg;
  UInt8 value;
  
  if (isNuvoton)
    return readNuvotonTemperature(temperatureRegisters[index]);
  
  bank = temperatureRegisters[index] >> 8;
  reg = temperatureRegisters[index] & 0xFF;
  value = readByte(bank, reg) << 1;
  
  if (bank > 0)
    value |= (readByte(bank, (UInt8)(reg + 1)) >> 7) & 1;
  
  float temperature = (float)value / 2.0f;
  
  return (temperature <= 125 && temperature >= -55) ? temperature : 0;
}

/*
 Read voltage for a specific sensor at index.
 */
long W836x::readVoltage(unsigned long index)
{
  UInt32 scale;
  float value = 0;
  bool valid = false;
  
  if (voltageVBatRegister && index < voltagesCount)
  {
    if (!isNuvoton) scale = WINBOND_VOLTAGE_SCALE[index];
    UInt8 reg =  voltageRegisters[index] & 0xFF;
    UInt8 bank = voltageRegisters[index] >> 8;
    value = readByte(bank, reg) * (isNuvoton ? 0.008f : scale);
    valid = value > 0;
    // check if battery voltage monitor is enabled
    if (valid && voltageRegisters[index] == voltageVBatRegister)
      reg =  vBatMonitorControlRegister & 0xFF;
    bank = vBatMonitorControlRegister >> 8;
    valid = (readByte(bank, reg) & 0x01) > 0;
  }
  
  return valid ? value : 0;
}

/*
 Update all fans values.
 */
void W836x::updateTachometers()
{
  if (isNuvoton)
  {
    for (int i = 0; i < fanLimit; i++)
    {
      UInt8 bank = (fanRpmBaseRegister + (i << 1)) >> 8;
      UInt8 reg  = (fanRpmBaseRegister + (i << 1)) & 0xFF;
      UInt8 msbyte = readByte(bank, reg);
      UInt8 lsbyte = readByte(bank, reg + 1);
      float value = (msbyte << 8) | lsbyte;
      value = value > minFanRPM ? value : 0;
      fanValue[i] = value;
      fanValueObsolete[i] = false;
    }
    return;
  }
  
  UInt64 bits = 0;
  
  for (int i = 0; i < 5; i++)
  {
    bits = (bits << 8) | readByte(0, WINBOND_TACHOMETER_DIVISOR[i]);
  }
  
  UInt64 newBits = bits;
  
  for (int i = 0; i < fanLimit; i++)
  {
    // assemble fan divisor
    UInt8 offset =  (((bits >> WINBOND_TACHOMETER_DIVISOR2[i]) & 1) << 2) |
    (((bits >> WINBOND_TACHOMETER_DIVISOR1[i]) & 1) << 1) |
    ((bits >> WINBOND_TACHOMETER_DIVISOR0[i]) & 1);
    
    UInt8 divisor = 1 << offset;
    UInt8 count = readByte(WINBOND_TACHOMETER_BANK[i], WINBOND_TACHOMETER[i]);
    
    // update fan divisor
    if (count > 192 && offset < 7)
    {
      offset++;
    }
    else if (count < 96 && offset > 0)
    {
      offset--;
    }
    
    float value = (count < 0xff) ? 1.35e6f / (float(count * divisor)) : 0;
    fanValue[i] = value;
    fanValueObsolete[i] = false;
    
    newBits = setBit(newBits, WINBOND_TACHOMETER_DIVISOR2[i], (offset >> 2) & 1);
    newBits = setBit(newBits, WINBOND_TACHOMETER_DIVISOR1[i], (offset >> 1) & 1);
    newBits = setBit(newBits, WINBOND_TACHOMETER_DIVISOR0[i],  offset       & 1);
  }
  
  // write new fan divisors
  for (int i = 4; i >= 0; i--)
  {
    UInt8 oldByte = bits & 0xff;
    UInt8 newByte = newBits & 0xff;
    
    if (oldByte != newByte)
    {
      writeByte(0, WINBOND_TACHOMETER_DIVISOR[i], newByte);
    }
    
    bits = bits >> 8;
    newBits = newBits >> 8;
  }
}

/*
 Actual Fan speed.
 */
long W836x::readTachometer(unsigned long index)
{
  if (fanValueObsolete[index])
    updateTachometers();
  
  fanValueObsolete[index] = true;
  
  return fanValue[index];
}

/*
 Fan min speed acquired during calibration.
 The user can modify the NVRAM to make appear different value
 */
long W836x::readTachometerMin(unsigned long index)
{
  long min = (UInt16)(nvram_data[16 + (index << 1)] << 8 | (nvram_data[16 + (index << 1) + 1] & 0xFF));
  return  (min >= minFanRPM && min <= maxFanRPM) ? min : minFanRPM;
}

/*
 Fan max speed acquired during calibration.
 The user can modify the NVRAM to make appear different value
 */
long W836x::readTachometerMax(unsigned long index)
{
  return fanControl ?
  (UInt16)(nvram_data[30 + (index << 1)] << 8 | (nvram_data[30 + (index << 1) + 1] & 0xFF))
  : fanValue[index];
}

/*
 Target value decided by the user
 */
long W836x::readTachometerTarget(unsigned long index)
{
  /*
   if target value is zero sensor will not show up.
   Anyway set it to the max until the user will set its custom value
   */
  
  long target = (UInt16)(nvram_data[(index << 1) + 2] << 8 | (nvram_data[(index << 1) + 2 + 1] & 0xFF));
  return target > minFanRPM ? target : readTachometerMax(index);
}

/*
 Return a value for the control keys:
 0 or 1 if in the format of "F0Md" by default
 or an UInt16 value if user choose the legacy key "FS! "
 */
long W836x::readTachometerControl(unsigned long index)
{
  UInt16 ctrl = (UInt16)(nvram_data[1] << 8 | (nvram_data[0] & 0xFF));
  return useFanForceNewKeys
  ? ((ctrl & (1U << index)) >> index ? 1 : 0)
  : ctrl;
}

/*
 Save Motherboards default Fan's control.
 This funcion must be called only once just befor start controlling fans
 */
void W836x::saveDefaultFanControl(unsigned long index)
{
  UInt8 bank, reg;
  if (isNuvoton)
  {
    bank = fanControlMode[index] >> 8;
    reg  = fanControlMode[index] & 0xFF;
    initialFanControlMode[index] = readByte(bank, reg);
    
    bank = fanControlPWMCommand[index] >> 8;
    reg  = fanControlPWMCommand[index] & 0xFF;
    initialFanPwmCommand[index] = readByte(bank, reg);
  }
  else
  {
    // Windbond
    bank = W83627EHF_REG_PWM_ENABLE[index] >> 8;
    reg  = W83627EHF_REG_PWM_ENABLE[index] & 0xFF;
    initialFanControlMode[index] = readByte(bank, reg);
    
    bank = W83627EHF_REG_PWM[index] >> 8;
    reg  = W83627EHF_REG_PWM[index] & 0xFF;
    initialFanPwmCommand[index] = readByte(bank, reg);
  }
}

/*
 Restore Motherboards default Fan's control.
 Only works if saveDefaultFanControl() was called (once) before start controlling
 */
void W836x::restoreDefaultFanControl(unsigned long index)
{
  if (restoreDefaultFanControlRequired[index])
  {
    UInt8 bank, reg;
    if (isNuvoton)
    {
      bank = fanControlMode[index] >> 8;
      reg  = fanControlMode[index] & 0xFF;
      writeByte(bank, reg, initialFanControlMode[index]);
      
      bank = fanControlPWMCommand[index] >> 8;
      reg  = fanControlPWMCommand[index] & 0xFF;
      writeByte(bank, reg, initialFanPwmCommand[index]);
    }
    else
    {
      // Windbond
      bank = W83627EHF_REG_PWM_ENABLE[index] >> 8;
      reg  = W83627EHF_REG_PWM_ENABLE[index] & 0xFF;
      writeByte(bank, reg, initialFanControlMode[index]);
      
      bank = W83627EHF_REG_PWM[index] >> 8;
      reg  = W83627EHF_REG_PWM[index] & 0xFF;
      writeByte(bank, reg, initialFanPwmCommand[index]);
    }
    restoreDefaultFanControlRequired[index] = false;
  }
}

/*
 Set target rpm. rpms are translated to a percentage
 */
void W836x::setControl(unsigned long index, UInt16 rpm)
{
  if (fanControl && index < fanControlsCount)
  {
    float targetRPM = rpm > maxFanRPM ? maxFanRPM : rpm;
    if (targetRPM >= minFanRPM )
    {
      int percentage = readTachometerControlPercent(index), newPercentage = 0;
      
      if (fanCalibrationStatus == minCalibration) {
        newPercentage = 0;
      } else if (fanCalibrationStatus == maxCalibration) {
        newPercentage = 100;
      }
      else
      {
        float tolerance = 20;
        percentage = readTachometerControlPercent(index);
        newPercentage = (percentage * (targetRPM + tolerance)) / fanValue[index];
      }
      // stay on the range..
      if (newPercentage < 0 || newPercentage > 100)
        newPercentage = 100;
      DebugLog("Fan %lu newPercentage = %d, rpm = %d", index,newPercentage, (int)targetRPM);
      // don't chage anything if the difference is +/- 1%
      bool dontWrite = false;
      if (fanCalibrationStatus != conluded)
      {
        dontWrite = (newPercentage + 1 == percentage || newPercentage - 1 == percentage);
      }
      if (!dontWrite) {
        UInt8 bank, reg;
        if (isNuvoton)
        {
          // set manual mode
          bank = fanControlMode[index] >> 8;
          reg  = fanControlMode[index] & 0xFF;
          writeByte(bank, reg, 0xFF);
          
          // set output value
          bank = fanControlPWMCommand[index] >> 8;
          reg  = fanControlPWMCommand[index] & 0xFF;
          writeByte(bank, reg, newPercentage * 2.55);
        }
        else
        {
          // Windbond
          /*
           reg = w83627ehf_read_value(data, W83627EHF_REG_PWM_ENABLE[nr]);
           reg &= ~(0x03 << W83627EHF_PWM_ENABLE_SHIFT[nr]);
           reg |= (val - 1) << W83627EHF_PWM_ENABLE_SHIFT[nr];
           w83627ehf_write_value(data, W83627EHF_REG_PWM_ENABLE[nr], reg);
           */
          // set manual mode
          bank = W83627EHF_REG_PWM_ENABLE[index] >> 8;
          reg  = W83627EHF_REG_PWM_ENABLE[index] & 0xFF;
          writeByte(bank, reg, 0);
          
          // set output value
          bank = W83627EHF_REG_PWM[index] >> 8;
          reg  = W83627EHF_REG_PWM[index] & 0xFF;
          writeByte(bank, reg, newPercentage * (model == W83687THF ? 1.27 : 2.55));
        }
        restoreDefaultFanControlRequired[index] = true;
      }
      
      if (fanCalibrationStatus == maxCalibration)
      {
        // We are mostly done with calibration,
        // set max rpm as target rpm at the end of calibration
        nvram_data[30 + (index << 1)]     = (UInt16)targetRPM >> 8;
        nvram_data[30 + (index << 1) + 1] = (UInt16)targetRPM & 0xFF;
        
        // adjust min and max since there's a possibility that non PWM fans
        // can have just a littel difference during min and max calibration
        // and exclude min value > of max value. In this case min = max!
        long min = readTachometerMin(index);
        long max = readTachometerMax(index);
        if (min > max) {
          nvram_data[16 + (index << 1)]     = nvram_data[30 + (index << 1)];
          nvram_data[16 + (index << 1) + 1] = nvram_data[30 + (index << 1) + 1];
        }
        return;
      }
      nvram_data[2 + (index << 1)]     = (UInt16)targetRPM >> 8;
      nvram_data[2 + (index << 1) + 1] = (UInt16)targetRPM & 0xFF;
    }
  }
}

/*
 Reading the actual percentage of speed used
 */
UInt8 W836x::readTachometerControlPercent(unsigned long index)
{
  if (isNuvoton)
  {
    UInt8 bank = fanControlPWMOut[index] >> 8;
    UInt8 reg  = fanControlPWMOut[index] & 0xFF;
    
    return readByte(bank, reg) / 2.55;
  }
  
  UInt8 value = readByte(0, W83627EHF_REG_PWM[index]);
  
  return (model == W83687THF) ? ((value >> 8) / 1.27) : (value / 2.55);
}

/*
 Write a key to NVRAM with data as object
 */
void W836x::writeKeyToNVRAM(const OSSymbol *key, OSData *data)
{
  if (safeToWrite && key && data) {
    if (IORegistryEntry *options = OSDynamicCast(IORegistryEntry,
                                                 IORegistryEntry::fromPath(kNVRAMPath,
                                                                           gIODTPlane)))
    {
      if (IODTNVRAM *nvram = OSDynamicCast(IODTNVRAM, options))
      {
        //IOLockLock(lock);
        nvram->setProperty(key, data);
        //IOLockUnlock(lock);
        OSSafeReleaseNULL(nvram);
      }
    }
  }
  OSSafeReleaseNULL(key);
}

/*
 Remove a key from the NVRAM
 */
void W836x::deleteNVRAMKey(const OSSymbol *key)
{
  if (safeToWrite && key)
  {
    if (IORegistryEntry *options = OSDynamicCast(IORegistryEntry,
                                                 IORegistryEntry::fromPath(kNVRAMPath,
                                                                           gIODTPlane)))
    {
      if (IODTNVRAM *nvram = OSDynamicCast(IODTNVRAM, options))
      {
        //IOLockLock(lock);
        if (nvram->getProperty(key))
          nvram->removeProperty(key);
        //IOLockUnlock(lock);
        OSSafeReleaseNULL(nvram);
      }
    }
  }
  OSSafeReleaseNULL(key);
}

/*
 Easy method to manual control each fan.
 P.S. nvram is persistent across reboots :-)
 */
void W836x::readNVRAMFansControl()
{
  if (!fanControl) return;
  
  // do nothing until the nvram is up.
  if (fanCalibrationStatus == doNothing || fanCalibrationStatus == conluded)
  {
    if (IORegistryEntry *options = OSDynamicCast(IORegistryEntry,
                                                 IORegistryEntry::fromPath(kNVRAMPath,
                                                                           gIODTPlane)))
    {
      if (IODTNVRAM *nvram = OSDynamicCast(IODTNVRAM, options))
      {
        char key[18];
        snprintf(key, 14, kFanControlKey);
        OSData *data = OSDynamicCast(OSData, nvram->getProperty(key));
        if (data && (data->getLength() >= 1))
        {
          UInt8 *nvram_ctrl = (UInt8 *)data->getBytesNoCopy();
          
          if (nvram_ctrl[0] >= 0x01 && nvram_ctrl[0] < 0xFF)
          {
            snprintf(key, 18, kFanControlData);
            data = OSDynamicCast(OSData, nvram->getProperty(key));
            if (data && (data->getLength() == 44))
            {
              bcopy(data->getBytesNoCopy(), &nvram_data, 44);
              UInt16 ctrl = (UInt16)(nvram_data[1] << 8 | (nvram_data[0] & 0xFF));
              fanCalibrationStatus = conluded; // we have everythings we need
              nvramTimeOutms = kFanControlCalibrationInterval;
              for (int i = 0; i < fanLimit; i++) {
                UInt16 value = (UInt16)(nvram_data[2 + (i << 1)] << 8 |
                                        (nvram_data[2 + (i << 1) + 1] & 0xFF));
                
                if (value && (ctrl & (1U << i)) >> i)
                {
                  setControl(i, value);
                }
                else
                {
                  // zero not allowed, let the motherboard doing its job
                  restoreDefaultFanControl(i);
                }
              }
            } else {
              //fanCalibrationStatus = initiate; // no valid data, calibrate fans
              // nope, if nvram isn't present can be because is updating: do nothing!
            }
          }
          else if (nvram_ctrl[0] == 0xFF) {
            // user wants to calibrate min and max fan's rpms
            InfoLog("Fan calibration requested.");
            fanCalibrationStatus = initiate;
          }
          else
          {
            // user doesn't want the Fan control, at least at the moment, take a look later
            timer->setTimeoutMS(kFanControlDisabledInterval);
            return;
          }
        }
        else
        {
          fanCalibrationStatus = initiate;
        }
      }
      else
      {
        // NVRAM not yet published. Do nothing until is available
        fanCalibrationStatus = doNothing;
      }
    }
    else
    {
      // NVRAM not yet published. Do nothing until is available
      fanCalibrationStatus = doNothing;
    }
  }
  
  
  // needs calibration or user has cleared the nvram
  if (fanCalibrationStatus == initiate)
  {
    bzero(nvram_data, 44);
    fanCalibrationStatus = minCalibration;
    updateTachometers();
    // fans calibration begin by storing lower values detected
    for (int i = 0; i < fanLimit; i++)
    {
      setControl(i, minFanRPM);
    }
    
    nvramTimeOutms = kFanControlCalibrationInterval;
  }
  else if (fanCalibrationStatus == minCalibration)
  {
    DebugLog("minCalibration");
    // read minimum values
    fanCalibrationStatus = maxCalibration;
    updateTachometers();
    for (int i = 0; i < fanLimit; i++)
    {
      UInt16 val = hw_ceil(fanValue[i] / 10) * 10;
      nvram_data[16 + (i << 1)] = val >> 8;
      nvram_data[16 + (i << 1) + 1] = val & 0xFF;
      setControl(i, maxFanRPM);
    }
    
    nvramTimeOutms = kFanControlCalibrationInterval + 3000;
  }
  else if (fanCalibrationStatus == maxCalibration)
  {
    DebugLog("maxCalibration");
    // read max values..
    updateTachometers();
    for (int i = 0; i < fanLimit; i++)
    {
      UInt16 val = hw_round(fanValue[i] / 10) * 10;
      nvram_data[30 + (i << 1)] = val >> 8;
      nvram_data[30 + (i << 1) + 1] = val & 0xFF;
      // .. and restore  mobos default
      restoreDefaultFanControl(i);
    }
    
    // keep normal interval
    enableNVRAMFansControl();
    fanCalibrationStatus = conluded;
    nvramTimeOutms = kFanControlInterval;
  }
  
  timer->setTimeoutMS(nvramTimeOutms);
}

/*
 Clients will know if fans can be controlled
 */
void W836x::enableNVRAMFansControl()
{
  writeKeyToNVRAM(OSSymbol::withCStringNoCopy(kFanControlKey), OSData::withBytes(&fanControlsCount, 1));
  writeKeyToNVRAM(OSSymbol::withCStringNoCopy(kFanControlData), OSData::withBytes(&nvram_data, 44));
}

/*
 Disable IO mapping lock for certain chips only
 */
void W836x::disableIOSpaceLock()
{
  
  switch (model)
  {
    case NCT6791D:
    case NCT6792D:
    case NCT6793D:
    case NCT6795D:
    case NCT6796D:
    case NCT6797D:
    case NCT6798D:
    case NCT679BD: break;
    default:       return;
  }
  
  UInt8 val = listenPortByte(HARDWARE_REG_ENABLE);
  if (!(val & 0x01))
  {
    DebugLog("Activating device");
    outb(registerPort, HARDWARE_REG_ENABLE);
    outb(registerPort + 1, val | 0x01);
  }
  else
  {
    DebugLog("Device is already activated");
  }
  
  
  val = listenPortByte(MONITOR_IO_SPACE_LOCK);
  // if the i/o space lock is enabled
  if ((val & 0x10) > 0)
  {
    DebugLog("Disabling IO space lock");
    // disable the i/o space lock
    outb(registerPort, MONITOR_IO_SPACE_LOCK);
    outb(registerPort + 1, val & ~0x10);
  }
  else
  {
    DebugLog("IO space already unlocked");
  }
  logAddresses();
}

/*
 Dump registers in the IO, so registers can be consulted easily (e.g. with IORegistryExplorer.app)
 */
void W836x::logAddresses()
{
  if (dumplogged)  return;
  
  UInt16 NuvotonAddresses[] =
  {
    0x000, 0x010, 0x020, 0x030, 0x040, 0x050, 0x060, 0x070, 0x0F0,
    0x100, 0x110, 0x120, 0x130, 0x140, 0x150,
    0x200, 0x210, 0x220, 0x230, 0x240, 0x250, 0x260,
    0x300,        0x320, 0x330, 0x340,        0x360,
    0x400, 0x410, 0x420,        0x440, 0x450, 0x460, 0x480, 0x490, 0x4B0,
    0x4C0, 0x4F0,
    0x500,                             0x550, 0x560,
    0x600, 0x610 ,0x620, 0x630, 0x640, 0x650, 0x660, 0x670,
    0x700, 0x710, 0x720, 0x730,
    0x800,        0x820, 0x830, 0x840,
    0x900,        0x920, 0x930, 0x940,        0x960,
    0xA00, 0xA10, 0xA20, 0xA30, 0xA40, 0xA50, 0xA60, 0xA70,
    0xB00, 0xB10, 0xB20, 0xB30,        0xB50, 0xB60, 0xB70,
    0xC00, 0xC10, 0xC20, 0xC30,        0xC50, 0xC60, 0xC70,
    0xD00, 0xD10, 0xD20, 0xD30,        0xD50, 0xD60,
    0xE00, 0xE10, 0xE20, 0xE30,
    0xF00, 0xF10, 0xF20, 0xF30,
    0x8040, 0x80F0
  };
  
  size_t glen = 5455 + 1; // nuvoton max len for the dump len
  char str[glen];
  
  const char *header = "      00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F\n\n";
  
  snprintf(str, glen, "%s", header); // add the header
  size_t pos = 55;
  
  if (isNuvoton)
  {
    for (int i = 0; i <100; i++)
    {
      UInt16 addr = NuvotonAddresses[i];
      snprintf(str + pos, glen - pos, "%04x ", addr);
      pos += 5;
      for (int j = 0; j <= 0xF; j++)
      {
        UInt8 bank = (addr | j) >> 8;
        UInt8 reg = (addr | j) & 0xFF;
        snprintf(str + pos, glen - pos, " %02x", readByte(bank, reg));
        pos += 3;
      }
      snprintf(str + pos, glen - pos, "%s", "\n");
      pos +=1;
    }
  }
  else
  {
    for (int i = 0; i <= 0x7; i++)
    {
      snprintf(str + pos, glen - pos, "%02x    ", (i << 4));
      pos += 6;
      for (int j = 0; j <= 0xF; j++)
      {
        UInt8 bank = ((i << 4) | j) >> 8;
        UInt8 reg = ((i << 4) | j) & 0xFF;
        
        snprintf(str + pos, glen - pos, " %02x ", readByte(bank, reg));
        pos += 3;
      }
      snprintf(str + pos, glen - pos, "%s", "\n");
      pos +=1;
    }
    
    for (int k = 1; k <= 0xF; k++)
    {
      snprintf(str + pos, glen - pos, "Bank %02d", k);
      pos += 6;
      for (int j = 0; j <= 0xF; j++)
      {
        UInt8 bank = ((k << 4) | j) >> 8;
        UInt8 reg = ((k << 4) | j) & 0xFF;
        snprintf(str + pos, glen - pos, " %02x", readByte(bank, reg));
        pos += 3;
      }
      snprintf(str + pos, glen - pos, "%s", "\n");
      pos +=1;
    }
  }
  
  
  IOService::setProperty("addresses", OSString::withCString(str));
  
  snprintf(str, 5, " 0x%02x", registerPort);
  IOService::setProperty("register port", OSString::withCString(str));
  
  snprintf(str, 7, " 0x%4x", address);
  IOService::setProperty("address", OSString::withCString(str));
  dumplogged = true;
}

