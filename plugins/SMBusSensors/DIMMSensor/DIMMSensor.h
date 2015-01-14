//
// Slice 2015
//

#include "I2CCommon.h"
#include "FakeSMC.h"
#include "SuperIOFamily.h"
#include "utils.h"

#define drvid "[DIMM] "
#define super IOService
#define addSensor addKey

#ifdef DIMM_DEBUG
#define DbgPrint(arg...) IOLog(drvid arg)
#else
#define DbgPrint(arg...)
#endif
#define IOPrint(arg...) IOLog(drvid arg)

#define NUM_SENSORS	8
#define DIMM_CAP 0
#define DIMM_CFG 1
#define DIMM_TRM 5
#define DIMM_VID 6
#define DIMM_DID 7
#define DIMM_TEMP_NA		0x80


class TSOD: public IOService //FakeSMCPlugin
{
  OSDeclareDefaultStructors(TSOD)
private:
  IOService     *fakeSMC;
  I2CDevice     *i2cNub;
  UInt8         DIMMaddr;
  struct MList {
    UInt8	hreg;			/* MS-byte */
    UInt8	lreg;			/* LS-byte */
    struct {
      char    key[16];
      char    type[5];
      unsigned char size;
    } hwsensor;
    bool present;
    
    SInt64 value;
    bool obsoleted;
  } Measures[NUM_SENSORS];
  
  OSDictionary *sensors;
    
  void updateSensors();
  void readSensor(int);
  
  bool addSensor(const char* key, const char* type, unsigned int size, int index);
protected:
  virtual bool        init (OSDictionary* dictionary = NULL);
  virtual void        free (void);
  virtual IOService*  probe (IOService* provider, SInt32* score);
  virtual bool        start (IOService* provider);
  virtual void        stop (IOService* provider);
  
  virtual IOReturn    callPlatformFunction(const OSSymbol *functionName, bool waitForFunction,
                                         void *param1, void *param2, void *param3, void *param4 );
};
