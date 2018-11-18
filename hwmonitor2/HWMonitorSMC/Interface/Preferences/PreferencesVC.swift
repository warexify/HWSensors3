//
//  PreferencesVC.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 25/02/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

class TemplateImageView: NSImageView {

}

class PreferencesVC: NSViewController, NSTextFieldDelegate {
  @IBOutlet var cpuTDPOverrideField       : NSTextField!
  @IBOutlet var cpuFrequencyOverrideField : NSTextField!
  
  @IBOutlet var ramPercentageBtn        : NSButton!
  @IBOutlet var expandCPUTemperatureBtn : NSButton!
  @IBOutlet var expandCPUFrequenciesBtn : NSButton!
  @IBOutlet var expandAllBtn            : NSButton!
  @IBOutlet var dontShowEmptyBtn        : NSButton!
  @IBOutlet var darkBtn                 : NSButton!
  @IBOutlet var hideScrollerBtn         : NSButton!
  @IBOutlet var translateUnitsBtn       : NSButton!
  @IBOutlet var runAtLoginBtn           : NSButton!
  @IBOutlet var useGPUAccelerator       : NSButton!
  
  @IBOutlet var useIntelPowerGadget     : NSButton!
  
  @IBOutlet var sliderCPU               : NSSlider!
  @IBOutlet var sliderGPU               : NSSlider!
  @IBOutlet var sliderMoBo              : NSSlider!
  @IBOutlet var sliderFans              : NSSlider!
  @IBOutlet var sliderRam               : NSSlider!
  @IBOutlet var sliderMedia             : NSSlider!
  @IBOutlet var sliderBattery           : NSSlider!
  
  @IBOutlet var sliderFieldCPU          : NSTextField!
  @IBOutlet var sliderFieldGPU          : NSTextField!
  @IBOutlet var sliderFieldMoBo         : NSTextField!
  @IBOutlet var sliderFieldFans         : NSTextField!
  @IBOutlet var sliderFieldRam          : NSTextField!
  @IBOutlet var sliderFieldMedia        : NSTextField!
  @IBOutlet var sliderFieldBattery      : NSTextField!
  
  private var appearanceObserver: NSKeyValueObservation?
  @IBOutlet var effectView              : NSVisualEffectView!
  
  var CPU_TDP_MAX : Double = 100 // fake value until Intel Power Gadget runs, or user define it. Just for the plot
  var CPU_Frequency_MAX : Double = Double(gCPUBaseFrequency()) // base frequency until user set the turbo boost value
  
  override func viewDidLoad() {
    super.viewDidLoad()

    for v in (self.view.subviews[0] as! NSVisualEffectView).subviews {
      if v is TemplateImageView {
        (v as! TemplateImageView).image?.isTemplate = true
      }
    }
    
    self.updateAppearance()
    if #available(OSX 10.14, *) {
      self.appearanceObserver = self.view.observe(\.effectiveAppearance) { [weak self] _, _  in
        self?.updateAppearance()
      }
    }
    getPreferences()
  }
  
  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }
  
  private func updateAppearance() {
    self.view.window?.animator().appearance = getAppearance()
  }
  
  deinit {
    if self.appearanceObserver != nil {
      self.appearanceObserver!.invalidate()
      self.appearanceObserver = nil
    }
  }
  
  func controlTextDidEndEditing(_ obj: Notification) {
    if let field : NSTextField = obj.object as? NSTextField {
      if field == self.cpuTDPOverrideField {
        var tdp : Double = Double(field.stringValue) ?? 0
        if tdp < 7 || tdp > 250 {
          tdp = 100
        }
        AppSd.cpuTDP = tdp
        UDs.set(tdp, forKey: kCPU_TDP_MAX)
        field.stringValue = String(format: "%.2f", tdp)
      } else if field == self.cpuFrequencyOverrideField {
        var freq : Double = Double(field.stringValue) ?? 0
        if freq <= 0 || freq > 7000 {
          freq = Double(gCPUBaseFrequency())
        }
        AppSd.cpuFrequencyMax = freq
        UDs.set(freq, forKey: kCPU_Frequency_MAX)
        field.stringValue = String(format: "%.2f", freq)
      }
      UDs.synchronize()
    }
  }
  
  func getPreferences() {
    if UDs.bool(forKey: kUseIPG) {
      self.useIntelPowerGadget.state = .on
      if AppSd.ipgInited {
        var tdp : Double = 0
        GetTDP(0, &tdp)
        self.cpuTDPOverrideField.isEnabled = false
        self.cpuTDPOverrideField.stringValue = String(format: "%.f", tdp)
        AppSd.cpuTDP = tdp
      } else {
        let tdp : Double = UDs.double(forKey: kCPU_TDP_MAX)
        self.CPU_TDP_MAX = (tdp >= 7 && tdp <= 250) ? tdp : 100
        self.cpuTDPOverrideField.stringValue = String(format: "%.f", self.CPU_TDP_MAX)
        UDs.set(tdp, forKey: kCPU_TDP_MAX)
        AppSd.cpuTDP = tdp
      }
    }
    
    let freqMax : Double = UDs.double(forKey: kCPU_Frequency_MAX)
    self.CPU_Frequency_MAX = (freqMax > 0 && freqMax <= 7000) ? freqMax : 5000
    self.cpuFrequencyOverrideField.stringValue = String(format: "%.f", self.CPU_Frequency_MAX)
    UDs.set(freqMax, forKey: kCPU_Frequency_MAX)
    
    
    AppSd.cpuFrequencyMax = freqMax
    
    self.translateUnitsBtn.state = UDs.bool(forKey: kTranslateUnits) ? .on : .off
    self.runAtLoginBtn.state = UDs.bool(forKey: kRunAtLogin) ? .on : .off
    
    self.useGPUAccelerator.state = UDs.bool(forKey: kUseGPUIOAccelerator) ? .on : .off
    self.ramPercentageBtn.state = UDs.bool(forKey: kUseMemoryPercentage) ? .on : .off
    self.expandCPUTemperatureBtn.state = UDs.bool(forKey: kExpandCPUTemperature) ? .on : .off
    self.expandCPUFrequenciesBtn.state = UDs.bool(forKey: kExpandCPUFrequencies) ? .on : .off
    self.expandAllBtn.state = UDs.bool(forKey: kExpandAll) ? .on : .off
    self.dontShowEmptyBtn.state = UDs.bool(forKey: kDontShowEmpty) ? .on : .off
    self.darkBtn.state = UDs.bool(forKey: kDark) ? .on : .off
    self.hideScrollerBtn.state = UDs.bool(forKey: kHideVerticalScroller) ? .on : .off
    self.synchronize()
    
    var ti : TimeInterval = UDs.double(forKey: kCPUTimeInterval) * 1000
    
    self.sliderCPU.doubleValue = (ti >= 100 && ti <= 10000) ? ti : 1500
    self.sliderCPU.performClick(nil)
    
    ti = UDs.double(forKey: kGPUTimeInterval) * 1000
    self.sliderGPU.doubleValue = (ti >= 100 && ti <= 10000) ? ti : 3000
    self.sliderGPU.performClick(nil)
    
    ti = UDs.double(forKey: kMoBoTimeInterval) * 1000
    self.sliderMoBo.doubleValue = (ti >= 100 && ti <= 10000) ? ti : 3000
    self.sliderMoBo.performClick(nil)
    
    ti = UDs.double(forKey: kFansTimeInterval) * 1000
    self.sliderFans.doubleValue = (ti >= 100 && ti <= 10000) ? ti : 3000
    self.sliderFans.performClick(nil)
    
    ti = UDs.double(forKey: kRAMTimeInterval) * 1000
    self.sliderRam.doubleValue = (ti >= 100 && ti <= 10000) ? ti : 3000
    self.sliderRam.performClick(nil)
    
    ti = UDs.double(forKey: kMediaTimeInterval) * 1000
    self.sliderMedia.doubleValue = (ti >= 100 && ti <= 600000) ? ti : 300000
    self.sliderMedia.performClick(nil)
    
    ti = UDs.double(forKey: kBatteryTimeInterval) * 1000
    self.sliderBattery.doubleValue = (ti >= 100 && ti <= 10000) ? ti : 3000
    self.sliderBattery.performClick(nil)
  }
  
  @IBAction func hideScroller(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kHideVerticalScroller)
    self.synchronize()
  }
    
  @IBAction func useMemoryPercentage(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kUseMemoryPercentage)
    self.synchronize()
  }
  
  @IBAction func useIntelPowerGadget(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kUseIPG)
    self.synchronize()
  }
  
  @IBAction func sliderCPUMoved(_ sender: NSSlider?) {
    let val : Double = self.sliderCPU.doubleValue / 1000
    self.sliderFieldCPU.stringValue = String(format: "%.2f''", val)
    UDs.set(val, forKey: kCPUTimeInterval)
    self.synchronize()
    if (sender != nil) {
      if let popoverVC = (AppSd.hwWC?.contentViewController as? HWViewController)?.popoverVC {
        if (popoverVC.CPUNode == nil) { return }
        if (popoverVC.timerCPU != nil) {
          if popoverVC.timerCPU!.isValid { popoverVC.timerCPU!.invalidate() }
        }
        popoverVC.timeCPUInterval = val
        popoverVC.updateCPUSensors()
        popoverVC.timerCPU = Timer.scheduledTimer(timeInterval: popoverVC.timeCPUInterval,
                                                  target: popoverVC,
                                                  selector: #selector(popoverVC.updateCPUSensors),
                                                  userInfo: nil,
                                                  repeats: true)
      }
    }
  }
  
  @IBAction func sliderGPUMoved(_ sender: NSSlider?) {
    let val : Double = self.sliderGPU.doubleValue / 1000
    self.sliderFieldGPU.stringValue = String(format: "%.2f''", val)
    UDs.set(val, forKey: kGPUTimeInterval)
    self.synchronize()
    
    if (sender != nil) {
      if let popoverVC = (AppSd.hwWC?.contentViewController as? HWViewController)?.popoverVC {
        if (popoverVC.GPUNode == nil) { return }
        if (popoverVC.timerGPU != nil) {
          if popoverVC.timerGPU!.isValid { popoverVC.timerGPU!.invalidate() }
        }
        popoverVC.timeGPUInterval = val
        popoverVC.updateGPUSensors()
        popoverVC.timerGPU = Timer.scheduledTimer(timeInterval: popoverVC.timeGPUInterval,
                                                  target: popoverVC,
                                                  selector: #selector(popoverVC.updateGPUSensors),
                                                  userInfo: nil,
                                                  repeats: true)
      }
    }
  }
  
  @IBAction func sliderMoBoMoved(_ sender: NSSlider?) {
    let val : Double = self.sliderMoBo.doubleValue / 1000
    self.sliderFieldMoBo.stringValue = String(format: "%.2f''", val)
    UDs.set(val, forKey: kMoBoTimeInterval)
    self.synchronize()
    
    if (sender != nil) {
      if let popoverVC = (AppSd.hwWC?.contentViewController as? HWViewController)?.popoverVC {
        if (popoverVC.MOBONode == nil) { return }
        if (popoverVC.timerMotherboard != nil) {
          if popoverVC.timerMotherboard!.isValid { popoverVC.timerMotherboard!.invalidate() }
        }
        popoverVC.timeMotherBoardInterval = val
        popoverVC.updateMotherboardSensors()
        popoverVC.timerMotherboard = Timer.scheduledTimer(timeInterval: popoverVC.timeMotherBoardInterval,
                                                  target: popoverVC,
                                                  selector: #selector(popoverVC.updateMotherboardSensors),
                                                  userInfo: nil,
                                                  repeats: true)
      }
    }
  }
  
  @IBAction func sliderFansMoved(_ sender: NSSlider?) {
    let val : Double = self.sliderFans.doubleValue / 1000
    self.sliderFieldFans.stringValue = String(format: "%.2f''", val)
    UDs.set(val, forKey: kFansTimeInterval)
    self.synchronize()
    
    if (sender != nil) {
      if let popoverVC = (AppSd.hwWC?.contentViewController as? HWViewController)?.popoverVC {
        if (popoverVC.FansNode == nil) { return }
        if (popoverVC.timerFans != nil) {
          if popoverVC.timerFans!.isValid { popoverVC.timerFans!.invalidate() }
        }
        popoverVC.timeFansInterval = val
        popoverVC.updateMotherboardSensors()
        popoverVC.timerFans = Timer.scheduledTimer(timeInterval: popoverVC.timeFansInterval,
                                                          target: popoverVC,
                                                          selector: #selector(popoverVC.updateFanSensors),
                                                          userInfo: nil,
                                                          repeats: true)
      }
    }
  }
  
  @IBAction func sliderRAMMoved(_ sender: NSSlider?) {
    let val : Double = self.sliderRam.doubleValue / 1000
    self.sliderFieldRam.stringValue = String(format: "%.2f''", val)
    UDs.set(val, forKey: kRAMTimeInterval)
    self.synchronize()
    
    if (sender != nil) {
      if let popoverVC = (AppSd.hwWC?.contentViewController as? HWViewController)?.popoverVC {
        if (popoverVC.RAMNode == nil) { return }
        if (popoverVC.timerRAM != nil) {
          if popoverVC.timerRAM!.isValid { popoverVC.timerRAM!.invalidate() }
        }
        popoverVC.timeRAMInterval = val
        popoverVC.updateRAMSensors()
        popoverVC.timerRAM = Timer.scheduledTimer(timeInterval: popoverVC.timeRAMInterval,
                                                   target: popoverVC,
                                                   selector: #selector(popoverVC.updateRAMSensors),
                                                   userInfo: nil,
                                                   repeats: true)
      }
    }
  }
  
  @IBAction func sliderMediaMoved(_ sender: NSSlider?) {
    let val : Double = self.sliderMedia.doubleValue / 1000
    self.sliderFieldMedia.stringValue = String(format: "%.2f''", val)
    UDs.set(val, forKey: kMediaTimeInterval)
    self.synchronize()
    
    if (sender != nil) {
      if let popoverVC = (AppSd.hwWC?.contentViewController as? HWViewController)?.popoverVC {
        if (popoverVC.mediaNode == nil) { return }
        if (popoverVC.timerMedia != nil) {
          if popoverVC.timerMedia!.isValid { popoverVC.timerMedia!.invalidate() }
        }
        popoverVC.timeMediaInterval = val
        popoverVC.updateMediaSensors()
        popoverVC.timerMedia = Timer.scheduledTimer(timeInterval: popoverVC.timeMediaInterval,
                                                  target: popoverVC,
                                                  selector: #selector(popoverVC.updateMediaSensors),
                                                  userInfo: nil,
                                                  repeats: true)
      }
    }
  }
  
  @IBAction func sliderBatteryMoved(_ sender: NSSlider?) {
    let val : Double = self.sliderBattery.doubleValue / 1000
    self.sliderFieldBattery.stringValue = String(format: "%.2f''", val)
    UDs.set(val, forKey: kBatteryTimeInterval)
    self.synchronize()
    
    if (sender != nil) {
      if let popoverVC = (AppSd.hwWC?.contentViewController as? HWViewController)?.popoverVC {
        if (popoverVC.batteriesNode == nil) { return }
        if (popoverVC.timerBattery != nil) {
          if popoverVC.timerBattery!.isValid { popoverVC.timerBattery!.invalidate() }
        }
        popoverVC.timeBatteryInterval = val
        popoverVC.updateBatterySensors()
        popoverVC.timerBattery = Timer.scheduledTimer(timeInterval: popoverVC.timeBatteryInterval,
                                                    target: popoverVC,
                                                    selector: #selector(popoverVC.updateBatterySensors),
                                                    userInfo: nil,
                                                    repeats: true)
      }
    }
  }
  
  @IBAction func expandCPUTemperature(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kExpandCPUTemperature)
    self.synchronize()
  }
  
  
  @IBAction func expandCPUFrequencies(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kExpandCPUFrequencies)
    self.synchronize()
  }

  @IBAction func useGPUIOAccelerator(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kUseGPUIOAccelerator)
    self.synchronize()
  }
  
  @IBAction func expandAll(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kExpandAll)
    self.synchronize()
  }
  
  @IBAction func dontshowEmpty(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kDontShowEmpty)
    self.synchronize()
  }
  
  @IBAction func startDark(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kDark)
    self.synchronize()
  }
  
  @IBAction func translateUnits(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kTranslateUnits)
    AppSd.translateUnits = sender.state == NSControl.StateValue.on
    self.synchronize()
  }
  
  @IBAction func setAsLoginItem(_ sender: NSButton) {
    if sender.state == .on {
      AppSd.setLaunchAtStartup()
    } else {
      AppSd.removeLaunchAtStartup()
    }
    self.runAtLoginBtn.state = UDs.bool(forKey: kRunAtLogin) ? .on : .off
  }
  
  func synchronize() {
    UDs.synchronize()
  }
}
