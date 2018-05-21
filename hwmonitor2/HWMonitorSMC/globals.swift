//
//  globals.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 05/03/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

let kTestVersion            = ""

let kRunAtLogin             = "runAtLogin"
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

let gPopOverFont : NSFont = NSFont(name: "Lucida Grande Bold", size: 9.0) ?? NSFont.systemFont(ofSize:  9.0)
let gLogFont     : NSFont = NSFont(name: "Lucida Grande", size: 10.0)     ?? NSFont.systemFont(ofSize: 10.0)

let gHelperID : CFString = "org.slice.HWMonitorSMC2-Helper" as CFString
