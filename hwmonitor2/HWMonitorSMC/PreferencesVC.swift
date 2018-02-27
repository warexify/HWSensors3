//
//  PreferencesVC.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 25/02/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

class PreferencesVC: NSViewController {
  @IBOutlet var expandCPUTemperatureBtn : NSButton!
  @IBOutlet var expandVoltagesBtn : NSButton!
  @IBOutlet var expandCPUFrequenciesBtn : NSButton!
  @IBOutlet var expandAllBtn : NSButton!
  @IBOutlet var dontShowEmptyBtn : NSButton!
  @IBOutlet var darkBtn : NSButton!
  @IBOutlet var slider : NSSlider!
  @IBOutlet var effectView : NSVisualEffectView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.effectView.appearance = NSAppearance(named: gAppearance)
    getPreferences()
  }
  
  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }
  
  func getPreferences() {
    let ud = UserDefaults.standard
    var timeInterval : TimeInterval = 3
    if (UserDefaults.standard.object(forKey: "SensorsTimeInterval") != nil) {
      timeInterval = UserDefaults.standard.double(forKey: "SensorsTimeInterval")
      if timeInterval < 3 {
        timeInterval = 3
      }
    }
    self.slider.doubleValue = timeInterval
    
    
    self.expandCPUTemperatureBtn.state = ud.bool(forKey: "expandCPUTemperature") ? .on : .off
    self.expandVoltagesBtn.state = ud.bool(forKey: "expandVoltages") ? .on : .off
    self.expandCPUFrequenciesBtn.state = ud.bool(forKey: "expandCPUFrequencies") ? .on : .off
    self.expandAllBtn.state = ud.bool(forKey: "expandAll") ? .on : .off
    self.dontShowEmptyBtn.state = ud.bool(forKey: "dontshowEmpty") ? .on : .off
    self.darkBtn.state = ud.bool(forKey: "Dark") ? .on : .off
    self.syncronize()
  }
  
  
  @IBAction func sliderMoved(_ sender: NSSlider) {
    UserDefaults.standard.set(sender.doubleValue, forKey: "SensorsTimeInterval")
    self.syncronize()
  }
  
  @IBAction func expandCPUTemperature(_ sender: NSButton) {
    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: "expandCPUTemperature")
    } else {
      UserDefaults.standard.set(false, forKey: "expandCPUTemperature")
    }
    self.syncronize()
  }
  
  @IBAction func expandVoltages(_ sender: NSButton) {
    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: "expandVoltages")
    } else {
      UserDefaults.standard.set(false, forKey: "expandVoltages")
    }
    self.syncronize()
  }
  
  @IBAction func expandCPUFrequencies(_ sender: NSButton) {
    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: "expandCPUFrequencies")
    } else {
      UserDefaults.standard.set(false, forKey: "expandCPUFrequencies")
    }
    self.syncronize()
  }
  
  @IBAction func expandAll(_ sender: NSButton) {
    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: "expandAll")
    } else {
      UserDefaults.standard.set(false, forKey: "expandAll")
    }
    self.syncronize()
  }
  
  @IBAction func dontshowEmpty(_ sender: NSButton) {
    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: "dontshowEmpty")
    } else {
      UserDefaults.standard.set(false, forKey: "dontshowEmpty")
    }
    self.syncronize()
  }
  
  @IBAction func startDark(_ sender: NSButton) {
    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: "Dark")
    } else {
      UserDefaults.standard.set(false, forKey: "Dark")
    }
    self.syncronize()
  }
  
  func syncronize() {
    UserDefaults.standard.synchronize()
  }
}
