//
//  AppDelegate.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 24/02/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  var useIPG : Bool = false
  var ipgInited : Bool = false
  let useIOAcceleratorForGPUs : Bool = UDs.bool(forKey: kUseGPUIOAccelerator)
  var sensorScanner : HWSensorsScanner = HWSensorsScanner()
  var debugIOACC: Bool = true
  
  let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  var hwWC : HWWindowController?

  var cpuFrequencyMax : Double = Double(gCPUBaseFrequency()) // Turbo Boost frequency to be set by the user
  var cpuTDP : Double = 100 // to be set by Intel Power Gadget or by the user
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let icon = NSImage(named: "temperature_small")
    icon?.isTemplate = true
    self.statusItem.image = icon
    
    self.license()
    
    if (UDs.object(forKey: kUseIPG) != nil) {
      self.useIPG = UDs.bool(forKey: kUseIPG)
    }
    self.hwWC = HWWindowController.loadFromNib()
    
    if (UserDefaults.standard.object(forKey: kRunAtLogin) == nil) {
      self.setLaunchAtStartup()
    }
  }
  
  func license() {
    if !UDs.bool(forKey: kLinceseAccepted) {
      if let lwc = NSStoryboard(name: "License",
                                bundle: nil).instantiateController(withIdentifier: "License") as? LicenseWC {
        NSApp.beginModalSession(for: lwc.window!)
      }
    }
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
    if self.ipgInited {
      IntelEnergyLibShutdown()
    }
  }
  
  override func awakeFromNib() {
  }
  
}

