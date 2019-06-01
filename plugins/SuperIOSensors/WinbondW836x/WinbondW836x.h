/*
 *  W836x.h
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

#include "../SuperIOFamily/SuperIOFamily.h"
#include <IOKit/IORegistryEntry.h>
#include <IOKit/IOPlatformExpert.h>
#include <IOKit/IODeviceTreeSupport.h>
#include <IOKit/IOKitKeys.h>



// Winbond/Nuvoton Hardware Monitor registers
static const UInt8 HARDWARE_MONITOR_LDN     = 0x0B;
static const UInt8 ADDRESS_REGISTER_OFFSET	= 0x05;
static const UInt8 DATA_REGISTER_OFFSET		  = 0x06;
static const UInt8 BANK_SELECT_REGISTER		  = 0x4E;

static const int minFanRPM = (int)(1.35e6 / 0xFFFF); //min value RPM value with 16-bit fan counter //default value
static const int maxFanRPM = 7000;

class W836x;

class W836xSensor : public SuperIOSensor {
    OSDeclareDefaultStructors(W836xSensor)
    
public:
    static SuperIOSensor *withOwner(SuperIOMonitor *aOwner,
                                    const char* aKey,
                                    const char* aType,
                                    unsigned char aSize,
                                    SuperIOSensorGroup aGroup,
                                    unsigned long aIndex,
                                    long aRi = 0,
                                    long aRf = 1,
                                    long aVf = 0);
    
    virtual long	getValue();
    virtual void  setValue(UInt16 value);
};

enum FanCalibrationStatus {
  doNothing       = 0,
  initiate        = 1,
  minCalibration  = 2,
  maxCalibration  = 3,
  conluded        = 4
};

static const int maxFanAllowed = 7;

class W836x : public SuperIOMonitor {
    OSDeclareDefaultStructors(W836x)
    
public:
	virtual bool		init(OSDictionary *properties=0);
	virtual IOService*	probe(IOService *provider, SInt32 *score);
  virtual bool		start(IOService *provider);
	virtual void		stop(IOService *provider);
	virtual void		free(void);

private:
  UInt8           nvram_data[44];
  IOLock          * lock = NULL;
  bool            safeToWrite = false;
  IOTimerEventSource * timer = NULL;
  IOWorkLoop      * workLoop = NULL;
  char            vendor[40];
  char            product[40];
  bool            isNuvoton = false;
  
  int             voltagesCount = 9;
  
  UInt16        * voltageRegisters;
  UInt16          voltageVBatRegister;
  UInt16          vBatMonitorControlRegister;
  
  UInt16        * temperatureRegisters;
  
  UInt32          nvramTimeOutms = kFanControlInitialInterval;
  
  FanCalibrationStatus fanCalibrationStatus = doNothing;
	UInt8           fanLimit;
	UInt16          fanValue[maxFanAllowed];
	bool            fanValueObsolete[maxFanAllowed];
  
  UInt16          fanRpmBaseRegister;
  UInt16        * fanControlMode = NULL;
  UInt16        * fanControlPWMCommand = NULL;
  UInt16        * fanControlPWMOut = NULL;
  int             fanMaxCount = 3;
  UInt8           fanControlsCount = 0;
  
  bool            restoreDefaultFanControlRequired[maxFanAllowed];
  UInt8           initialFanControlMode[maxFanAllowed];
  UInt8           initialFanPwmCommand[maxFanAllowed];
	
	void            writeByte(UInt8 bank, UInt8 reg, UInt8 value);
	UInt8           readByte(UInt8 bank, UInt8 reg);
  UInt64          setBit(UInt64 target, UInt16 bit, UInt32 value);
	
	virtual bool		probePort();
    //  virtual bool			startPlugin();
	virtual void		enter();
  void            disableIOSpaceLock();
	virtual void		exit();
  
  void            logAddresses();
  bool            dumplogged = false;
    
	virtual long		readTemperature(unsigned long index);
  long            readNuvotonTemperature(UInt16 temperatureRegister);
	virtual long		readVoltage(unsigned long index);
  
	void            updateTachometers();
  UInt8           readTachometerControlPercent(unsigned long index);
  virtual long		readTachometerControl(unsigned long index);
  virtual long		readTachometer(unsigned long index);
  virtual long		readTachometerMin(unsigned long index);
  virtual long		readTachometerMax(unsigned long index);
  virtual long		readTachometerTarget(unsigned long index);
  void            saveDefaultFanControl(unsigned long index);
  void            restoreDefaultFanControl(unsigned long index);

  void            readNVRAMFansControl();
  void            enableNVRAMFansControl();
  void            writeKeyToNVRAM(const OSSymbol *key, OSData *data);
  void            deleteNVRAMKey(const OSSymbol *key);
	
	virtual const char*	getModelName();
	
public:
  SuperIOSensor * addSensor(const char* key,
                            const char* type,
                            unsigned int size,
                            SuperIOSensorGroup group,
                            unsigned long index,
                            long aRi = 0,
                            long aRf = 1,
                            long aVf = 0);
  
  virtual IOReturn callPlatformFunction(const OSSymbol *functionName,
                                        bool waitForFunction,
                                        void *param1,
                                        void *param2,
                                        void *param3,
                                        void *param4);
  
  void setControl(unsigned long index, UInt16 rpm);
  virtual IOReturn  setPowerState(unsigned long powerStateOrdinal, IOService *whatDevice);
};
