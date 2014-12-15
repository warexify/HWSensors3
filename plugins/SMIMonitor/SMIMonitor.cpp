/*
 *  SMIMonitor.cpp
 *  HWSensors
 *
 *  Copyright 2014 Slice. All rights reserved.
 *
 */

#include "SMIMonitor.h"
#include "FakeSMC.h"
#include "utils.h"

#define Debug FALSE

#define LogPrefix "SMIMonitor: "
#define DebugLog(string, args...)	do { if (Debug) { IOLog (LogPrefix "[Debug] " string "\n", ## args); } } while(0)
#define WarningLog(string, args...) do { IOLog (LogPrefix "[Warning] " string "\n", ## args); } while(0)
#define InfoLog(string, args...)	do { IOLog (LogPrefix string "\n", ## args); } while(0)

#define super IOService
OSDefineMetaClassAndStructors(SMIMonitor, IOService)

bool SMIMonitor::addSensor(const char* key, const char* type, unsigned char size)
{
  if (kIOReturnSuccess != fakeSMC->callPlatformFunction(kFakeSMCAddKeyHandler, false, (void *)key, (void *)type, (void *)size, (void *)this)) {
    WarningLog("Can't add key %s to fake SMC device, kext will not load", key);
    return false;
  }
	return true;
}

// for example addTachometer(0, "System Fan");
bool SMIMonitor::addTachometer(int index, const char* id)
{
	UInt8 length = 0;
	void * data = 0;
	
	if (kIOReturnSuccess == fakeSMC->callPlatformFunction(kFakeSMCGetKeyValue, true, (void *)KEY_FAN_NUMBER, (void *)&length, (void *)&data, 0)) {
		char key[5];
		length = 0;
		
		bcopy(data, &length, 1);
		
		snprintf(key, 5, KEY_FORMAT_FAN_SPEED, length);
		
		if (addSensor(key, TYPE_FPE2, 2)) {
			if (id) {
        FanTypeDescStruct fds;
				snprintf(key, 5, KEY_FORMAT_FAN_ID, length);
        fds.type = FAN_PWM_TACH;
        fds.ui8Zone = 1;
        fds.location = LEFT_LOWER_FRONT;
        strncpy(fds.strFunction, id, DIAG_FUNCTION_STR_LEN);
        
        if (kIOReturnSuccess != fakeSMC->callPlatformFunction(kFakeSMCAddKeyValue, false, (void *)key, (void *)TYPE_FDESC, (void *)((UInt64)sizeof(fds)), (void *)&fds)) {
          
					WarningLog("error adding tachometer id value");
        }
			}
			
			length++;
			
			if (kIOReturnSuccess != fakeSMC->callPlatformFunction(kFakeSMCSetKeyValue, true, (void *)KEY_FAN_NUMBER, (void *)1, (void *)&length, 0))
				WarningLog("error updating FNum value");
			
			return true;
		}
	}
	else WarningLog("error reading FNum value");
	
	return false;
}
/*
 SMIC=0xB2
 SMIA=0x86
Mutex (SMIX, 0x01)
Method (SMI, 2, NotSerialized)
{
  Acquire (SMIX, 0xFFFF)
  Store (Arg1, \_SB.SMIA)
  Store (Arg0, \_SB.SMIC)
  Store (\_SB.SMIC, Local0)
  While (LNotEqual (Local0, Zero))
  {
    Store (\_SB.SMIC, Local0)
  }
  
  Store (\_SB.SMIA, Local1)
  Release (SMIX)
  Return (Local1)
}
*/

inline int i8k_smm(SMMRegisters *regs)
{
  
  int rc;
  int eax = regs->eax;
  
  asm("pushl %%eax\n\t" \
      "movl 0(%%eax),%%edx\n\t" \
      "push %%edx\n\t" \
      "movl 4(%%eax),%%ebx\n\t" \
      "movl 8(%%eax),%%ecx\n\t" \
      "movl 12(%%eax),%%edx\n\t" \
      "movl 16(%%eax),%%esi\n\t" \
      "movl 20(%%eax),%%edi\n\t" \
      "popl %%eax\n\t" \
      "out %%al,$0xb2\n\t" \
      "out %%al,$0x84\n\t" \
      "xchgl %%eax,(%%esp)\n\t" \
      "movl %%ebx,4(%%eax)\n\t" \
      "movl %%ecx,8(%%eax)\n\t" \
      "movl %%edx,12(%%eax)\n\t" \
      "movl %%esi,16(%%eax)\n\t" \
      "movl %%edi,20(%%eax)\n\t" \
      "popl %%edx\n\t" \
      "movl %%edx,0(%%eax)\n\t" \
      "lahf\n\t" \
      "shrl $8,%%eax\n\t" \
      "andl $1,%%eax\n" \
      : "=a" (rc)
      : "a" (regs)
      : "%ebx", "%ecx", "%edx", "%esi", "%edi", "memory"
      );
  //example to do
  //outb((UInt16)(address), WINBOND_BANK_SELECT_REGISTER);
  
  if ((rc != 0) || ((regs->eax & 0xffff) == 0xffff) || (regs->eax == eax)) {
    return -1;
  }

  return 0;
}

int SMIMonitor::i8k_get_bios_version(void)
{
  INIT_REGS;
  int rc;
  
  regs.eax = I8K_SMM_BIOS_VERSION;
  if ((rc=i8k_smm(&regs)) < 0) {
    return rc;
  }
  
  return regs.eax;
}

/*
 * Read the CPU temperature in Celcius.
 */
int SMIMonitor::i8k_get_cpu_temp(void)
{
  INIT_REGS;
  int rc;
  int temp;
  
  regs.eax = I8K_SMM_GET_TEMP;
  if ((rc=i8k_smm(&regs)) < 0) {
    return rc;
	}
	
  temp = regs.eax & 0xff;
  return temp;
}

bool SMIMonitor::i8k_get_dell_sig_aux(int fn)
{
  INIT_REGS;
//  int rc;
  
  regs.eax = fn;
  if (i8k_smm(&regs) < 0) {
    return false;
  }
  
  return ((regs.eax == 1145651527) && (regs.edx == 1145392204));
}

bool SMIMonitor::i8k_get_dell_signature(void)
{
  
  return (i8k_get_dell_sig_aux(I8K_SMM_GET_DELL_SIG1) &&
          i8k_get_dell_sig_aux(I8K_SMM_GET_DELL_SIG2));
}


/*
 * Read the power status.
 */
int SMIMonitor::i8k_get_power_status(void)
{
  INIT_REGS;
  int rc;
  
  regs.eax = I8K_SMM_POWER_STATUS;
  if ((rc=i8k_smm(&regs)) < 0) {
    return rc;
  }
  
  return regs.eax & 0xff; // 0 = No Batt, 3 = No AC, 1 = Charging, 5 = Full.
}

/*
 * Read the fan speed in RPM.
 */
int SMIMonitor::i8k_get_fan_speed(int fan)
{
  INIT_REGS;
  int rc;
  
  regs.eax = I8K_SMM_GET_SPEED;
  regs.ebx = fan & 0xff;
  if ((rc=i8k_smm(&regs)) < 0) {
    return rc;
  }
  
  return (regs.eax & 0xffff) * I8K_FAN_MULT;
}
/*
int SMIMonitor::i8k_get_fan0_speed(void)
{
  return i8k_get_fan_speed(I8K_FAN_PRIMARY);
}

int SMIMonitor::i8k_get_fan1_speed(void)
{
  return i8k_get_fan_speed(I8K_FAN_SECONDARY);
}
*/
/*
 * Read the fan status.
 */
int SMIMonitor::i8k_get_fan_status(int fan)
{
  INIT_REGS;
  int rc;
  
  regs.eax = I8K_SMM_GET_FAN;
  regs.ebx = fan & 0xff;
  if ((rc=i8k_smm(&regs)) < 0) {
    return rc;
  }
  
  return (regs.eax & 0xff);
}
/*
int SMIMonitor::i8k_get_fan0_status(void)
{
  return i8k_get_fan_status(I8K_FAN_PRIMARY);
}

int SMIMonitor::i8k_get_fan1_status(void)
{
  return i8k_get_fan_status(I8K_FAN_SECONDARY);
}
*/


IOService* SMIMonitor::probe(IOService *provider, SInt32 *score)
{
	if (super::probe(provider, score) != this) return 0;
  
  if (!i8k_get_dell_signature()) {
    WarningLog("Unable to get Dell SMM signature!");
    return NULL;
  }

  InfoLog("Based on I8kfan project adopted to HWSensors by Slice 2014");
  InfoLog("Dell BIOS version=%x", i8k_get_bios_version());
  	
	return this;
}

bool SMIMonitor::start(IOService * provider)
{
	if (!provider || !super::start(provider)) return false;
	
	if (!(fakeSMC = waitForService(serviceMatching(kFakeSMCDeviceService)))) {
		WarningLog("Can't locate fake SMC device, kext will not load");
		return false;
	}
	
//	acpiDevice = (IOACPIPlatformDevice *)provider;
	
	char key[5];
	
	//Here is Fan in ACPI
	OSArray* fanNames = OSDynamicCast(OSArray, getProperty("FanNames"));
	
	for (int i=0; i<3; i++)
	{
		snprintf(key, 5, "FAN%X", i);
		
		OSString* name = NULL;
			
		if (fanNames )
			name = OSDynamicCast(OSString, fanNames->getObject(i));
			
      if (!addTachometer(i, name ? name->getCStringNoCopy() : 0)) {
			WarningLog("Can't add tachometer sensor, key %s", key);
      }
	}

    addSensor(KEY_CPU_PROXIMITY_TEMPERATURE, TYPE_SP78, 2);  //TC0P
	registerService(0);
  
	return true;
}


bool SMIMonitor::init(OSDictionary *properties)
{
  if (!super::init(properties))
		return false;
	
	if (!(sensors = OSDictionary::withCapacity(0)))
		return false;
	
	return true;
}

void SMIMonitor::stop (IOService* provider)
{
	sensors->flushCollection();
  if (kIOReturnSuccess != fakeSMC->callPlatformFunction(kFakeSMCRemoveKeyHandler, true, this, NULL, NULL, NULL)) {
    WarningLog("Can't remove key handler");
    IOSleep(500);
  }
	
	super::stop(provider);
}

void SMIMonitor::free ()
{
	sensors->release();
	
	super::free();
}

#define MEGA10 10000000ull
IOReturn SMIMonitor::callPlatformFunction(const OSSymbol *functionName, bool waitForFunction, void *param1, void *param2, void *param3, void *param4 )
{
	const char* name = (const char*)param1;
	void * data = param2;
  //	UInt64 size = (UInt64)param3;
	OSString* key;
#if __LP64__
	UInt64 value;
#else
	UInt32 value;
#endif
	UInt16 val;

	if (functionName->isEqualTo(kFakeSMCSetValueCallback)) {
		if (name && data) {
      key = OSDynamicCast(OSString, sensors->getObject(name));
			if (key) {
				InfoLog("Writing key=%s by method=%s value=%x", name, key->getCStringNoCopy(), *(UInt16*)data);
				OSObject * params[1];
				if (key->getChar(0) == 'F') {
					val = decode_fpe2(*(UInt16*)data);
				} else {
					val = *(UInt16*)data;
				}
				params[0] = OSDynamicCast(OSObject, OSNumber::withNumber((unsigned long long)val, 32));
				return kIOReturnBadArgument; //acpiDevice->evaluateInteger(key->getCStringNoCopy(), &value, params, 1);
				
        /*
         virtual IOReturn evaluateInteger( const OSSymbol * objectName,
         UInt32 *         resultInt32,
         OSObject *       params[]   = 0,
         IOItemCount      paramCount = 0,
         IOOptionBits     options    = 0 );
         flags_num = OSNumber::withNumber((unsigned long long)flags, 32);
        */
				
			}
			return kIOReturnBadArgument;
		}
		return kIOReturnBadArgument;
		
	}
  
//#define KEY_FORMAT_FAN_ID                       "F%XID"
//#define KEY_FORMAT_FAN_SPEED                    "F%XAc"
//#define KEY_CPU_PROXIMITY_TEMPERATURE           "TC0P"

	if (functionName->isEqualTo(kFakeSMCGetValueCallback)) {
		
		if (name && data) {
      key = OSDynamicCast(OSString, sensors->getObject(name));
			if (key) {        
					val = 0;
					
					if (key->getChar(0) == 'F') {
						if ((key->getChar(2) == 'A') && (key->getChar(3) == 'c')) {
              int fan = (int)(key->getChar(1) - '0');
              value = i8k_get_fan_speed(fan);
							val = encode_fpe2(value);
						}
					} else if (key->getChar(0) == 'T') {
            val = i8k_get_cpu_temp();
          }
          
          bcopy(&val, data, 2);
          return kIOReturnSuccess;
			}
			
			return kIOReturnBadArgument;
		}
		
		//DebugLog("bad argument key name or data");
		
		return kIOReturnBadArgument;
	}
	
	return super::callPlatformFunction(functionName, waitForFunction, param1, param2, param3, param4);
}
