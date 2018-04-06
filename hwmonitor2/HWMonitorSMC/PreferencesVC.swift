//
//  PreferencesVC.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 25/02/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

class PreferencesVC: NSViewController {
  @IBOutlet var ramPercentageBtn        : NSButton!
  @IBOutlet var expandCPUTemperatureBtn : NSButton!
  @IBOutlet var expandVoltagesBtn       : NSButton!
  @IBOutlet var expandCPUFrequenciesBtn : NSButton!
  @IBOutlet var expandAllBtn            : NSButton!
  @IBOutlet var dontShowEmptyBtn        : NSButton!
  @IBOutlet var darkBtn                 : NSButton!
  @IBOutlet var hideScrollerBtn         : NSButton!
  @IBOutlet var runAtLoginBtn           : NSButton!
  @IBOutlet var slider                  : NSSlider!
  @IBOutlet var effectView              : NSVisualEffectView!
  
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
    if (UserDefaults.standard.object(forKey: kSensorsTimeInterval) != nil) {
      timeInterval = UserDefaults.standard.double(forKey: kSensorsTimeInterval)
      if timeInterval < 3 {
        timeInterval = 3
      }
    }
    let shared = NSApplication.shared.delegate as! AppDelegate
    let state : Bool = shared.applicationIsInStartUpItems()
    self.runAtLoginBtn.state = state ? .on : .off
    
    self.slider.doubleValue = timeInterval
    
    self.ramPercentageBtn.state = ud.bool(forKey: kUseMemoryPercentage) ? .on : .off
    self.expandCPUTemperatureBtn.state = ud.bool(forKey: kExpandCPUTemperature) ? .on : .off
    self.expandVoltagesBtn.state = ud.bool(forKey: kExpandVoltages) ? .on : .off
    self.expandCPUFrequenciesBtn.state = ud.bool(forKey: kExpandCPUFrequencies) ? .on : .off
    self.expandAllBtn.state = ud.bool(forKey: kExpandAll) ? .on : .off
    self.dontShowEmptyBtn.state = ud.bool(forKey: kDontShowEmpty) ? .on : .off
    self.darkBtn.state = ud.bool(forKey: kDark) ? .on : .off
    self.hideScrollerBtn.state = ud.bool(forKey: kHideVerticalScroller) ? .on : .off
    self.synchronize()
  }
  
  @IBAction func hideScroller(_ sender: NSButton) {
/*    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: kHideVerticalScroller)
    } else {
      UserDefaults.standard.set(false, forKey: kHideVerticalScroller)
    } */
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kHideVerticalScroller)
    self.synchronize()
  }
    
  @IBAction func useMemoryPercentage(_ sender: NSButton) {
/*    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: kUseMemoryPercentage)
    } else {
      UserDefaults.standard.set(false, forKey: kUseMemoryPercentage)
    } */
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kUseMemoryPercentage)
    self.synchronize()
  }
  
  @IBAction func sliderMoved(_ sender: NSSlider) {
    UserDefaults.standard.set(sender.doubleValue, forKey: kSensorsTimeInterval)
    self.synchronize()
  }
  
  @IBAction func expandCPUTemperature(_ sender: NSButton) {
/*    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: kExpandCPUTemperature)
    } else {
      UserDefaults.standard.set(false, forKey: kExpandCPUTemperature)
    } */
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kExpandCPUTemperature)
    self.synchronize()
  }
  
  @IBAction func expandVoltages(_ sender: NSButton) {
/*    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: kExpandVoltages)
    } else {
      UserDefaults.standard.set(false, forKey: kExpandVoltages)
    } */
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kExpandVoltages)
    self.synchronize()
  }
  
  @IBAction func expandCPUFrequencies(_ sender: NSButton) {
/*    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: kExpandCPUFrequencies)
    } else {
      UserDefaults.standard.set(false, forKey: kExpandCPUFrequencies)
    }  */
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kExpandCPUFrequencies)
    self.synchronize()
  }
  
  @IBAction func expandAll(_ sender: NSButton) {
/*    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: kExpandAll)
    } else {
      UserDefaults.standard.set(false, forKey: kExpandAll)
    } */
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kExpandAll)
    self.synchronize()
  }
  
  @IBAction func dontshowEmpty(_ sender: NSButton) {
/*    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: kDontShowEmpty)
    } else {
      UserDefaults.standard.set(false, forKey: kDontShowEmpty)
    } */
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kDontShowEmpty)
    self.synchronize()
  }
  
  @IBAction func startDark(_ sender: NSButton) {
/*    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: kDark)
    } else {
      UserDefaults.standard.set(false, forKey: kDark)
    } */
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kDark)
    self.synchronize()
  }
  
  @IBAction func setAsLoginItem(_ sender: NSButton) {
    let shared = NSApplication.shared.delegate as! AppDelegate
    
    if shared.applicationIsInStartUpItems() {
      shared.removeLaunchAtStartup()
    } else {
      shared.addLaunchAtStartup()
    }
    let state : Bool = shared.applicationIsInStartUpItems()
    self.runAtLoginBtn.state = state ? .on : .off
    
    UserDefaults.standard.set(true, forKey: kRunAtLoginWasSet)
    self.synchronize()
  }
  
  func synchronize() {
    UserDefaults.standard.synchronize()
  }
}
