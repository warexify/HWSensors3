//
//  HWOulineView.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 24/02/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

class RightClickWindowController: NSWindowController, NSWindowDelegate {
  override func windowDidLoad() {
    super.windowDidLoad()
    self.window?.appearance = NSAppearance(named: gAppearance )
  }
}

class RightClickViewController: NSViewController {
  @IBOutlet var textView : NSTextView!
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  
  func loadFromNib() -> RightClickViewController {
    let s = NSStoryboard(name: NSStoryboard.Name(rawValue: "Info"), bundle: nil)
    let vc = s.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Info"))
    return vc as! RightClickViewController
  }
  
  @IBAction func copyToPasteboard(_ sender: Any?) {
    var log = self.textView.string
    
    if log.count > 0 {
      let pasteboard = NSPasteboard.general
      pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
      if let version = Bundle.main.infoDictionary?["CFBundleVersion"]  as? String {
        log = "   HWMonitorSMC2 v" + version + " \(kTestVersion)\n\n" + log
      }
      if !pasteboard.setString(log, forType: NSPasteboard.PasteboardType.string) {
        NSSound.beep()
      }
    } else {
      NSSound.beep()
    }
  }
}

class HWOulineView: NSOutlineView, NSPopoverDelegate {
  
  enum InfoViewSize : Int {
    case small  = 1
    case normal = 2
    case medium = 3
    case big    = 4
  }
  
  func popoverDidClose(_ notification: Notification) {
    let shared = NSApplication.shared.delegate as! AppDelegate
    if let popover = (shared.hwWC?.contentViewController as! HWViewController).popover {
      if (self.window != nil) && !(self.window?.isKeyWindow)! {
        if popover.isShown {
          popover.close()
        }
      }
    }
  }

  override func menu(for event: NSEvent) -> NSMenu? {
    let point = self.convert(event.locationInWindow, from: nil)
    let row = self.row(at: point)
    if let item : HWTreeNode = self.item(atRow: row) as? HWTreeNode {
      self.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
      var rowView : NSView? = nil
      let pop : NSPopover? = self.getLogPopOverForNode(item, at: row, rowView: &rowView)
      if (pop != nil && rowView != nil) {
        pop?.show(relativeTo: (rowView?.bounds)!, of: rowView!, preferredEdge: NSRectEdge.maxX)
      }
    }
    
    return nil
  }
  
  private func getLogPopOverForNode(_ node: HWTreeNode, at row: Int, rowView: inout NSView?) -> NSPopover? {
    var log : String? = nil
    var size : InfoViewSize = .normal
    if ((node.sensorData?.sensor?.group) != nil) {
      let g : SensorGroup = (node.sensorData?.sensor?.group)!
      
      switch g {/*
         case UInt(TemperatureSensorGroup):
         case UInt(VoltageSensorGroup):
         case UInt(TachometerSensorGroup):
         case UInt(FrequencySensorGroup):
         case UInt(MultiplierSensorGroup):*/
      case UInt(BatterySensorsGroup):
        size = .normal
        log = self.getBatteryInfo()
      case UInt(MemorySensorGroup):
        size = .normal
        log = self.getMemoryInfo()
      case UInt(HDSmartLifeSensorGroup): fallthrough
      case UInt(HDSmartTempSensorGroup): fallthrough
      case UInt(MediaSMARTContenitorGroup):
        size = .normal
        log = node.sensorData?.sensor?.characteristics
      default:
        break
      }
    } else {
      //we are on a parent
      if let groupString = node.sensorData?.group {
        switch groupString {
        case NSLocalizedString("CPU Temperatures", comment: ""): fallthrough
        case NSLocalizedString("CPU Frequencies", comment: ""):
          size = .medium
          log = self.getCPUInfo()
        case NSLocalizedString("RAM", comment: ""):
          size = .normal
          log = self.getMemoryInfo()
        case NSLocalizedString("Batteries", comment: ""):
          size = .normal
          log = self.getBatteryInfo()
        case NSLocalizedString("Multipliers", comment: ""):   fallthrough
        case NSLocalizedString("Voltages", comment: ""):      fallthrough
        case NSLocalizedString("Fans or Pumps", comment: ""): fallthrough
        case NSLocalizedString("Temperatures", comment: ""):
          size = .big
          log = self.getSystemStatus()
        case NSLocalizedString("Media health", comment: ""):
          var allDrivesInfo : String = ""
          for diskNode in node.children! {
            if let disk : HWTreeNode = diskNode as? HWTreeNode {
              if let characteristics : String = disk.sensorData?.sensor?.characteristics {
                allDrivesInfo += characteristics
                allDrivesInfo += "\n"
              }
            }
          }
          if allDrivesInfo.count > 0 {
            size = .medium
            log = allDrivesInfo
          }
        default:
          break
        }
      }
    }
    if (log != nil && log!.count > 0) {
      let pop = NSPopover()
      pop.delegate = self
      if size == .small {
        pop.contentSize = NSMakeSize(250, 100)
      } else if size == .normal {
        pop.contentSize = NSMakeSize(400, 200)
      } else if size == .big {
        pop.contentSize = NSMakeSize(650, 600)
      } else if size == .medium {
        pop.contentSize = NSMakeSize(400, 450)
      }

      pop.behavior = .transient
      pop.animates = true
      let vc = RightClickViewController().loadFromNib()
      vc.view.setFrameSize(pop.contentSize)
      let attrLog = NSMutableAttributedString(string: log!)
      attrLog.addAttributes([NSAttributedStringKey.font : NSFont(name: "Lucida Grande", size: 10.0)!],
                          range: NSMakeRange(0, attrLog.length))
      vc.textView.textStorage?.append(attrLog)
      pop.contentViewController = vc
      rowView = self.view(atColumn: 2, row: row, makeIfNecessary: false)
      return pop
    }
    NSSound.beep()
    return nil
  }
  
  private func getCPUInfo() -> String {
    var statusString : String = ""
    statusString += "   CPU:\n"
    statusString += "\tName: \(System.sysctlbynameString("machdep.cpu.brand_string"))\n"
    statusString += "\tVendor: \(System.sysctlbynameString("machdep.cpu.vendor"))\n"
    statusString += "\tPhysical cores: \(System.physicalCores())\n"
    statusString += "\tLogical cores: \(System.logicalCores())\n"
    statusString += "\tFamily: \(System.sysctlbynameInt("machdep.cpu.family"))\n"
    statusString += String(format: "\tModel: 0x%X\n", System.sysctlbynameInt("machdep.cpu.model"))
    statusString += String(format: "\tExt Model: 0x%X\n", System.sysctlbynameInt("machdep.cpu.extmodel"))
    statusString += "\tExt Family: \(System.sysctlbynameInt("machdep.cpu.extfamily"))\n"
    statusString += "\tStepping: \(System.sysctlbynameInt("machdep.cpu.stepping"))\n"
    statusString += String(format: "\tSignature: 0x%X\n", System.sysctlbynameInt("machdep.cpu.signature"))
    statusString += "\tBrand: \(System.sysctlbynameInt("machdep.cpu.brand"))\n"
    
    statusString += "\tFeatures:"
    let feature : [String] = System.sysctlbynameString("machdep.cpu.features").components(separatedBy: " ")
    var gcount : Int = 0
    var count : Int = 0
    for f in feature {
      count += 1
      gcount += 1
      if gcount < 8 {
        if gcount == 1 {
          statusString += (count == 1) ? " ": "\t               " // "\tFeatures:"
        }
        statusString += " \(f)"
      } else {
        statusString += " \(f)\n"
        gcount = 0
      }
    }
    statusString += "\n"
    statusString += "\tExt Features:"
    let extfeature : [String] = System.sysctlbynameString("machdep.cpu.extfeatures").components(separatedBy: " ")
    var egcount : Int = 0
    var ecount : Int = 0
    for f in extfeature {
      ecount += 1
      egcount += 1
      if egcount < 8 {
        if egcount == 1 {
          statusString += (ecount == 1) ? " ": "\t                     " // "\tExt Features:"
        }
        statusString += " \(f)"
      } else {
        statusString += " \(f)\n"
        egcount = 0
      }
    }
    statusString += "\n"
    statusString += "\tMicrocode version: \(System.sysctlbynameInt("machdep.cpu.microcode_version"))\n"
    statusString += "\tThermal sensors: \(System.sysctlbynameInt("machdep.cpu.thermal.sensor"))\n"
    statusString += "\tThermal invariant APIC timer: \(System.sysctlbynameInt("machdep.cpu.thermal.invariant_APIC_timer"))\n"
    
    var sys = System()
    let cpuUsage = sys.usageCPU()
    statusString += "\n\tSystem: \(Int(cpuUsage.system))%\n"
    statusString += "\tUser: \(Int(cpuUsage.user))%\n"
    statusString += "\tIdle: \(Int(cpuUsage.idle))%\n"
    statusString += "\tNice: \(Int(cpuUsage.nice))%\n"
    statusString += "\n"
    return statusString
  }
  
  private func getMemoryInfo() -> String {
    var statusString : String = ""
    statusString += "   MEMORY:\n"
    statusString += "\tPhysical size: \(System.physicalMemory())GB\n"
    
    let memoryUsage = System.memoryUsage()
    func memoryUnit(_ value: Double) -> String {
      if value < 1.0 { return String(Int(value * 1000.0))    + "MB" }
      else           { return NSString(format:"%.2f", value) as String + "GB" }
    }
    
    statusString += "\tFree: \(memoryUnit(memoryUsage.free))\n"
    statusString += "\tWired: \(memoryUnit(memoryUsage.wired))\n"
    statusString += "\tActive: \(memoryUnit(memoryUsage.active))\n"
    statusString += "\tInactive: \(memoryUnit(memoryUsage.inactive))\n"
    statusString += "\tCompressed: \(memoryUnit(memoryUsage.compressed))\n"
    statusString += "\n"
    return statusString
  }
  
  private func getSystemInfo() -> String {
    var statusString : String = ""
    statusString += "   SYSTEM:\n"
    statusString += "\tModel: \(System.modelName())\n"
    let names = System.uname()
    statusString += "\tSys name: \(names.sysname)\n"
    statusString += "\tNode name: \(names.nodename)\n"
    statusString += "\tRelease: \(names.release)\n"
    statusString += "\tVersion: \(names.version)\n"
    statusString += "\tMachine: \(names.machine)\n"
    
    let uptime = System.uptime()
    statusString += "\tUptime: \(uptime.days)d \(uptime.hrs)h \(uptime.mins)m " + "\(uptime.secs)s\n"
    
    let counts = System.processCounts()
    statusString += "\tProcesses: \(counts.processCount)\n"
    statusString += "\tThreads: \(counts.threadCount)\n"
    
    let loadAverage = System.loadAverage().map { NSString(format:"%.2f", $0) }
    statusString += "\tLoad Average: \(loadAverage)\n"
    statusString += "\tMach Factor: \(System.machFactor())\n"
    statusString += "\n"
    return statusString
  }
  
  private func getPowerInfo() -> String {
    var statusString : String = ""
    statusString += "   POWER:\n"
    let cpuThermalStatus = System.CPUPowerLimit()
    
    statusString += "\tCPU Speed limit: \(cpuThermalStatus.processorSpeed)%\n"
    statusString += "\tCPUs available: \(cpuThermalStatus.processorCount)\n"
    statusString += "\tScheduler limit: \(cpuThermalStatus.schedulerTime)%\n"
    
    statusString += "\tThermal level: \(System.thermalLevel().rawValue)\n"
    statusString += "\n"
    return statusString
  }
  
  private func getBatteryInfo() -> String {
    var statusString : String = ""
    var battery = Battery()
    if battery.open() == kIOReturnSuccess {
      statusString += "   BATTERY:\n"
      statusString += "\tAC Powered: \(battery.isACPowered())\n"
      statusString += "\tCharged: \(battery.isCharged())\n"
      statusString += "\tCharging: \(battery.isCharging())\n"
      statusString += "\tCharge: \(battery.charge())%\n"
      statusString += "\tCapacity: \(battery.currentCapacity()) mAh\n"
      statusString += "\tMax capacity: \(battery.maxCapactiy()) mAh\n"
      statusString += "\tDesign capacity: \(battery.designCapacity()) mAh\n"
      statusString += "\tCycles: \(battery.cycleCount())\n"
      statusString += "\tMax cycles: \(battery.designCycleCount())\n"
      statusString += "\tTemperature: \(battery.temperature())°C\n"
      statusString += "\tTime remaining: \(battery.timeRemainingFormatted())\n"
      statusString += "\n"
    }
    _ = battery.close()
    
    return statusString
  }
  
  private func getSystemStatus() -> String {
    var statusString : String = ""
    statusString += "MACHINE STATUS:\n\n"
    statusString += self.getCPUInfo()
    statusString += self.getMemoryInfo()
    statusString += self.getSystemInfo()
    statusString += self.getPowerInfo()
    statusString += self.getBatteryInfo()
    statusString += Display.getScreensInfo()

    return statusString
  }
}
