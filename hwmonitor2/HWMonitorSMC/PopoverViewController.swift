//
//  PopoverViewController.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 26/02/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

class PopoverViewController: NSViewController {
  @IBOutlet var outline         : HWOulineView!
  @IBOutlet var lock            : NSButton!
  @IBOutlet var attachButton    : NSButton!
  @IBOutlet var versionLabel    : NSTextField!
  @IBOutlet var effectView      : NSVisualEffectView!
  
  var preferenceWC              : PreferencesWC?
  
  var initiated                 : Bool = false
  var lastSpartUpdate           : Date?
  var sensorDelegate            : HWSensorsDelegate?
  
  var dataSource                : NSMutableArray?
  var sensorList                : NSMutableArray?
  
  var expandCPUTemperature      : Bool = false
  var expandVoltages            : Bool = false
  var expandCPUFrequencies      : Bool = false
  var expandAll                 : Bool = false
  var dontshowEmpty             : Bool = true
  
  // nodes
  var RAMNode                   : HWTreeNode?
  var CPUFrequenciesNode        : HWTreeNode?
  var voltagesNode              : HWTreeNode?
  var CPUTemperaturesNode       : HWTreeNode?
  var multipliersNode           : HWTreeNode?
  var allOtherTemperaturesNode  : HWTreeNode?
  var allOtherFrequenciesNode   : HWTreeNode?
  var fansNode                  : HWTreeNode?
  var mediaNode                 : HWTreeNode?
  var batteriesNode             : HWTreeNode?
  
  var smartBeginDate            : Date?
  var forceSmarScan             : Bool = false
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let pin = NSImage(named: NSImage.Name(rawValue: "pin"))
    pin?.isTemplate = true
    self.attachButton.image = pin
    self.effectView.appearance = NSAppearance(named: gAppearance)
    if let version = Bundle.main.infoDictionary?["CFBundleVersion"]  as? String {
      self.versionLabel.stringValue = "HWMonitorSMC v" + version + " rc1"
    }
    
    self.lock.state = NSControl.StateValue.off
    
    self.outline.delegate = self
    self.outline.dataSource = self
    self.outline.doubleAction = #selector(self.clicked)
    
    self.initialize()
  }
  
  override func awakeFromNib() {
    
  }
  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }
  
  func loadPreferences() {
    let ud = UserDefaults.standard
    if (ud.object(forKey: kExpandCPUTemperature) != nil) {
      self.expandCPUTemperature = ud.bool(forKey: kExpandCPUTemperature)
    } else {
      self.expandCPUTemperature = true
      ud.set(true, forKey: kExpandCPUTemperature)
    }
    
    if (ud.object(forKey: kExpandVoltages) != nil) {
      self.expandVoltages = ud.bool(forKey: kExpandVoltages)
    } else {
      self.expandVoltages = false
      ud.set(false, forKey: kExpandVoltages)
    }
    
    if (ud.object(forKey: kExpandCPUFrequencies) != nil) {
      self.expandCPUFrequencies = ud.bool(forKey: kExpandCPUFrequencies)
    } else {
      self.expandCPUFrequencies = true
      ud.set(true, forKey: kExpandCPUFrequencies)
    }
    
    if (ud.object(forKey: kExpandAll) != nil) {
      self.expandAll = ud.bool(forKey: kExpandAll)
    } else {
      self.expandAll = false
      ud.set(false, forKey: kExpandAll)
    }
    
    if (ud.object(forKey: kDontShowEmpty) != nil) {
      self.dontshowEmpty = ud.bool(forKey: kDontShowEmpty)
    } else {
      self.dontshowEmpty = true
      ud.set(true, forKey: kDontShowEmpty)
    }
    ud.synchronize()
  }
  
  @IBAction func closeApp(sender : NSButton) {
    NSApp.terminate(self)
  }
  
  @IBAction func reattachPopover(_ sender: NSButton) {
    let shared = NSApplication.shared.delegate as! AppDelegate
    if let button = shared.statusItem.button {
      button.performClick(button)
    }
  }
  
  @IBAction func showPreferences(sender : NSButton) {
    if (self.preferenceWC == nil) {
      self.preferenceWC = PreferencesWC.loadFromNib()
    }
    self.preferenceWC?.showWindow(self)
  }
  
  func initialize() {
    var timeInterval : TimeInterval = 3
    if (UserDefaults.standard.object(forKey: kSensorsTimeInterval) != nil) {
      timeInterval = UserDefaults.standard.double(forKey: kSensorsTimeInterval)
      if timeInterval < 3 {
        timeInterval = 3
      }
    }
    
    loadPreferences()
    self.sensorList = NSMutableArray()
    self.dataSource = NSMutableArray()
    self.sensorDelegate = HWSensorsDelegate()
    
    // ------
    
    self.CPUFrequenciesNode = HWTreeNode(representedObject: HWSensorData(group: NSLocalizedString("CPU Frequencies", comment: ""),
                                                                         sensor: nil,
                                                                         isLeaf: false))
    for s in (self.sensorDelegate?.getCPUFrequencies())! {
      let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.CPUFrequenciesNode?.sensorData?.group)!,
                                                              sensor: s as? HWMonitorSensor,
                                                              isLeaf: true))
      self.CPUFrequenciesNode?.mutableChildren.add(sensor)
    }
    
    if (self.CPUFrequenciesNode?.children?.count)! > 0 {
      self.sensorList?.addObjects(from: (self.CPUFrequenciesNode?.children)!)
      self.dataSource?.add(self.CPUFrequenciesNode!)
    } else {
      if self.dontshowEmpty {
        self.CPUFrequenciesNode = nil
      } else {
        self.dataSource?.add(self.CPUFrequenciesNode!)
      }
    }
    // ------
    self.CPUTemperaturesNode = HWTreeNode(representedObject: HWSensorData(group: NSLocalizedString("CPU Temperatures", comment: ""),
                                                                          sensor: nil,
                                                                          isLeaf: false))
    for s in (self.sensorDelegate?.getCPUTemperatures())! {
      let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.CPUTemperaturesNode?.sensorData?.group)!,
                                                              sensor: s as? HWMonitorSensor,
                                                              isLeaf: true))
      self.CPUTemperaturesNode?.mutableChildren.add(sensor)
    }
    if (self.CPUTemperaturesNode?.children?.count)! > 0 {
      self.sensorList?.addObjects(from: (self.CPUTemperaturesNode?.children)!)
      self.dataSource?.add(self.CPUTemperaturesNode!)
    } else {
      if self.dontshowEmpty {
        self.CPUTemperaturesNode = nil
      } else {
        self.dataSource?.add(self.CPUTemperaturesNode!)
      }
    }
    // ------
    self.voltagesNode = HWTreeNode(representedObject: HWSensorData(group: NSLocalizedString("Voltages", comment: ""),
                                                                   sensor: nil,
                                                                   isLeaf: false))
    for s in (self.sensorDelegate?.getVoltages())! {
      let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.voltagesNode?.sensorData?.group)!,
                                                              sensor: s as? HWMonitorSensor,
                                                              isLeaf: true))
      self.voltagesNode?.mutableChildren.add(sensor)
    }
    if (self.voltagesNode?.children?.count)! > 0 {
      self.sensorList?.addObjects(from: (self.voltagesNode?.children)!)
      self.dataSource?.add(self.voltagesNode!)
    } else {
      if self.dontshowEmpty {
        self.voltagesNode = nil
      } else {
        self.dataSource?.add(self.voltagesNode!)
      }
    }
    // ------
    self.multipliersNode =  HWTreeNode(representedObject: HWSensorData(group: NSLocalizedString("Multipliers", comment: ""),
                                                                       sensor: nil,
                                                                       isLeaf: false))
    for s in (self.sensorDelegate?.getMultipliers())! {
      let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.multipliersNode?.sensorData?.group)!,
                                                              sensor: s as? HWMonitorSensor,
                                                              isLeaf: true))
      self.multipliersNode?.mutableChildren.add(sensor)
    }
    if (self.multipliersNode?.children?.count)! > 0 {
      self.sensorList?.addObjects(from: (self.multipliersNode?.children)!)
      self.dataSource?.add(self.multipliersNode!)
    } else {
      if self.dontshowEmpty {
        self.multipliersNode = nil
      } else {
        self.dataSource?.add(self.multipliersNode!)
      }
    }
    // ------
    self.RAMNode = HWTreeNode(representedObject: HWSensorData(group: NSLocalizedString("RAM", comment: ""),
                                                              sensor: nil,
                                                              isLeaf: false))
    for s in (self.sensorDelegate?.getMemory())! {
      let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.RAMNode?.sensorData?.group)!,
                                                              sensor: s as? HWMonitorSensor,
                                                              isLeaf: true))
      self.RAMNode?.mutableChildren.add(sensor)
    }
    
    if (self.RAMNode?.children?.count)! > 0 {
      self.sensorList?.addObjects(from: (self.RAMNode?.children)!)
      self.dataSource?.add(self.RAMNode!)
    } else {
      if self.dontshowEmpty {
        self.RAMNode = nil
      } else {
        self.dataSource?.add(self.RAMNode!)
      }
    }
    // ------
    self.allOtherTemperaturesNode =  HWTreeNode(representedObject: HWSensorData(group: NSLocalizedString("Temperatures", comment: ""),
                                                                                sensor: nil,
                                                                                isLeaf: false))
    for s in (self.sensorDelegate?.getAllOtherTemperatures())! {
      let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.allOtherTemperaturesNode?.sensorData?.group)!,
                                                              sensor: s as? HWMonitorSensor,
                                                              isLeaf: true))
      self.allOtherTemperaturesNode?.mutableChildren.add(sensor)
    }
    if (self.allOtherTemperaturesNode?.children?.count)! > 0 {
      self.sensorList?.addObjects(from: (self.allOtherTemperaturesNode?.children)!)
      self.dataSource?.add(self.allOtherTemperaturesNode!)
    } else {
      if self.dontshowEmpty {
        self.allOtherTemperaturesNode = nil
      } else {
        self.dataSource?.add(self.allOtherTemperaturesNode!)
      }
    }
    // ------
    self.allOtherFrequenciesNode =  HWTreeNode(representedObject: HWSensorData(group: NSLocalizedString("Frequencies", comment: ""),
                                                                               sensor: nil,
                                                                               isLeaf: false))
    for s in (self.sensorDelegate?.getOtherFrequencies())! {
      let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.allOtherFrequenciesNode?.sensorData?.group)!,
                                                              sensor: s as? HWMonitorSensor,
                                                              isLeaf: true))
      self.allOtherFrequenciesNode?.mutableChildren.add(sensor)
    }
    if (self.allOtherFrequenciesNode?.children?.count)! > 0 {
      self.sensorList?.addObjects(from: (self.allOtherFrequenciesNode?.children)!)
      self.dataSource?.add(self.allOtherFrequenciesNode!)
    } else {
      if self.dontshowEmpty {
        self.allOtherFrequenciesNode = nil
      } else {
        self.dataSource?.add(self.allOtherFrequenciesNode!)
      }
    }
    // ------
    self.fansNode =  HWTreeNode(representedObject: HWSensorData(group: NSLocalizedString("Fans or Pumps", comment: ""),
                                                                sensor: nil,
                                                                isLeaf: false))
    for s in (self.sensorDelegate?.getFans())! {
      let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.fansNode?.sensorData?.group)!,
                                                              sensor: s as? HWMonitorSensor,
                                                              isLeaf: true))
      self.fansNode?.mutableChildren.add(sensor)
    }
    if (self.fansNode?.children?.count)! > 0 {
      self.sensorList?.addObjects(from: (self.fansNode?.children)!)
      self.dataSource?.add(self.fansNode!)
    } else {
      if self.dontshowEmpty {
        self.fansNode = nil
      } else {
        self.dataSource?.add(self.fansNode!)
      }
    }
    // ------
    self.mediaNode =  HWTreeNode(representedObject: HWSensorData(group: NSLocalizedString("Media health", comment: ""),
                                                                sensor: nil,
                                                                isLeaf: false))

    self.smartBeginDate = Date()
    let smartscanner = HWSmartDataScanner()
    for d in smartscanner.getSmartCapableDisks() {
      var log : String = ""
      var productName : String = ""
      var serial : String = ""
      
      let list = smartscanner.getSensors(from: d, characteristics: &log, productName: &productName, serial: &serial)
      let smartSensorParent = HWMonitorSensor(key: productName,
                                              andType: "",
                                              andGroup: UInt(MediaSMARTContenitorGroup),
                                              withCaption: serial)
      let smartSensorParentNode = HWTreeNode(representedObject: HWSensorData(group: productName,
                                                                             sensor: smartSensorParent,
                                                                             isLeaf: false))
      for s in list {
        let snode = HWTreeNode(representedObject: HWSensorData(group: (smartSensorParentNode.sensorData?.group)!,
                                                              sensor: s,
                                                              isLeaf: true))
        s.characteristics = log
        smartSensorParent?.characteristics = log
        smartSensorParentNode.mutableChildren.add(snode)
        self.sensorList?.add(snode)
      }
      self.mediaNode?.mutableChildren.add(smartSensorParentNode)
    }
    addObservers()
    //----------------------
    if (self.mediaNode?.children?.count)! > 0 {
      self.sensorList?.addObjects(from: (self.mediaNode?.children)!)
      self.dataSource?.add(self.mediaNode!)
    } else {
      if self.dontshowEmpty {
        self.mediaNode = nil
      } else {
        self.dataSource?.add(self.mediaNode!)
      }
    }
    // ------
    self.batteriesNode =  HWTreeNode(representedObject: HWSensorData(group: NSLocalizedString("Batteries", comment: ""),
                                                                     sensor: nil,
                                                                     isLeaf: false))
    for s in (self.sensorDelegate?.getBattery())! {
      let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.batteriesNode?.sensorData?.group)!,
                                                              sensor: s as? HWMonitorSensor,
                                                              isLeaf: true))
      self.batteriesNode?.mutableChildren.add(sensor)
    }
    
    for s in (self.sensorDelegate?.getGenericBatteries())! {
      let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.batteriesNode?.sensorData?.group)!,
                                                              sensor: s as? HWMonitorSensor,
                                                              isLeaf: true))
      self.batteriesNode?.mutableChildren.add(sensor)
    }
    
    if (self.batteriesNode?.children?.count)! > 0 {
      self.sensorList?.addObjects(from: (self.batteriesNode?.children)!)
      self.dataSource?.add(self.batteriesNode!)
    } else {
      if self.dontshowEmpty {
        self.batteriesNode = nil
      } else {
        self.dataSource?.add(self.batteriesNode!)
      }
    }
    // ------
    
    self.initiated = true
    self.outline.reloadData()
    
    
    if (self.CPUFrequenciesNode != nil) && (self.expandCPUFrequencies || self.expandAll) {
      self.outline.expandItem(self.CPUFrequenciesNode)
    }
    
    if (self.voltagesNode != nil) && (self.expandCPUFrequencies || self.expandVoltages) {
      self.outline.expandItem(self.voltagesNode)
    }
    
    if (self.CPUTemperaturesNode != nil) && (self.expandCPUTemperature || self.expandAll) {
      self.outline.expandItem(self.CPUTemperaturesNode)
    }
    
    if self.expandAll {
      if (self.RAMNode != nil) {
        self.outline.expandItem(self.RAMNode)
      }
      if (self.multipliersNode != nil) {
        self.outline.expandItem(self.multipliersNode)
      }
      if (self.allOtherFrequenciesNode != nil) {
        self.outline.expandItem(self.allOtherFrequenciesNode)
      }
      if (self.allOtherTemperaturesNode != nil) {
        self.outline.expandItem(self.allOtherTemperaturesNode)
      }
      if (self.fansNode != nil) {
        self.outline.expandItem(self.fansNode)
      }
      if (self.mediaNode != nil) {
        self.outline.expandItem(self.mediaNode)
        for i in (self.mediaNode?.children)! {
          self.outline.expandItem(i)
        }
      }
      if (self.batteriesNode != nil) {
        self.outline.expandItem(self.batteriesNode)
      }
    }
    self.updateTitles()
    Timer.scheduledTimer(timeInterval: timeInterval,
                         target: self,
                         selector: #selector(self.updateTitles),
                         userInfo: nil,
                         repeats: true)
  }
  
  @objc func updateTitles() {
    if self.initiated {
      var found : Bool = false
      let statusString : NSMutableString = NSMutableString()
      let copy : NSArray = self.sensorList?.copy() as! NSArray
      
      
      let newMemRead : [HWMonitorSensor] = self.sensorDelegate?.getMemory() as! [HWMonitorSensor]
      let newGenericBatteries : [HWMonitorSensor] = self.sensorDelegate?.getGenericBatteries() as! [HWMonitorSensor]
      let newBattery : [HWMonitorSensor] = self.sensorDelegate?.getBattery() as! [HWMonitorSensor]
      
      
      let elapsed = Date().timeIntervalSince(self.smartBeginDate!)
      var newMediaNode : HWTreeNode
      let interval : TimeInterval = 600 // scan S.M.A.R.T. each 10 minutes
      if self.forceSmarScan || elapsed >= interval {
        self.forceSmarScan = false
        newMediaNode  = HWTreeNode(representedObject: HWSensorData(group: (self.mediaNode?.sensorData?.group)!,
                                                                   sensor: nil,
                                                                   isLeaf: false))
        
        let smartscanner = HWSmartDataScanner()
        for d in smartscanner.getSmartCapableDisks() {
          var log : String = ""
          var productName : String = ""
          var serial : String = ""
          
          let list = smartscanner.getSensors(from: d, characteristics: &log, productName: &productName, serial: &serial)
          let smartSensorParent = HWMonitorSensor(key: productName,
                                                  andType: "",
                                                  andGroup: UInt(MediaSMARTContenitorGroup),
                                                  withCaption: serial)
          let smartSensorParentNode = HWTreeNode(representedObject: HWSensorData(group: productName,
                                                                                 sensor: smartSensorParent,
                                                                                 isLeaf: false))
          for s in list {
            let snode = HWTreeNode(representedObject: HWSensorData(group: (smartSensorParentNode.sensorData?.group)!,
                                                                   sensor: s,
                                                                   isLeaf: true))
            s.characteristics = log
            smartSensorParent?.characteristics = log
            smartSensorParentNode.mutableChildren.add(snode)
          }
          newMediaNode.mutableChildren.add(smartSensorParentNode)
        }
        self.smartBeginDate = Date()
      } else {
        newMediaNode = self.mediaNode!
      }
      
      
      for i in copy {
        let node = i as! HWTreeNode
        let sensor = node.sensorData?.sensor
        let group = node.sensorData?.sensor?.group
        
        var value : String = "-"
        // Battery sensor are fake, re read it
        switch group {
        case UInt(HDSmartLifeSensorGroup)?:
          found = false
          for disk in newMediaNode.children! {
            let productNameNode : HWTreeNode = disk as! HWTreeNode
            var same = false
            for n in productNameNode.children! {
              let ln : HWTreeNode = n as! HWTreeNode
              if ln.sensorData?.sensor?.group == group && (ln.sensorData?.sensor?.caption)! == sensor?.caption {
                sensor?.stringValue = ln.sensorData?.sensor?.stringValue
                value = (ln.sensorData?.sensor?.stringValue)! + "%"
                same = true
                break
              }
            }
            if same {
              found = same
              break
            }
          }
          break
        case UInt(HDSmartTempSensorGroup)?:
          found = false
          for disk in newMediaNode.children! {
            let productNameNode : HWTreeNode = disk as! HWTreeNode
            var same = false
            for n in productNameNode.children! {
              let tn : HWTreeNode = n as! HWTreeNode
              if tn.sensorData?.sensor?.group == group && (tn.sensorData?.sensor?.caption)! == sensor?.caption {
                sensor?.stringValue = tn.sensorData?.sensor?.stringValue
                value = (tn.sensorData?.sensor?.stringValue)! + "°"
                same = true
                break
              }
            }
            if same {
              found = same
              break
            }
          }
          break
        case UInt(MediaSMARTContenitorGroup)?:
          found = false
          var before : [String] = [String]()
          var after  : [String] = [String]()
          for disk in (self.mediaNode?.children)! {
            let productNameNode : HWTreeNode = disk as! HWTreeNode
            let modelAndSerial : String = (productNameNode.sensorData?.sensor?.key)! + (productNameNode.sensorData?.sensor?.caption)!
            before.append(modelAndSerial)
          }
          for disk in newMediaNode.children! {
            let productNameNode : HWTreeNode = disk as! HWTreeNode
            let modelAndSerial : String = (productNameNode.sensorData?.sensor?.key)! + (productNameNode.sensorData?.sensor?.caption)!
            after.append(modelAndSerial)
          }
          
          if before != after {
            // clean old sensors
            for n in (self.mediaNode?.mutableChildren)! {
              /* self.mediaNode contains sub groups named with the model of the drive
               each drive contains life and temperature sensors that must be removed from self.sensorList
              */
              let driveNode : HWTreeNode = n as! HWTreeNode
              for sub in driveNode.children! {
                self.sensorList?.remove(sub)
              }
              self.mediaNode?.mutableChildren.remove(n)
            }
            // add new sensors with a new read
            self.mediaNode?.mutableChildren.addObjects(from: newMediaNode.children!)
            for n in newMediaNode.children! {
              /* newMediaNode contains sub groups named with the model of the drive
               each drive contains life and temperature sensors that must be re added to self.sensorList
               */
              let driveNode : HWTreeNode = n as! HWTreeNode
              for sub in driveNode.children! {
                self.sensorList?.add(sub)
              }
            }
            self.outline.reloadItem(self.mediaNode, reloadChildren: true)
          }
          break
        case UInt(MemorySensorGroup)?:
          found = false
          for newSensor in newMemRead {
            if newSensor.caption == sensor?.caption {
              value = newSensor.stringValue
              sensor?.stringValue = newSensor.stringValue
              found = true
              break
            }
          }
          break
        case UInt(BatterySensorsGroup)?:
          found = false
          for newSensor in newBattery {
            if newSensor.caption == sensor?.caption {
              sensor?.stringValue = newSensor.stringValue
              value = newSensor.stringValue + (newSensor.key == "B0AV" ? "mV" : "mA")
              found = true
              break
            }
          }
          break
        case UInt(GenericBatterySensorsGroup)?:
          var new : [HWTreeNode] = [HWTreeNode]()
          found = false
          for newSensor in newGenericBatteries {
            if newSensor.caption == sensor?.caption {
              if let data = HWMonitorSensor.readValue(forKey: sensor?.key) {
                value = newSensor.formatedValue(data)
              }
              found = true
            } else {
              // this is a new battery
              if (self.batteriesNode != nil) {
                self.batteriesNode =  HWTreeNode(representedObject: HWSensorData(group: NSLocalizedString("Batteries", comment: ""),
                                                                                 sensor: nil,
                                                                                 isLeaf: false))
              }
              
              let newNode = HWTreeNode(representedObject: HWSensorData(group: (self.batteriesNode?.sensorData?.group)!,
                                                                       sensor: newSensor,
                                                                       isLeaf: true))
              new.append(newNode)
            }
          }
          
          // deleting old battery sensor no longer available
          if !found {
            if (self.sensorList?.contains(node))! {
              self.sensorList?.remove(node)
              if (self.batteriesNode?.mutableChildren.contains(node))! {
                let index : Int = (self.batteriesNode?.mutableChildren.index(of: node))!
                self.batteriesNode?.mutableChildren.remove(node)
                self.outline.removeItems(at: IndexSet(integer:index), inParent: self.batteriesNode, withAnimation: .effectFade)
              }
            }
          }
          // we have a new sensors..adding them
          if new.count > 0 {
            for newSensor in new {
              self.batteriesNode?.mutableChildren.add(newSensor)
              self.sensorList?.add(newSensor)
              break
            }
            self.outline.reloadItem(self.batteriesNode, reloadChildren: true)
          }
          break
        default:
          found = true
          if let data = HWMonitorSensor.readValue(forKey: sensor?.key) {
            value = (sensor?.formatedValue(data)!)!
          }
          break
        }
        
        if found {
          if (sensor?.favorite)! {
            statusString.append(" ")
            statusString.append(value)
          }
          //ensure the node is visible before reload its view (no sense otherwise)
          let nodeIndex = self.outline.row(forItem: node)
          if self.outline.isItemExpanded(node.parent) && (nodeIndex >= 0) {
            self.outline.reloadData(forRowIndexes: IndexSet(integer: nodeIndex), columnIndexes: IndexSet(integer: 2))
          }
        }
      }
   
      let style = NSMutableParagraphStyle()
      style.lineSpacing = 0
      let title = NSMutableAttributedString(string: statusString as String, attributes: [NSAttributedStringKey.paragraphStyle : style])
      
      title.addAttributes([NSAttributedStringKey.font : NSFont(name: "Lucida Grande Bold", size: 9.0)!],
                          range: NSMakeRange(0, title.length))
      let shared = NSApplication.shared.delegate as! AppDelegate
      shared.statusItem.attributedTitle = title
      
    }
  }
}

extension PopoverViewController: NSOutlineViewDelegate {
  func outlineViewSelectionDidChange(_ notification: Notification) {
    
  }
  
  func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
    let rowView = HWTableRowView()
    rowView.isEmphasized = true
    return rowView
  }
  
  @objc func clicked() {
    let selected = self.outline.clickedRow
    if selected >= 0 {
      if let node : HWTreeNode = self.outline.item(atRow: selected) as? HWTreeNode {
        if (node.sensorData?.isLeaf)! {
          let view : NSTableCellView = self.outline.view(atColumn: 0,
                                                         row: selected,
                                                         makeIfNecessary: false /* mind that is already visible */) as! NSTableCellView
          let sensor = node.sensorData?.sensor
          if (sensor?.favorite)! {
            sensor?.favorite = false
            view.imageView?.image = nil
          } else {
            sensor?.favorite = true
            let image = NSImage(named: NSImage.Name(rawValue: "checkbox"))
            image?.isTemplate = true
            view.imageView?.image = image
          }
          UserDefaults.standard.set(sensor?.favorite, forKey: (sensor?.key)!)
          UserDefaults.standard.synchronize()
          self.updateTitles()
        } else {
          if self.outline.isItemExpanded(node) {
            self.outline.collapseItem(node)
          } else {
            self.outline.expandItem(node)
          }
        }
        
      }
    }
  }
  
}

extension PopoverViewController: NSOutlineViewDataSource {
  
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    if let node = item as? HWTreeNode {
      if !(node.sensorData?.isLeaf)! {
        return true
      }
    }
    return false
  }
  
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    if !self.initiated {
      return 0
    }
    if (item == nil) {
      return (self.dataSource?.count)!
    } else {
      return ((item as! HWTreeNode).children?.count)!
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView,
                   child index: Int,
                   ofItem item: Any?) -> Any {
    if item != nil {
      return (item as! HWTreeNode).children![index]
    }
    else
    {
      return self.dataSource?.object(at: index) as Any
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView,
                   viewFor tableColumn: NSTableColumn?,
                   item: Any) -> NSView? {
    var view : NSTableCellView? = nil
    
    if let node : HWTreeNode = item as? HWTreeNode {
      let isGroup : Bool = !(node.sensorData?.isLeaf)!
      if (tableColumn != nil) {
        view = outlineView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView
        switch tableColumn!.identifier.rawValue {
        case "column0":
          view?.imageView?.image = getImageFor(node: node)
          break
        case "column1":
          if isGroup {
            view?.textField?.stringValue = (node.sensorData?.group)!
            view?.textField?.textColor = (gAppearance == NSAppearance.Name.vibrantDark) ? NSColor.green : NSColor.controlTextColor
          } else {
            if node.sensorData?.sensor?.group == UInt(HDSmartLifeSensorGroup) {
              view?.textField?.stringValue = NSLocalizedString("Life", comment: "")
            } else if node.sensorData?.sensor?.group == UInt(HDSmartTempSensorGroup) {
              view?.textField?.stringValue = NSLocalizedString("Tеmperature", comment: "")
            } else {
              view?.textField?.stringValue = (node.sensorData?.sensor?.caption)!
            }
            view?.textField?.textColor = NSColor.controlTextColor
          }
          break
        case "column2":
          if isGroup {
            view?.textField?.stringValue = ""
          } else {
            let group : SensorGroup = (node.sensorData?.sensor?.group)!
            var value : String = "-"
            switch group {
            case UInt(MemorySensorGroup):
              value = (node.sensorData?.sensor?.stringValue)!
              break
            case UInt(HDSmartLifeSensorGroup):
              value = (node.sensorData?.sensor?.stringValue)! + "%"
              break
            case UInt(HDSmartTempSensorGroup):
              value = (node.sensorData?.sensor?.stringValue)! + "°"
              break
            case UInt(BatterySensorsGroup):
              value = (node.sensorData?.sensor?.stringValue)! + ((node.sensorData?.sensor?.key)! == "B0AV" ? "mV" : "mA")
              break
            default:
              if let data = HWMonitorSensor.readValue(forKey: node.sensorData?.sensor?.key) {
                value = (node.sensorData?.sensor?.formatedValue(data))!
              }
            }
            view?.textField?.stringValue = value
          }
          break
        default:
          view = nil
          break
        }
      }
    }
    return view
  }
  
  func getImageFor(node: HWTreeNode) -> NSImage? {
    var image : NSImage? = nil
    let group : String = (node.sensorData?.group)!
    
    if (node.sensorData?.isLeaf)! {
      if (node.sensorData?.sensor?.favorite)! {
        image = NSImage(named: NSImage.Name(rawValue: "checkbox"))
        image?.isTemplate = true
        return image
      }
    } else {
      switch group {
      case NSLocalizedString("RAM", comment: ""):
        image = NSImage(named: NSImage.Name(rawValue: "ram_small"))
        break
      case NSLocalizedString("CPU Temperatures", comment: ""):
        image = NSImage(named: NSImage.Name(rawValue: "cpu_temp_small"))
        break
      case NSLocalizedString("CPU Frequencies", comment: ""):
        image = NSImage(named: NSImage.Name(rawValue: "cpu_freq_small"))
        break
      case NSLocalizedString("Temperatures", comment: ""):
        image = NSImage(named: NSImage.Name(rawValue: "temp_alt_small"))
        break
      case NSLocalizedString("Fans or Pumps", comment: ""):
        image = NSImage(named: NSImage.Name(rawValue: "fan_small"))
        break
      case NSLocalizedString("Frequencies", comment: ""):
        image = NSImage(named: NSImage.Name(rawValue: "freq_small"))
        break
      case NSLocalizedString("Multipliers", comment: ""):
        image = NSImage(named: NSImage.Name(rawValue: "multiply_small"))
        break
      case NSLocalizedString("Voltages", comment: ""):
        image = NSImage(named: NSImage.Name(rawValue: "voltage_small"))
        break
      case NSLocalizedString("Batteries", comment: ""):
        image = NSImage(named: NSImage.Name(rawValue: "modern-battery-icon"))
        break
      case NSLocalizedString("Media health", comment: ""):
        image = NSImage(named: NSImage.Name(rawValue: "hd_small.png"))
        break
      default:
        break
      }
    }
    image?.isTemplate = true
    return image
  }
}

extension PopoverViewController {
  override func mouseDragged(with theEvent: NSEvent) {
    let shared = NSApplication.shared.delegate as! AppDelegate
    if let popover = (shared.hwWC?.contentViewController as! HWViewController).popover {
      let mouseLocation = NSEvent.mouseLocation
      
      var newLocation   = mouseLocation
      let frame = NSScreen.main?.frame
      newLocation.x     = frame!.size.width - mouseLocation.x
      newLocation.y     = frame!.size.height - mouseLocation.y
      if newLocation.x < 310 {
        newLocation.x = 310
      }
      
      if newLocation.y < 270 {
        newLocation.y = 270
      }
      popover.contentSize = NSSize(width: newLocation.x, height: newLocation.y)
      UserDefaults.standard.set(newLocation.x, forKey: kPopoverWidth)
      UserDefaults.standard.set(newLocation.y, forKey: kPopoverHeight)
      UserDefaults.standard.synchronize()
    }
  }
}

extension PopoverViewController {
  /*
   we need to rescan disks when the System awake (because the user can have removed some of it),
   or just when a disk is ejected or plugged.
   */
  func addObservers() {
    NSWorkspace.shared.notificationCenter.addObserver(self,
                                                      selector: #selector(self.diskMounted),
                                                      name: NSWorkspace.didMountNotification,
                                                      object: nil)
    
    NSWorkspace.shared.notificationCenter.addObserver(self,
                                                      selector: #selector(self.diskUmounted),
                                                      name: NSWorkspace.didUnmountNotification,
                                                      object: nil)
    
    NSWorkspace.shared.notificationCenter.addObserver(self,
                                                      selector: #selector(self.wakeListener),
                                                      name: NSWorkspace.didWakeNotification,
                                                      object: nil)
    
    NSWorkspace.shared.notificationCenter.addObserver(self,
                                                      selector: #selector(self.powerOffListener),
                                                      name: NSWorkspace.willPowerOffNotification,
                                                      object: nil)
  }
  
  func removeObservers() {
    if #available(OSX 10.12, *) {
      //print("do need to remove the observer in 10.12 onward!")
    } else {
      NSWorkspace.shared.notificationCenter.removeObserver(self,
                                                           name: NSWorkspace.didMountNotification,
                                                           object: nil)
      
      NSWorkspace.shared.notificationCenter.removeObserver(self,
                                                           name: NSWorkspace.didUnmountNotification,
                                                           object: nil)
      
      NSWorkspace.shared.notificationCenter.removeObserver(self,
                                                           name: NSWorkspace.didRenameVolumeNotification,
                                                           object: nil)
      
      NSWorkspace.shared.notificationCenter.removeObserver(self,
                                                           name: NSWorkspace.didWakeNotification,
                                                           object: nil)
      
      NSWorkspace.shared.notificationCenter.removeObserver(self,
                                                           name: NSWorkspace.willPowerOffNotification,
                                                           object: nil)
    }
  }

  @objc func diskMounted() {
    self.forceSmarScan = true
    self.updateTitles()
  }
  
  @objc func diskUmounted() {
    self.forceSmarScan = true
    self.updateTitles()
  }
  
  @objc func powerOffListener() {
    self.removeObservers()
  }
  
  @objc func wakeListener() {
    self.forceSmarScan = true
    self.updateTitles()
  }
}
