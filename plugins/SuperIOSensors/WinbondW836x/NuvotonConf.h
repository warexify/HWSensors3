//
//  NuvotonConf.h
//  HWSensors
//
//  Created by vector sigma on 17/04/19.
//  Copyright © 2019 slice. All rights reserved.
//

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

#ifndef NuvotonConf_h
#define NuvotonConf_h

// IO space lock
static const UInt8 HARDWARE_REG_ENABLE   = 0x30;
static const UInt8 MONITOR_IO_SPACE_LOCK = 0x28;

// old temperature registers
static const UInt16 NUVOTON_TEMPERATURE[]           = { 0x150, 0x670, 0x27 };
static const UInt16 NUVOTON_NEW_TEMPERATURE1[]      = { 0x75, 0x77, 0x73, 0x79 };
static const UInt16 NUVOTON_NEW_TEMPERATURE2[]      = { 0x402, 0x401, 0x404, 0x405 };

static struct NCT610X_config {
  UInt16 VENDOR_ID_HIGH_REGISTER = 0x80FE;
  UInt16 VENDOR_ID_LOW_REGISTER = 0x00FE;
  
  UInt16 temperatureRegisters[4] = { 0x027, 0x018, 0x019, 0x01A };
  UInt16 temperatureSourceRegister[4] = { 0x621, 0x100, 0x200, 0x300 };
  UInt16 alternatetemperatureRegisters[4] = { NULL, 0x018, 0x019, 0x01A };
  
  UInt16 voltageRegisters[9] = { 0x300, 0x301, 0x302, 0x303, 0x304, 0x305, 0x307, 0x308, 0x309 };
  UInt16 voltageVBatRegister = 0x308;
  UInt16 vBatMonitorControlRegister = 0x0318;
  
  UInt16 FAN_PWM_OUT_REG[3] = { 0x04A, 0x04B, 0x04C };
  UInt16 FAN_PWM_COMMAND_REG[3] = { 0x119, 0x129, 0x139 };
  UInt16 FAN_CONTROL_MODE_REG[3] = { 0x113, 0x123, 0x133 };
  UInt16 fanRpmBaseRegister = 0x030;
  
  int fansCount = 3;
  int controlsCount = 3;
  int voltagesCount = 9;
} NCT610X_conf;

struct NCT6771F_config {
  UInt16 VENDOR_ID_HIGH_REGISTER = 0x804F;
  UInt16 VENDOR_ID_LOW_REGISTER = 0x004F;
  
  UInt16 temperatureRegisters[9] = { 0x027, 0x073, 0x075, 0x077, 0x150, 0x250, 0x62B, 0x62C, 0x62D };
  UInt16 temperatureSourceRegister[9] = { 0x621, 0x100, 0x200, 0x300, 0x622, 0x623, 0x624, 0x625, 0x626 };
  UInt16 alternatetemperatureRegisters[4] = { NULL, NULL, NULL, NULL };
  
  UInt16 voltageRegisters[9] = { 0x020, 0x021, 0x022, 0x023, 0x024, 0x025, 0x026, 0x550, 0x551 };
  UInt16 voltageVBatRegister = 0x551;
  UInt16 vBatMonitorControlRegister = 0x005D;
  
  UInt16 FAN_PWM_OUT_REG[4] = { 0x001, 0x003, 0x011, 0x013 };
  UInt16 FAN_PWM_COMMAND_REG[4] = { 0x109, 0x209, 0x309, 0x809 };
  UInt16 FAN_CONTROL_MODE_REG[4] = { 0x102, 0x202, 0x302, 0x802 };
  UInt16 fanRpmBaseRegister = 0x656;
  
  int fansCount = 4;
  int controlsCount = 4;
  int voltagesCount = 9;
} NCT6771F_conf;

struct NCT6776F_config {
  UInt16 VENDOR_ID_HIGH_REGISTER = 0x804F;
  UInt16 VENDOR_ID_LOW_REGISTER = 0x004F;
  
  UInt16 temperatureRegisters[9] = { 0x027, 0x073, 0x075, 0x077, 0x150, 0x250, 0x62B, 0x62C, 0x62D };
  UInt16 temperatureSourceRegister[9] = { 0x621, 0x100, 0x200, 0x300, 0x622, 0x623, 0x624, 0x625, 0x626 };
  UInt16 alternatetemperatureRegisters[4] = { NULL, NULL, NULL, NULL };
  
  UInt16 voltageRegisters[9] = { 0x020, 0x021, 0x022, 0x023, 0x024, 0x025, 0x026, 0x550, 0x551 };
  UInt16 voltageVBatRegister = 0x551;
  UInt16 vBatMonitorControlRegister = 0x005D;
  
  UInt16 FAN_PWM_OUT_REG[5] = { 0x001, 0x003, 0x011, 0x013, 0x015 };
  UInt16 FAN_PWM_COMMAND_REG[5] = { 0x109, 0x209, 0x309, 0x809, 0x909 };
  UInt16 FAN_CONTROL_MODE_REG[5] = { 0x102, 0x202, 0x302, 0x802, 0x902 };
  UInt16 fanRpmBaseRegister = 0x656;
  
  int fansCount = 5;
  int controlsCount = 5;
  int voltagesCount = 9;
} NCT6776F_conf;

struct NCT6779D_config {
  UInt16 VENDOR_ID_HIGH_REGISTER = 0x804F;
  UInt16 VENDOR_ID_LOW_REGISTER = 0x004F;
  
  UInt16 temperatureRegisters[7] = { 0x027, 0x073, 0x075, 0x077, 0x079, 0x07B, 0x150 };
  UInt16 temperatureSourceRegister[7] = { 0x621, 0x100, 0x200, 0x300, 0x800, 0x900, 0x622 };
  UInt16 alternatetemperatureRegisters[7] =  { NULL, 0x491, 0x490, 0x492, 0x493, 0x494, 0x495 };
  
  UInt16 voltageRegisters[15] = { 0x480, 0x481, 0x482, 0x483, 0x484, 0x485, 0x486, 0x487, 0x488,
    0x489, 0x48A, 0x48B, 0x48C, 0x48D, 0x48E };
  UInt16 voltageVBatRegister = 0x488;
  UInt16 vBatMonitorControlRegister = 0x005D;
  
  UInt16 FAN_PWM_OUT_REG[5] = { 0x001, 0x003, 0x011, 0x013, 0x015 };
  UInt16 FAN_PWM_COMMAND_REG[5] = { 0x109, 0x209, 0x309, 0x809, 0x909 };
  UInt16 FAN_CONTROL_MODE_REG[5] = { 0x102, 0x202, 0x302, 0x802, 0x902 };
  UInt16 fanRpmBaseRegister = 0x4C0;
  
  int fansCount = 5;
  int controlsCount = 5;
  int voltagesCount = 15;
} NCT6779D_conf;

static struct NCT6791D_config {
  UInt16 VENDOR_ID_HIGH_REGISTER = 0x804F;
  UInt16 VENDOR_ID_LOW_REGISTER = 0x004F;
  
  UInt16 temperatureRegisters[7] = { 0x027, 0x073, 0x075, 0x077, 0x079, 0x07B, 0x150 };
  UInt16 temperatureSourceRegister[7] = { 0x621, 0x100, 0x200, 0x300, 0x800, 0x900, 0x622 };
  UInt16 alternatetemperatureRegisters[7] =  { NULL, 0x491, 0x490, 0x492, 0x493, 0x494, 0x495 };
  
  UInt16 voltageRegisters[15] = { 0x480, 0x481, 0x482, 0x483, 0x484, 0x485, 0x486, 0x487, 0x488,
    0x489, 0x48A, 0x48B, 0x48C, 0x48D, 0x48E };
  UInt16 voltageVBatRegister = 0x488;
  UInt16 vBatMonitorControlRegister = 0x005D;
  
  UInt16 FAN_PWM_OUT_REG[6] = { 0x001, 0x003, 0x011, 0x013, 0x015, 0xA09 /*0x017*/ };
  UInt16 FAN_PWM_COMMAND_REG[6] = { 0x109, 0x209, 0x309, 0x809, 0x909, 0xA09 };
  UInt16 FAN_CONTROL_MODE_REG[6] = { 0x102, 0x202, 0x302, 0x802, 0x902, 0xA02 };
  UInt16 fanRpmBaseRegister = 0x4C0;
  
  int fansCount = 6;
  int controlsCount = 6;
  int voltagesCount = 15;
} NCT6791D_conf;


struct NCT6796D_config { // to be tested
  UInt16 VENDOR_ID_HIGH_REGISTER = 0x804F;
  UInt16 VENDOR_ID_LOW_REGISTER = 0x004F;
  
  UInt16 temperatureRegisters[7] = { 0x027, 0x150, 0x670, 0x672, 0x674, 0x676, 0x678 };
  UInt16 temperatureSourceRegister[7] = { 0x621, 0x622, 0xC26, 0xc27, 0xc28, 0xc29, 0xc2a };
  UInt16 alternatetemperatureRegisters[7] =  { NULL, 0x491, 0x490, 0x492, 0x493, 0x494, 0x495 };
  
  UInt16 voltageRegisters[15] = { 0x480, 0x481, 0x482, 0x483, 0x484, 0x485, 0x486, 0x487, 0x488,
    0x489, 0x48A, 0x48B, 0x48C, 0x48D, 0x48E };
  UInt16 voltageVBatRegister = 0x488;
  UInt16 vBatMonitorControlRegister = 0x005D;
  
  UInt16 FAN_PWM_OUT_REG[7] = { 0x001, 0x003, 0x011, 0x013, 0x015, 0xA09, 0xB09 };
  UInt16 FAN_PWM_COMMAND_REG[7] = { 0x109, 0x209, 0x309, 0x809, 0x909, 0xA09, 0xB09 };
  UInt16 FAN_CONTROL_MODE_REG[7] = { 0x102, 0x202, 0x302, 0x802, 0x902, 0xA02, 0xB02 };
  UInt16 fanRpmBaseRegister = 0x4C0;
  
  int fansCount = 7;
  int controlsCount = 6;
  int voltagesCount = 15;
} NCT6796D_conf;


#endif /* NuvotonConf_h */
