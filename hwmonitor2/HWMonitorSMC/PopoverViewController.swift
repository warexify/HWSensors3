//
//  PopoverViewController.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 26/02/18.
//  Copyright © 2018 vector sigma. All rights reserved.
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
  var CPUFrequenciesNode        : HWTreeNode?
  var voltagesNode              : HWTreeNode?
  var CPUTemperaturesNode       : HWTreeNode?
  var multipliersNode           : HWTreeNode?
  var allOtherTemperaturesNode  : HWTreeNode?
  var allOtherFrequenciesNode   : HWTreeNode?
  var fansNode                  : HWTreeNode?
  var mediaNode                 : HWTreeNode?
  var batteriesNode             : HWTreeNode?
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let pin = NSImage(named: NSImage.Name(rawValue: "pin"))
    pin?.isTemplate = true
    self.attachButton.image = pin
    self.effectView.appearance = NSAppearance(named: gAppearance)
    if let version = Bundle.main.infoDictionary?["CFBundleVersion"]  as? String {
      self.versionLabel.stringValue = "HWMonitorSMC v" + version + " Beta"
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
    if (ud.object(forKey: "expandCPUTemperature") != nil) {
      self.expandCPUTemperature = ud.bool(forKey: "expandCPUTemperature")
    } else {
      self.expandCPUTemperature = true
      ud.set(true, forKey: "expandCPUTemperature")
    }
    
    if (ud.object(forKey: "expandVoltages") != nil) {
      self.expandVoltages = ud.bool(forKey: "expandVoltages")
    } else {
      self.expandVoltages = false
      ud.set(false, forKey: "expandVoltages")
    }
    
    if (ud.object(forKey: "expandCPUFrequencies") != nil) {
      self.expandCPUFrequencies = ud.bool(forKey: "expandCPUFrequencies")
    } else {
      self.expandCPUFrequencies = true
      ud.set(true, forKey: "expandCPUFrequencies")
    }
    
    if (ud.object(forKey: "expandAll") != nil) {
      self.expandAll = ud.bool(forKey: "expandAll")
    } else {
      self.expandAll = false
      ud.set(false, forKey: "expandAll")
    }
    
    if (ud.object(forKey: "dontshowEmpty") != nil) {
      self.dontshowEmpty = ud.bool(forKey: "dontshowEmpty")
    } else {
      self.dontshowEmpty = true
      ud.set(true, forKey: "dontshowEmpty")
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
    if (UserDefaults.standard.object(forKey: "SensorsTimeInterval") != nil) {
      timeInterval = UserDefaults.standard.double(forKey: "SensorsTimeInterval")
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
    self.multipliersNode =  HWTreeNode(representedObject: HWSensorData(group: NSLocalizedString("Multiplers", comment: ""),
                                                                       sensor: nil,
                                                                       isLeaf: false))
    for s in (self.sensorDelegate?.getMultiplers())! {
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
    self.mediaNode =  HWTreeNode(representedObject: HWSensorData(group: NSLocalizedString("Media healt", comment: ""),
                                                                sensor: nil,
                                                                isLeaf: false))
    for s in (self.sensorDelegate?.getDisks())! {
      let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.mediaNode?.sensorData?.group)!,
                                                              sensor: s as? HWMonitorSensor,
                                                              isLeaf: true))
      self.mediaNode?.mutableChildren.add(sensor)
    }
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
      }
      if (self.batteriesNode != nil) {
        self.outline.expandItem(self.batteriesNode)
      }
    }
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
      let newGenericBatteries : [HWMonitorSensor] = self.sensorDelegate?.getGenericBatteries() as! [HWMonitorSensor]
      let newBattery : [HWMonitorSensor] = self.sensorDelegate?.getBattery() as! [HWMonitorSensor]
      let newMedia : [HWMonitorSensor] = self.sensorDelegate?.getDisks() as! [HWMonitorSensor]
      for i in copy {
        let node = i as! HWTreeNode
        let sensor = node.sensorData?.sensor
        let group = node.sensorData?.sensor?.group
        if ((sensor?.valueField) != nil) {
          var value : String = "-"
          // Battery sensor are fake, re read it
          switch group {
          case UInt(HDSmartLifeSensorGroup)?:
            found = true
            for newSensor in newMedia {
              if newSensor.caption == node.sensorData?.sensor?.caption {
                value = "\(NSLocalizedString("life", comment: "")): " + newSensor.stringValue
                //value = newSensor.stringValue
              }
            }
            break
          case UInt(HDSmartTempSensorGroup)?:
            found = true
            for newSensor in newMedia {
              if newSensor.caption == node.sensorData?.sensor?.caption {
                value = newSensor.stringValue
              }
            }
            break
          case UInt(BatterySensorsGroup)?:
            found = true
            for newSensor in newBattery {
              if newSensor.caption == node.sensorData?.sensor?.caption {
                value = newSensor.stringValue
              }
            }
            break
          case UInt(GenericBatterySensorsGroup)?:
            var new : [HWTreeNode] = [HWTreeNode]()
            found = false
            for newSensor in newGenericBatteries {
              if newSensor.caption == node.sensorData?.sensor?.caption {
                if let data = HWMonitorSensor.readValue(forKey: node.sensorData?.sensor?.key) {
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
              }
              self.outline.reloadItem(self.batteriesNode, reloadChildren: true)
            }
            break
            case UInt(HDSmartLifeSensorGroup)?:
            break
            case UInt(HDSmartTempSensorGroup)?:
            break
          default:
            found = true
            if let data = HWMonitorSensor.readValue(forKey: node.sensorData?.sensor?.key) {
              value = (sensor?.formatedValue(data)!)!
            }
            break
          }
          
          if found {
            node.sensorData?.sensor?.valueField.stringValue = value
            if (sensor?.favorite)! {
              statusString.append(" ")
              statusString.append(value)
            }
          }
        }
        if self.outline.isItemExpanded(node.parent) {
          self.outline.reloadItem(node, reloadChildren: false)
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
  
  
  @objc func clicked() {
    let selected = self.outline.clickedRow
    if selected >= 0 {
      if let node : HWTreeNode = self.outline.item(atRow: selected) as? HWTreeNode {
        if (node.sensorData?.isLeaf)! {
          let sensor = node.sensorData?.sensor
          if (sensor?.favorite)! {
            sensor?.favorite = false
            sensor?.stateView.image = nil
          } else {
            sensor?.favorite = true
            let image = NSImage(named: NSImage.Name(rawValue: "checkbox"))
            image?.isTemplate = true
            sensor?.stateView.image = image
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
  
  /*
  func outlineView(_ outlineView: NSOutlineView,
                   objectValueFor tableColumn: NSTableColumn?,
                   byItem item: Any?) -> Any? {
    return "e"
  }*/
  
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
          (view?.imageView as! HWImageView).representedObject = node.sensorData?.sensor
          node.sensorData?.sensor?.stateView = view?.imageView as! HWImageView!
          node.sensorData?.sensor?.object = view
          break
        case "column1":
          if isGroup {
            view?.textField?.stringValue = (node.sensorData?.group)!
            view?.textField?.textColor = (gAppearance == NSAppearance.Name.vibrantDark) ? NSColor.green : NSColor.blue
          } else {
            view?.textField?.stringValue = (node.sensorData?.sensor?.caption)!
            (view?.textField as! HWTextField).representedObject = node.sensorData?.sensor
            node.sensorData?.sensor?.keyField = (view?.textField)! as! HWTextField
          }
          node.sensorData?.sensor?.object = view
          
          break
        case "column2":
          if isGroup {
            view?.textField?.stringValue = ""
          } else {
            var value : String = "-"
            
            if node.sensorData?.sensor?.group == UInt(HDSmartLifeSensorGroup) {
              value = "\(NSLocalizedString("life", comment: "")): " + (node.sensorData?.sensor?.stringValue)!
            } else
            if node.sensorData?.sensor?.group == UInt(BatterySensorsGroup) ||
              node.sensorData?.sensor?.group == UInt(HDSmartTempSensorGroup) {
              value = (node.sensorData?.sensor?.stringValue)!
            } else {
              if let data = HWMonitorSensor.readValue(forKey: node.sensorData?.sensor?.key) {
                value = (node.sensorData?.sensor?.formatedValue(data))!
              }
            }
            
            view?.textField?.stringValue = value
            (view?.textField as! HWTextField).representedObject = node.sensorData?.sensor
            node.sensorData?.sensor?.object = view
            node.sensorData?.sensor?.valueField = (view?.textField)! as! HWTextField
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
      case NSLocalizedString("CPU Temperatures", comment: ""):
        image = NSImage(named: NSImage.Name(rawValue: "temperature_small"))
        break
      case NSLocalizedString("CPU Frequencies", comment: ""):
        image = NSImage(named: NSImage.Name(rawValue: "freq_small"))
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
      case NSLocalizedString("Multiplers", comment: ""):
        image = NSImage(named: NSImage.Name(rawValue: "multiply_small"))
        break
      case NSLocalizedString("Voltages", comment: ""):
        image = NSImage(named: NSImage.Name(rawValue: "voltage_small"))
        break
      case NSLocalizedString("Batteries", comment: ""):
        image = NSImage(named: NSImage.Name(rawValue: "modern-battery-icon"))
        break
      case NSLocalizedString("Media healt", comment: ""):
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
      UserDefaults.standard.set(newLocation.x, forKey: "popoverWidth")
      UserDefaults.standard.set(newLocation.y, forKey: "popoverHeight")
      UserDefaults.standard.synchronize()
    }
  }
}
