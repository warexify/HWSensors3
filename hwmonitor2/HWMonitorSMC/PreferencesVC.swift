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
  @IBOutlet var useGPUAccelerator       : NSButton!
  @IBOutlet var slider                  : NSSlider!
  @IBOutlet var effectView              : NSVisualEffectView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.effectView.appearance = getAppearance()
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
      if timeInterval < 1 {
        timeInterval = 3
      }
    }
    self.runAtLoginBtn.state = ud.bool(forKey: kRunAtLogin) ? .on : .off
    self.slider.doubleValue = timeInterval
    self.useGPUAccelerator.state = ud.bool(forKey: kUseGPUIOAccelerator) ? .on : .off
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
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kHideVerticalScroller)
    self.synchronize()
  }
    
  @IBAction func useMemoryPercentage(_ sender: NSButton) {
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kUseMemoryPercentage)
    self.synchronize()
  }
  
  @IBAction func sliderMoved(_ sender: NSSlider) {
    UserDefaults.standard.set(sender.doubleValue, forKey: kSensorsTimeInterval)
    self.synchronize()
  }
  
  @IBAction func expandCPUTemperature(_ sender: NSButton) {
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kExpandCPUTemperature)
    self.synchronize()
  }
  
  @IBAction func expandVoltages(_ sender: NSButton) {
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kExpandVoltages)
    self.synchronize()
  }
  
  @IBAction func expandCPUFrequencies(_ sender: NSButton) {
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kExpandCPUFrequencies)
    self.synchronize()
  }

  @IBAction func useGPUIOAccelerator(_ sender: NSButton) {
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kUseGPUIOAccelerator)
    self.synchronize()
  }
  
  @IBAction func expandAll(_ sender: NSButton) {
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kExpandAll)
    self.synchronize()
  }
  
  @IBAction func dontshowEmpty(_ sender: NSButton) {
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kDontShowEmpty)
    self.synchronize()
  }
  
  @IBAction func startDark(_ sender: NSButton) {
    UserDefaults.standard.set(sender.state == NSControl.StateValue.on, forKey: kDark)
    self.synchronize()
  }
  
  @IBAction func setAsLoginItem(_ sender: NSButton) {
    let shared = NSApplication.shared.delegate as! AppDelegate
    if sender.state == .on {
      shared.setLaunchAtStartup()
    } else {
      shared.removeLaunchAtStartup()
    }
    print(UserDefaults.standard.bool(forKey: kRunAtLogin))
    self.runAtLoginBtn.state = UserDefaults.standard.bool(forKey: kRunAtLogin) ? .on : .off
  }
  
  func synchronize() {
    UserDefaults.standard.synchronize()
  }
}
