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
    self.slider.doubleValue = timeInterval
    
    self.ramPercentageBtn.state = ud.bool(forKey: kUseMemoryPercentage) ? .on : .off
    self.expandCPUTemperatureBtn.state = ud.bool(forKey: kExpandCPUTemperature) ? .on : .off
    self.expandVoltagesBtn.state = ud.bool(forKey: kExpandVoltages) ? .on : .off
    self.expandCPUFrequenciesBtn.state = ud.bool(forKey: kExpandCPUFrequencies) ? .on : .off
    self.expandAllBtn.state = ud.bool(forKey: kExpandAll) ? .on : .off
    self.dontShowEmptyBtn.state = ud.bool(forKey: kDontShowEmpty) ? .on : .off
    self.darkBtn.state = ud.bool(forKey: kDark) ? .on : .off
    self.hideScrollerBtn.state = ud.bool(forKey: kHideVerticalScroller) ? .on : .off
    self.syncronize()
  }
  
  @IBAction func hideScroller(_ sender: NSButton) {
    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: kHideVerticalScroller)
    } else {
      UserDefaults.standard.set(false, forKey: kHideVerticalScroller)
    }
    self.syncronize()
  }
    
  @IBAction func useMemoryPercentage(_ sender: NSButton) {
    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: kUseMemoryPercentage)
    } else {
      UserDefaults.standard.set(false, forKey: kUseMemoryPercentage)
    }
    self.syncronize()
  }
  
  @IBAction func sliderMoved(_ sender: NSSlider) {
    UserDefaults.standard.set(sender.doubleValue, forKey: kSensorsTimeInterval)
    self.syncronize()
  }
  
  @IBAction func expandCPUTemperature(_ sender: NSButton) {
    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: kExpandCPUTemperature)
    } else {
      UserDefaults.standard.set(false, forKey: kExpandCPUTemperature)
    }
    self.syncronize()
  }
  
  @IBAction func expandVoltages(_ sender: NSButton) {
    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: kExpandVoltages)
    } else {
      UserDefaults.standard.set(false, forKey: kExpandVoltages)
    }
    self.syncronize()
  }
  
  @IBAction func expandCPUFrequencies(_ sender: NSButton) {
    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: kExpandCPUFrequencies)
    } else {
      UserDefaults.standard.set(false, forKey: kExpandCPUFrequencies)
    }
    self.syncronize()
  }
  
  @IBAction func expandAll(_ sender: NSButton) {
    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: kExpandAll)
    } else {
      UserDefaults.standard.set(false, forKey: kExpandAll)
    }
    self.syncronize()
  }
  
  @IBAction func dontshowEmpty(_ sender: NSButton) {
    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: kDontShowEmpty)
    } else {
      UserDefaults.standard.set(false, forKey: kDontShowEmpty)
    }
    self.syncronize()
  }
  
  @IBAction func startDark(_ sender: NSButton) {
    if sender.state == NSControl.StateValue.on {
      UserDefaults.standard.set(true, forKey: kDark)
    } else {
      UserDefaults.standard.set(false, forKey: kDark)
    }
    self.syncronize()
  }
  
  func syncronize() {
    UserDefaults.standard.synchronize()
  }
}
