#include "I2CCommon.h"
#include "FakeSMC.h"
//#include "FakeSMCPlugin.h"
//#include "FakeSMCUtils.h"
//#include "SuperIOMonitor.h" /* vendorID() */
#include "SuperIOFamily.h"
#include "utils.h"
//#define ASC_DEBUG 1
#define ASC7621_ADDRS {0x2c,0x2d,0x2e}

#define drvid "[Andigilog] "
#define super IOService /*FakeSMCPlugin */
#define addSensor addKey

#ifdef ASC_DEBUG
#define DbgPrint(arg...) IOLog(drvid arg)
#else
#define DbgPrint(arg...) ;
#endif
#define IOPrint(arg...) IOLog(drvid arg)

#define ADT7470_DID_REG 0x3d
#define ASC7621_VID_REG 0x3e
#define ASC7621_PID_REG 0x3f
#define ASC7621_VID     0x61
#define ASC7621_PID     0x6c
#define ASC7621A_PID    0x6d
#define EMC6D103_PID    0x68
#define EMC6D103_VID    0x5c
#define ADT7490_VID     0x41
#define ADT7490_PID     0x6e


#define NUM_SENSORS	8
#define NUM_PWM     3

#define ASC7621_TEMP1H		0x25
#define ASC7621_TEMP1L		0x10
#define ASC7621_TEMP2H		0x26
#define ASC7621_TEMP2L		0x15
#define ASC7621_TEMP3H		0x27
#define ASC7621_TEMP3L		0x16
#define ASC7621_TEMP4H		0x33
#define ASC7621_TEMP4L		0x17
#define ASC7621_TEMP_NA		0x80
#define ASC7621_TACH1H		0x29
#define ASC7621_TACH1L		0x28
#define ASC7621_TACH2H		0x2b
#define ASC7621_TACH2L		0x2a
#define ASC7621_TACH3H		0x2d
#define ASC7621_TACH3L		0x2c
#define ASC7621_TACH4H		0x2f
#define ASC7621_TACH4L		0x2e

#define ASC7621_FANCM(x)    (x >> 5)
#define ASC7621_ALTBG(x)    ((x >> 3) & 0x01)
#define ASC7621_ALTBS(x)    (x |= (1 << 3))
#define ASC7621_ALTBC(x)    (x &= ~(1 << 3))
#define ASC7621_PWM1R       { 0x5c, 0x30 }
#define ASC7621_PWM2R       { 0x5d, 0x31 }
#define ASC7621_PWM3R       { 0x5e, 0x32 }
#define ASC7621_PWM1B       5
#define ASC7621_PWM2B       6
#define ASC7621_PWM3B       7

#define ADT7490_V25       0x20
#define ADT7490_VCCP      0x21
#define ADT7490_VCC       0x22
#define ADT7490_V5        0x23
#define ADT7490_V12       0x24
//limits
#define ADT7490_V25_L     0x44
#define ADT7490_V25_H     0x45
#define ADT7490_VCCP_L    0x46
#define ADT7490_VCCP_H    0x47
#define ADT7490_VCC_L     0x48
#define ADT7490_VCC_H     0x49
#define ADT7490_V5_L      0x4A
#define ADT7490_V5_H      0x4B
#define ADT7490_V12_L     0x4C
#define ADT7490_V12_H     0x4D



class Andigilog: public IOService //FakeSMCPlugin
{
    OSDeclareDefaultStructors(Andigilog)
private:
  IOService*				fakeSMC;
    I2CDevice *i2cNub;
    UInt8 Asc7621_addr;
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
    
    bool addKey(const char* key, const char* type, unsigned char size, int index);
    void addTachometer(struct MList *, int);
protected:
    virtual bool    init (OSDictionary* dictionary = NULL);
    virtual void    free (void);
    virtual IOService*      probe (IOService* provider, SInt32* score);
    virtual bool    start (IOService* provider);
    virtual void    stop (IOService* provider);
    
    virtual IOReturn	callPlatformFunction(const OSSymbol *functionName, bool waitForFunction,
                                             void *param1, void *param2, void *param3, void *param4 );
};