#include "I2CCommon.h"
#include "FakeSMC.h"
#include "SuperIOFamily.h"
#include "utils.h"
#define ADT7470_ADDRS {0x2c,0x2d,0x2e}

#define drvid "[AnalogDevices] "
#define super IOService 
#define addSensor addKey

#ifdef ADT_DEBUG
#define DbgPrint(arg...) IOLog(drvid arg)
#else
#define DbgPrint(arg...) 
#endif
#define IOPrint(arg...) IOLog(drvid arg)

#define ADT7470_DID_REG 0x3d
#define ADT7470_VID_REG 0x3e
#define ADT7470_PID_REG 0x3f
#define ADT7470_VID     0x41
#define ADT7470_PID     0x70


#define NUM_SENSORS	8
#define NUM_PWM     3

#define ADT7470_TEMP1L		0x10
#define ADT7470_TEMP2L		0x15
#define ADT7470_TEMP3L		0x16
#define ADT7470_TEMP4L		0x17

#define ADT7470_TEMP1H		0x25
#define ADT7470_TEMP2H		0x26
#define ADT7470_TEMP3H		0x27
#define ADT7470_TEMP4H		0x33
#define ADT7470_TEMP_NA		0x80
#define ADT7470_TACH1H		0x29
#define ADT7470_TACH1L		0x28
#define ADT7470_TACH2H		0x2b
#define ADT7470_TACH2L		0x2a
#define ADT7470_TACH3H		0x2d
#define ADT7470_TACH3L		0x2c
#define ADT7470_TACH4H		0x2f
#define ADT7470_TACH4L		0x2e

#define ADT7470_FANCM(x)    (x >> 5)
#define ADT7470_ALTBG(x)    ((x >> 3) & 0x01)
#define ADT7470_ALTBS(x)    (x |= (1 << 3))
#define ADT7470_ALTBC(x)    (x &= ~(1 << 3))
#define ADT7470_PWM1R       { 0x5c, 0x30 }
#define ADT7470_PWM2R       { 0x5d, 0x31 }
#define ADT7470_PWM3R       { 0x5e, 0x32 }
#define ADT7470_PWM1B       5
#define ADT7470_PWM2B       6
#define ADT7470_PWM3B       7

#define ADT7470_V25       0x20
#define ADT7470_VCCP      0x21
#define ADT7470_VCC       0x22
#define ADT7470_V5        0x23
#define ADT7470_V12       0x24


//FakeSMCPlugin
class Analog: public IOService {
    OSDeclareDefaultStructors(Analog)
private:
  IOService*				fakeSMC;
    I2CDevice *i2cNub;
    UInt8 ADT7470_addr;
    struct MList {
        UInt8	hreg;			/* MS-byte */
        UInt8	lreg;			/* LS-byte */
        struct {
            char	key[16];
            char    type[5];
            unsigned char size;
            char pwm;
        } hwsensor;
        char fan;
        
        SInt64 value;
        bool obsoleted;
    } Measures[NUM_SENSORS];
  
    struct PList {
        UInt8 reg[2];
        UInt8 value;
        SInt8 duty;
    } Pwm[NUM_PWM];
  
    struct {
        UInt16 pwm_mode;
        char start_fan;
        char num_fan;
        char fan_offset;
    } config;
    
    OSDictionary *	sensors;
    
    
    void updateSensors();
    void readSensor(int);
    /* Fan control */
    void   GetConf();
    void   SetPwmMode(UInt16);
    void   SetPwmDuty(char, UInt16);
    /* */
    
    bool addKey(const char* key, const char* type, unsigned int size, int index);
    void addTachometer(struct MList *, int);
protected:
    virtual bool    init (OSDictionary* dictionary = NULL);
    virtual void    free (void);
    virtual IOService*      probe (IOService* provider, SInt32* score);
    virtual bool    start (IOService* provider);
    virtual void    stop (IOService* provider);
    
    virtual IOReturn	callPlatformFunction(const OSSymbol *functionName,
                                           bool waitForFunction,
                                           void *param1,
                                           void *param2,
                                           void *param3,
                                           void *param4);
};
