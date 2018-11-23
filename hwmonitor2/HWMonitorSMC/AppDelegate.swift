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
  var initialAppearance : NSAppearance = NSAppearance(named: .vibrantDark)!
  var licensed : Bool = false
  var translateUnits : Bool = true
  var useIPG : Bool = false
  var ipgInited : Bool = false
  let useIOAcceleratorForGPUs : Bool = UDs.bool(forKey: kUseGPUIOAccelerator)
  var sensorScanner : HWSensorsScanner = HWSensorsScanner()
  var debugIOACC: Bool = true
  
  let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  var statusItemLen : CGFloat = 0
  var hwWC : HWWindowController?

  var cpuFrequencyMax : Double = Double(gCPUBaseFrequency()) // Turbo Boost frequency to be set by the user
  var cpuTDP : Double = 100 // to be set by Intel Power Gadget or by the user
  
  func applicationWillFinishLaunching(_ notification: Notification) {
    let pid = NSRunningApplication.current.processIdentifier
    for app in NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier!) {
      if app.processIdentifier != pid {
        NSApp.terminate(self)
      }
    }
  }
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let forceDark : Bool = UserDefaults.standard.bool(forKey: kDark)
    if !forceDark {
      let appearanceName : String? = UserDefaults.standard.object(forKey: kAppleInterfaceStyle) as? String
      if (appearanceName == nil || ((appearanceName?.range(of: "Dark")) == nil)) {
        self.initialAppearance = NSAppearance(named: .vibrantLight)!
      }
    }
    
    if (UDs.object(forKey: kTranslateUnits) != nil) {
      self.translateUnits = UDs.bool(forKey: kTranslateUnits)
    }
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
    //FIXME: in El Capitan the license window wont show up
    if #available(OSX 10.12, *) {
      if (UDs.object(forKey: kLinceseAccepted) != nil) {
        self.licensed = UDs.bool(forKey: kLinceseAccepted)
      }
      self.licensed = UDs.bool(forKey: kLinceseAccepted)
      if !self.licensed {
        if let lwc = NSStoryboard(name: "License",
                                  bundle: nil).instantiateController(withIdentifier: "License") as? LicenseWC {
          lwc.showWindow(self)
        }
      }
    } else {
      self.licensed = true // to be removed
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

