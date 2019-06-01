/*
 *  SMIMonitor.h
 *  HWSensors
 *
 *  Created by Slice 2014.
 *
 */

#include <IOKit/IOService.h>
#include "IOKit/acpi/IOACPIPlatformDevice.h"
#include <IOKit/IOTimerEventSource.h>

#define I8K_SMM_FN_STATUS       0x0025
#define I8K_SMM_POWER_STATUS    0x0069   /* 0x85*/
#define I8K_SMM_SET_FAN         0x01a3
#define I8K_SMM_GET_FAN         0x00a3
#define I8K_SMM_GET_SPEED       0x02a3
#define I8K_SMM_GET_TEMP        0x10a3
#define I8K_SMM_GET_DELL_SIG1   0xfea3
#define I8K_SMM_GET_DELL_SIG2   0xffa3
#define I8K_SMM_BIOS_VERSION    0x00a6

#define I8K_FAN_MULT            30
#define I8K_MAX_TEMP            127

#define I8K_FAN_PRIMARY         0
#define I8K_FAN_SECONDARY       1
#define I8K_FAN_OFF             0
#define I8K_FAN_LOW             1
#define I8K_FAN_HIGH            2
#define I8K_FAN_MAX             I8K_FAN_HIGH

#define I8K_POWER_AC            0x05
#define I8K_POWER_BATTERY       0x01
#define I8K_AC                  1
#define I8K_BATTERY             0

/*  battery status
 SX30 (0x02)
 SX30 (One)
   battery info
 SX30 (One)
 SX30 (One)
    Battery Trip Point
 SX30 (0x03)
 SX30 (One)

 
 LID
 Store (SMI (0x84, Zero), Local0)
 
 Thermal
 Store (GINF (0x04), Local0)
 
 Power Source
 Store (SMI (0x85, Zero), Local0)
 */


typedef struct {
  unsigned int eax;
  unsigned int ebx __attribute__ ((packed));
  unsigned int ecx __attribute__ ((packed));
  unsigned int edx __attribute__ ((packed));
  unsigned int esi __attribute__ ((packed));
  unsigned int edi __attribute__ ((packed));
} SMMRegisters;

#define INIT_REGS               SMMRegisters regs = { 0, 0, 0, 0, 0, 0 }

class SMIMonitor : public IOService
{
  OSDeclareDefaultStructors(SMIMonitor)
private:
	IOService*				fakeSMC;
	IOACPIPlatformDevice *	acpiDevice;
	OSDictionary*			sensors;
	
	bool				addSensor(const char* key, const char* type, unsigned int size);
	bool				addTachometer(int index, const char* caption);
  
 // int i8k_smm(SMMRegisters *regs);
  int i8k_get_bios_version(void);
  bool i8k_get_dell_sig_aux(int fn);
  bool i8k_get_dell_signature(void);
  int i8k_get_cpu_temp(void);
  int i8k_get_power_status(void);
  int i8k_get_fan_speed(int fan);
//  int i8k_get_fan0_speed(void);
//  int i8k_get_fan1_speed(void);
  int i8k_get_fan_status(int fan);
//  int i8k_get_fan0_status(void);
//  int i8k_get_fan1_status(void);
  
	
public:
	virtual IOService*	probe(IOService *provider, SInt32 *score);
  virtual bool		start(IOService *provider);
	virtual bool		init(OSDictionary *properties=0);
	virtual void		free(void);
	virtual void		stop(IOService *provider);
	
	virtual IOReturn	callPlatformFunction(const OSSymbol *functionName,
                                         bool waitForFunction,
                                         void *param1,
                                         void *param2,
                                         void *param3,
                                         void *param4);
};
