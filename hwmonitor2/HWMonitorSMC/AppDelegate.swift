//
//  AppDelegate.swift
//  HWTest
//
//  Created by vector sigma on 24/02/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa
let gAppearance = (UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" ||
  UserDefaults.standard.bool(forKey: "Dark")) ?
  NSAppearance.Name.vibrantDark :
  NSAppearance.Name.vibrantLight

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  var hwWC : HWWindowController?
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let icon = NSImage(named: NSImage.Name(rawValue: "temperature_small"))
    icon?.isTemplate = true
    self.statusItem.image = icon
    
    self.hwWC = HWWindowController.loadFromNib()
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
  override func awakeFromNib() {
  }
  
}

