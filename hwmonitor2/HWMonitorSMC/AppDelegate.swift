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
  
  let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  var hwWC : HWWindowController?
  
  var graphNum : Int = 0
  var plotNum: Int {
    get {
      return self.graphNum
    }
    set {
      self.graphNum = newValue
    }
  }

  var cpuFrequencyMax : Double = Double(gCPUBaseFrequency()) // Turbo Boost frequency to be set by the user
  var cpuTDP : Double = 100 // to be set by Intel Power Gadget or by the user
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let icon = NSImage(named: "temperature_small")
    icon?.isTemplate = true
    self.statusItem.image = icon
    
    if (UDs.object(forKey: kUseIPG) != nil) {
      self.useIPG = UDs.bool(forKey: kUseIPG)
    }
    self.hwWC = HWWindowController.loadFromNib()
    
    if (UserDefaults.standard.object(forKey: kRunAtLogin) == nil) {
      self.setLaunchAtStartup()
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

