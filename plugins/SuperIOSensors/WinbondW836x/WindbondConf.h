//
//  WindbondConf.h
//  HWSensors
//
//  Created by vector sigma on 20/04/2019.
//  Copyright © 2019 slice. All rights reserved.
//

#ifndef WindbondConf_h
#define WindbondConf_h

static const UInt8  WINBOND_VENDOR_ID_REGISTER  = 0x4F;
static const UInt16 WINBOND_VENDOR_ID           = 0x5CA3;
static const UInt8  WINBOND_HIGH_BYTE           = 0x80;

//private string[] TEMPERATURE_NAME =
//new string[] {"CPU", "Ambient", "System", "Memory"};
static const UInt16 WINBOND_TEMPERATURE[]       = { 0x150, 0x250, 0x27 };

static const UInt8 WINBOND_TEMPERATURE_SOURCE_SELECT_REG  = 0x49;


// Voltages                                    VCORE   AVSB   3VCC   AVCC  +12V1  -12V2  -5VIN3  3VSB   VBAT
static const UInt16 WINBOND_VOLTAGE_REG[]          = { 0x20,  0x21,  0x23,  0x22,  0x24,  0x25,  0x26,  0x550, 0x551 };
static const float  WINBOND_VOLTAGE_SCALE[]        = { 8,     8,     16,    16,    8,     8,     8,     16,    16 };
static const UInt16 WINBOND_VOLTAGE_VBAT_REG       = 0x0551;
//static const UInt16 NUVOTON_VOLTAGE_REG[]          = { 0x480, 0x482, 0x483, 0x484, 0x485, 0x481, 0x486, 0x487, 0x488 };


static const UInt8 WINBOND_TACHOMETER[]      = { 0x28, 0x29, 0x2A, 0x3F, 0x53 };
static const UInt8 WINBOND_TACHOMETER_BANK[] = { 0, 0, 0, 0, 5 };

//                                        SYSFAN, CPUFAN, AUXFAN
//static const UInt16 NUVOTON_TACHOMETER[]      = { 0x4C0,  0x4C2,  0x4C4,  0x4C6, 0x4C8, 0x4CA};

static const UInt8 WINBOND_TACHOMETER_DIV0[]      = { 0x47, 0x47, 0x4B, 0x59, 0x59 };
static const UInt8 WINBOND_TACHOMETER_DIV0_BIT[]  = { 4,    6,    6,    0,    2 };
static const UInt8 WINBOND_TACHOMETER_DIV1[]      = { 0x47, 0x47, 0x4B, 0x59, 0x59 };
static const UInt8 WINBOND_TACHOMETER_DIV1_BIT[]  = { 5,    7,    7,    1,    3 };
static const UInt8 WINBOND_TACHOMETER_DIV2[]      = { 0x5D, 0x5D, 0x5D, 0x4C, 0x59 };
static const UInt8 WINBOND_TACHOMETER_DIV2_BIT[]  = { 5,    6,    7,    7,    7 };

static const UInt8 WINBOND_TACHOMETER_DIVISOR[]   = { 0x47, 0x4B, 0x4C, 0x59, 0x5D };
static const UInt8 WINBOND_TACHOMETER_DIVISOR0[]  = { 36, 38, 30, 8, 10 };
static const UInt8 WINBOND_TACHOMETER_DIVISOR1[]  = { 37, 39, 31, 9, 11 };
static const UInt8 WINBOND_TACHOMETER_DIVISOR2[]  = { 5, 6, 7, 23, 15 };

// Fan Control https://github.com/torvalds/linux/blob/master/drivers/hwmon/w83627ehf.c
static const UInt8 W83627EHF_REG_PWM_ENABLE[] = {
  0x04,      /* SYS FAN0 output mode and PWM mode */
  0x04,      /* CPU FAN0 output mode and PWM mode */
  0x12,      /* AUX FAN mode */
  0x62,      /* CPU FAN1 mode */
};

static const UInt8 W83627EHF_PWM_ENABLE_SHIFT[]    = { 2, 4, 1, 4 };
static const UInt8 W83627EHF_PWM_MODE_SHIFT[]      = { 0, 1, 0, 6 };
static const UInt8 W83627EHF_REG_PWM[]             = { 0x01, 0x03, 0x11, 0x61 };
#endif /* WindbondConf_h */
