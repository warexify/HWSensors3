//
//  globals.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 05/03/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

let kTestVersion           = "rc4" // or "" for final release

let kRunAtLoginWasSet       = "runAtLoginWasSet"
let kHideVerticalScroller   = "hideVerticalScroller"
let kAppleInterfaceStyle    = "AppleInterfaceStyle"
let kDark                   = "Dark"
let kPopoverHeight          = "popoverHeight"
let kPopoverWidth           = "popoverWidth"
let kSensorsTimeInterval    = "SensorsTimeInterval"
let kUseMemoryPercentage    = "useMemoryPercentage"
let kExpandCPUTemperature   = "expandCPUTemperature"
let kExpandVoltages         = "expandVoltages"
let kExpandCPUFrequencies   = "expandCPUFrequencies"
let kExpandAll              = "expandAll"
let kDontShowEmpty          = "dontshowEmpty"

let gAppearance = (UserDefaults.standard.string(forKey: kAppleInterfaceStyle) == kDark ||
    UserDefaults.standard.bool(forKey: kDark)) ?
        NSAppearance.Name.vibrantDark :
    NSAppearance.Name.vibrantLight

let gHideVerticalScroller : Bool = UserDefaults.standard.bool(forKey: kHideVerticalScroller)

let gPopOverFont = NSFont(name: "Lucida Grande Bold", size: 9.0)
let gLogFont =     NSFont(name: "Lucida Grande", size: 10.0)
