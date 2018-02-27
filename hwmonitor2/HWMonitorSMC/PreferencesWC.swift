//
//  PreferencesWC.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 25/02/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

class PreferencesWC: NSWindowController, NSWindowDelegate {
  
  override func windowDidLoad() {
    super.windowDidLoad()
    self.window?.appearance = NSAppearance(named: gAppearance )
  }
  
  class func loadFromNib() -> PreferencesWC {
    let wc = (NSStoryboard(name: NSStoryboard.Name(rawValue: "Preferences"),
                           bundle: nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Preferences")) as! PreferencesWC)
    return wc
  }
  
  func windowWillClose(_ notification: Notification) {
    
  }
}
