//
//  HWOulineView.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 24/02/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa
import SystemKit

class HWOulineView: NSOutlineView {
  
  enum InfoViewSize : Int {
    case small  = 1
    case normal = 2
    case medium = 3
    case big    = 4
  }
  
  override func menu(for event: NSEvent) -> NSMenu? {
    
    let point = self.convert(event.locationInWindow, from: nil)
    let row = self.row(at: point)
    if let item : HWTreeNode = self.item(atRow: row) as? HWTreeNode {
      self.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
      return self.menu(for: item)
    }
    
    return nil
  }
  
  private func menu(for node: HWTreeNode) -> NSMenu? {
    var menu : NSMenu? = nil

    if ((node.sensorData?.sensor?.group) != nil) {
      let g : SensorGroup = (node.sensorData?.sensor?.group)!
      
      switch g {/*
      case UInt(TemperatureSensorGroup):
      case UInt(VoltageSensorGroup):
      case UInt(TachometerSensorGroup):
      case UInt(FrequencySensorGroup):
      case UInt(MultiplierSensorGroup):*/
      case UInt(BatterySensorsGroup):
        menu = self.menuWithItem(with: NSLocalizedString("Batteries", comment: ""),
                                 text: self.getBatteryInfo(), size: InfoViewSize.normal)
      case UInt(MemorySensorGroup):
        menu = self.menuWithItem(with: NSLocalizedString("RAM", comment: ""),
                                 text: self.getMemoryInfo(), size: InfoViewSize.normal)
      case UInt(HDSmartLifeSensorGroup): fallthrough
      case UInt(HDSmartTempSensorGroup): fallthrough
        case UInt(MediaSMARTContenitorGroup):
          if let characteristics : String = node.sensorData?.sensor?.characteristics {
            menu = self.menuWithItem(with: NSLocalizedString("Media health", comment: ""),
                                     text: characteristics, size: InfoViewSize.normal)
          }
      
      default:
        break
      }
    } else {
      //we are on a parent
      if let groupString = node.sensorData?.group {
        switch groupString {
        case NSLocalizedString("CPU Temperatures", comment: ""): fallthrough
        case NSLocalizedString("CPU Frequencies", comment: ""):
          menu = self.menuWithItem(with: groupString,
                                   text: self.getCPUInfo(), size: InfoViewSize.normal)
        case NSLocalizedString("RAM", comment: ""):
          menu = self.menuWithItem(with: groupString,
                                   text: self.getMemoryInfo(), size: InfoViewSize.normal)
        case NSLocalizedString("Batteries", comment: ""):
          menu = self.menuWithItem(with: groupString,
                                   text: self.getBatteryInfo(), size: InfoViewSize.normal)
        case NSLocalizedString("Multipliers", comment: ""): fallthrough
        case NSLocalizedString("Voltages", comment: ""): fallthrough
        case NSLocalizedString("Fans or Pumps", comment: ""): fallthrough
        case NSLocalizedString("Temperatures", comment: ""):
        menu = self.menuWithItem(with: groupString,
                                 text: self.getSystemStatus(), size: InfoViewSize.big)
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
            menu = self.menuWithItem(with: NSLocalizedString("Media health", comment: ""),
                                     text: allDrivesInfo, size: InfoViewSize.medium)
          }
        default:
          break
        }
      }
    }
    if (menu == nil) {
      NSSound.beep()
    }
    return menu
  }
  
  private func menuWithItem(with title: String, text: String, size: InfoViewSize) -> NSMenu {
    let menu = NSMenu(title: title)
    let item = NSMenuItem(title: menu.title, action: nil, keyEquivalent: "")
    item.view = self.textView(with: text, size: size)
    menu.addItem(item)
    return menu
  }
  
  private func textView(with text: String, size: InfoViewSize) -> NSView {
    var rect : NSRect = NSRect(x: 0, y: 0, width: 500, height: 600)
    
    if size == .small {
      rect = NSRect(x: 0, y: 0, width: 250, height: 100)
    } else if size == .normal {
      rect = NSRect(x: 0, y: 0, width: 400, height: 200)
    } else if size == .big {
      rect = NSRect(x: 0, y: 0, width: 500, height: 600)
    } else if size == .medium {
      rect = NSRect(x: 0, y: 0, width: 400, height: 450)
    }
    
    let scroller = NSScrollView(frame: rect)
    scroller.wantsLayer = true
    scroller.borderType = .bezelBorder//.noBorder
    scroller.hasHorizontalScroller = false
    scroller.hasVerticalScroller = false
    scroller.autohidesScrollers = true
    scroller.drawsBackground = false
    
    let textStorage = NSTextStorage()
    let layoutManager = NSLayoutManager()
    textStorage.addLayoutManager(layoutManager)
    let textContainer = NSTextContainer(containerSize: rect.size)
    layoutManager.addTextContainer(textContainer)
    let textView = NSTextView(frame: rect, textContainer: textContainer)
    //textView.wantsLayer = true
    textView.drawsBackground = false
    textView.isEditable = false
    textView.isSelectable = true
    
    textStorage.append(NSAttributedString(string: text))
    scroller.documentView = textView
    scroller.contentView.copiesOnScroll = true
    textView.scrollToBeginningOfDocument(self)
    return scroller
  }
  
  private func getCPUInfo() -> String {
    var statusString : String = ""
    statusString += "-- CPU --\n"
    var size = 0
    sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
    var machine = [CChar](repeating: 0,  count: Int(size))
    sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
    statusString += "\tNAME:  \(String(cString: machine))\n"
    
    statusString += "\tPHYSICAL CORES:  \(System.physicalCores())\n"
    statusString += "\tLOGICAL CORES:   \(System.logicalCores())\n"
    
    var sys = System()
    let cpuUsage = sys.usageCPU()
    statusString += "\tSYSTEM: \(Int(cpuUsage.system))%\n"
    statusString += "\tUSER: \(Int(cpuUsage.user))%\n"
    statusString += "\tIDLE: \(Int(cpuUsage.idle))%\n"
    statusString += "\tNICE: \(Int(cpuUsage.nice))%\n"
    statusString += "\n"
    return statusString
  }
  
  private func getMemoryInfo() -> String {
    var statusString : String = ""
    statusString += "-- MEMORY --\n"
    statusString += "\tPHYSICAL SIZE: \(System.physicalMemory())GB\n"
    
    let memoryUsage = System.memoryUsage()
    func memoryUnit(_ value: Double) -> String {
      if value < 1.0 { return String(Int(value * 1000.0))    + "MB" }
      else           { return NSString(format:"%.2f", value) as String + "GB" }
    }
    
    statusString += "\tFREE: \(memoryUnit(memoryUsage.free))\n"
    statusString += "\tWIRED: \(memoryUnit(memoryUsage.wired))\n"
    statusString += "\tACTIVE: \(memoryUnit(memoryUsage.active))\n"
    statusString += "\tINACTIVE: \(memoryUnit(memoryUsage.inactive))\n"
    statusString += "\tCOMPRESSED: \(memoryUnit(memoryUsage.compressed))\n"
    statusString += "\n"
    return statusString
  }
  
  private func getSystemInfo() -> String {
    var statusString : String = ""
    statusString += "-- SYSTEM --\n"
    statusString += "\tMODEL: \(System.modelName())\n"
    
    /* to be finished
     let names = System.uname()
     statusString += "\tSYSNAME:         \(names.sysname)\n"
     statusString += "\tNODENAME:        \(names.nodename)\n"
     statusString += "\tRELEASE:         \(names.release)\n"
     statusString += "\tVERSION:         \(names.version)\n"
     statusString += "\tMACHINE:         \(names.machine)\n"
     */
    let uptime = System.uptime()
    statusString += "\tUPTIME: \(uptime.days)d \(uptime.hrs)h \(uptime.mins)m " + "\(uptime.secs)s\n"
    
    let counts = System.processCounts()
    statusString += "\tPROCESSES: \(counts.processCount)\n"
    statusString += "\tTHREADS: \(counts.threadCount)\n"
    
    let loadAverage = System.loadAverage().map { NSString(format:"%.2f", $0) }
    statusString += "\tLOAD AVERAGE: \(loadAverage)\n"
    statusString += "\tMACH FACTOR: \(System.machFactor())\n"
    statusString += "\n"
    return statusString
  }
  
  private func getPowerInfo() -> String {
    var statusString : String = ""
    statusString += "-- POWER --\n"
    let cpuThermalStatus = System.CPUPowerLimit()
    
    statusString += "\tCPU SPEED LIMIT: \(cpuThermalStatus.processorSpeed)%\n"
    statusString += "\tCPUs AVAILABLE: \(cpuThermalStatus.processorCount)\n"
    statusString += "\tSCHEDULER LIMIT: \(cpuThermalStatus.schedulerTime)%\n"
    
    statusString += "\tTHERMAL LEVEL: \(System.thermalLevel().rawValue)\n"
    statusString += "\n"
    return statusString
  }
  
  private func getBatteryInfo() -> String {
    var statusString : String = ""
    var battery = Battery()
    if battery.open() == kIOReturnSuccess {
      statusString += "-- BATTERY --\n"
      statusString += "\tAC POWERED: \(battery.isACPowered())\n"
      statusString += "\tCHARGED: \(battery.isCharged())\n"
      statusString += "\tCHARGING: \(battery.isCharging())\n"
      statusString += "\tCHARGE: \(battery.charge())%\n"
      statusString += "\tCAPACITY: \(battery.currentCapacity()) mAh\n"
      statusString += "\tMAX CAPACITY: \(battery.maxCapactiy()) mAh\n"
      statusString += "\tDESGIN CAPACITY: \(battery.designCapacity()) mAh\n"
      statusString += "\tCYCLES: \(battery.cycleCount())\n"
      statusString += "\tMAX CYCLES: \(battery.designCycleCount())\n"
      statusString += "\tTEMPERATURE: \(battery.temperature())°C\n"
      statusString += "\tTIME REMAINING: \(battery.timeRemainingFormatted())\n"
      statusString += "\n"
    }
    _ = battery.close()
    
    return statusString
  }
  private func getSystemStatus() -> String {
    var statusString : String = ""
    statusString += "MACHINE STATUS\n"
    statusString += self.getCPUInfo()
    statusString += self.getMemoryInfo()
    statusString += self.getSystemInfo()
    statusString += self.getPowerInfo()
    statusString += self.getBatteryInfo()

    return statusString
  }
}
