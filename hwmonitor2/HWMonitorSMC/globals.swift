//
//  globals.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 05/03/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

let kTestVersion            = ""

let kLinceseAccepted        = "LinceseAccepted"
let kRunAtLogin             = "runAtLogin"
let kUseIPG                 = "UseIPG"
let kShowGadget             = "ShowGadget"
let kHideVerticalScroller   = "hideVerticalScroller"
let kAppleInterfaceStyle    = "AppleInterfaceStyle"
let kDark                   = "Dark"
let kPopoverHeight          = "popoverHeight"
let kPopoverWidth           = "popoverWidth"
let kSensorsTimeInterval    = "SensorsTimeInterval"

let kCPU_TDP_MAX            = "CPU_TDP_MAX"
let kCPU_Frequency_MAX      = "CPU_Frequency_MAX"


let kCPUTimeInterval        = "CPUTimeInterval"
let kGPUTimeInterval        = "GPUTimeInterval"
let kMoBoTimeInterval       = "MoBoTimeInterval"
let kFansTimeInterval       = "FansTimeInterval"
let kRAMTimeInterval        = "RAMTimeInterval"
let kMediaTimeInterval      = "MediaTimeInterval"
let kBatteryTimeInterval    = "BatteryTimeInterval"

let kUseMemoryPercentage    = "useMemoryPercentage"
let kExpandCPUTemperature   = "expandCPUTemperature"
let kExpandVoltages         = "expandVoltages"
let kExpandCPUFrequencies   = "expandCPUFrequencies"
let kExpandAll              = "expandAll"
let kDontShowEmpty          = "dontshowEmpty"
let kUseGPUIOAccelerator    = "useGPUIOAccelerator"

let AppSd = NSApplication.shared.delegate as! AppDelegate
let UDs = UserDefaults.standard
let kMinWidth  : CGFloat = 370
let kMinHeight : CGFloat = 270

let gHideVerticalScroller : Bool = UserDefaults.standard.bool(forKey: kHideVerticalScroller)

let gPopOverFont : NSFont = NSFont(name: "Lucida Grande Bold", size: 9.0) ?? NSFont.systemFont(ofSize:  9.0)
let gLogFont     : NSFont = NSFont(name: "Lucida Grande", size: 10.0)     ?? NSFont.systemFont(ofSize: 10.0)

let gHelperID : CFString = "org.slice.HWMonitorSMC2-Helper" as CFString

let gSMC = SMCKit.init()

func gCPUPackageCount() -> Int {
  var c: Int = 0
  var l: size_t = MemoryLayout<Int>.size
  sysctlbyname("hw.packages", &c, &l, nil, 0)
  return c
}

func gCountPhisycalCores() -> Int {
  var c: Int = 0
  var l: size_t = MemoryLayout<Int>.size
  sysctlbyname("machdep.cpu.core_count", &c, &l, nil, 0)
  return c
}

func gCPUBaseFrequency() -> Int64 {
  var frequency: Int64 = 0
  var size = MemoryLayout<Int64>.size
  sysctlbyname("hw.cpufrequency", &frequency, &size, nil, 0)
  return (frequency > 0) ? (frequency / 1000000) : 0
}

func getAppearance() -> NSAppearance {
  let forceDark : Bool = UserDefaults.standard.bool(forKey: kDark)
  var appearance = NSAppearance(named: .vibrantDark)
  if !forceDark {
    let appearanceName : String? = UserDefaults.standard.object(forKey: kAppleInterfaceStyle) as? String
    if (appearanceName == nil || ((appearanceName?.range(of: "Dark")) == nil)) {
      appearance = NSAppearance(named: .vibrantLight)
    }
  }
  return appearance!
}

