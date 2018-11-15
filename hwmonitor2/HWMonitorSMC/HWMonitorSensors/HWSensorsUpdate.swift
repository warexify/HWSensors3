//
//  HWSensorsUpdate.swift
//  HWMonitorSMC2
//
//  Created by Vector Sigma on 26/10/2018.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

extension PopoverViewController {
  @objc func updateCPUSensors() {
    if self.initiated && (self.CPUNode != nil) {
      var newRead : [HWMonitorSensor] = AppSd.sensorScanner.get_CPU_GlobalParameters()
      
      for s in AppSd.sensorScanner.getSMC_SingleCPUFrequencies() {
        newRead.append(s)
      }
      
      for s in AppSd.sensorScanner.getSMC_SingleCPUTemperatures() {
        newRead.append(s)
      }

      let copy : NSArray = self.sensorList?.copy() as! NSArray
      for i in copy {
        let node = i as! HWTreeNode
        let sensor = node.sensorData!.sensor
        let sensorType = node.sensorData?.sensor?.sensorType
        
        for newSensor in newRead {
          if (newSensor.sensorType == sensorType) &&
            (newSensor.title == sensor?.title) &&
            (newSensor.key == sensor?.key) {
            sensor?.stringValue = newSensor.stringValue
            sensor?.doubleValue = newSensor.doubleValue
          }
        }
      }
      self.updateStatuBar()
    }
  }
  
  @objc func updateGPUSensors() {
    if self.initiated && (self.GPUNode != nil) {
      var newRead : [HWMonitorSensor] = AppSd.sensorScanner.getSMCGPU()
      
      if self.useIOAcceleratorForGPUs {
        for n in Graphics.init().getVideoCardsSensorsFromAccelerator() {
          for sub in n.mutableChildren {
            if let sensor : HWMonitorSensor = (sub as! HWTreeNode).sensorData?.sensor {
              newRead.append(sensor)
            }
          }
        }
      } else {
        if self.useIntelPowerGadget {
          newRead.append(contentsOf: getIntelPowerGadgetGPUSensors())
        }
        if let ipp = AppSd.sensorScanner.getIGPUPackagePower() {
          newRead.append(ipp)
        }
      }
      let copy : NSArray = self.sensorList?.copy() as! NSArray
      for i in copy {
        let node = i as! HWTreeNode
        let sensor = node.sensorData!.sensor
        let sensorType = node.sensorData?.sensor?.sensorType
        
        for newSensor in newRead {
          if (newSensor.sensorType == sensorType) &&
            (newSensor.title == sensor?.title)
            && (newSensor.key == sensor?.key) {
            sensor?.stringValue = newSensor.stringValue
            sensor?.doubleValue = newSensor.doubleValue
          }
        }
      }
      self.updateStatuBar()
    }
  }
  
  @objc func updateMotherboardSensors() {
    if self.initiated && (self.MOBONode != nil) {
      let newRead = AppSd.sensorScanner.getMotherboard()
      
      let copy : NSArray = self.sensorList?.copy() as! NSArray
      for i in copy {
        let node = i as! HWTreeNode
        let sensor = node.sensorData!.sensor
        let sensorType = node.sensorData?.sensor?.sensorType
        
        for newSensor in newRead {
          if (newSensor.sensorType == sensorType) && (newSensor.title == sensor?.title) {
            sensor?.stringValue = newSensor.stringValue
            sensor?.doubleValue = newSensor.doubleValue
          }
        }
      }
      self.updateStatuBar()
    }
  }
  
  @objc func updateFanSensors() {
    if self.initiated && (self.FansNode != nil) {
      let newRead = AppSd.sensorScanner.getFans()
      
      let copy : NSArray = self.sensorList?.copy() as! NSArray
      for i in copy {
        let node = i as! HWTreeNode
        let sensor = node.sensorData!.sensor
        let sensorType = node.sensorData?.sensor?.sensorType
        
        for newSensor in newRead {
          if (newSensor.sensorType == sensorType) && (newSensor.title == sensor?.title) {
            sensor?.stringValue = newSensor.stringValue
            sensor?.doubleValue = newSensor.doubleValue
          }
        }
      }
      self.updateStatuBar()
    }
  }
  
  @objc func updateRAMSensors() {
    if self.initiated && (self.RAMNode != nil) {
      let newRAM = AppSd.sensorScanner.getMemory()
      
      let copy : NSArray = self.sensorList?.copy() as! NSArray
      for i in copy {
        let node = i as! HWTreeNode
        let sensor = node.sensorData!.sensor
        let sensorType = node.sensorData?.sensor?.sensorType
        
        for newSensor in newRAM {
          if (newSensor.sensorType == sensorType) && (newSensor.title == sensor?.title) {
            sensor?.stringValue = newSensor.stringValue
            sensor?.doubleValue = newSensor.doubleValue
            sensor?.unit = newSensor.unit
          }
        }
      }
      self.updateStatuBar()
    }
  }
  
  @objc func updateMediaSensors() {
    if self.initiated && (self.mediaNode != nil) {
      // to do? see if we have new hard drive, and update the outline.
      let newMediaNode = HWTreeNode(representedObject: HWSensorData(group: (self.mediaNode?.sensorData?.group)!,
                                                                     sensor: nil,
                                                                     isLeaf: false))
      
      let smartscanner = HWSmartDataScanner()
      for d in smartscanner.getSmartCapableDisks() {
        var log : String = ""
        var productName : String = ""
        var serial : String = ""
        
        let list = smartscanner.getSensors(from: d, characteristics: &log, productName: &productName, serial: &serial)
        let smartSensorParent = HWMonitorSensor(key: productName,
                                                unit: HWUnit.none,
                                                type: "Parent",
                                                sensorType: .mediaSMARTContenitor,
                                                title: serial,
                                                canPlot: false)
        
        smartSensorParent.logType = .mediaLog
        smartSensorParent.characteristics = log
        let smartSensorParentNode = HWTreeNode(representedObject: HWSensorData(group: productName,
                                                                               sensor: smartSensorParent,
                                                                               isLeaf: false))
        for s in list {
          let snode = HWTreeNode(representedObject: HWSensorData(group: (smartSensorParentNode.sensorData?.group)!,
                                                                 sensor: s,
                                                                 isLeaf: true))
          s.characteristics = log
          smartSensorParentNode.mutableChildren.add(snode)
        }
        newMediaNode.mutableChildren.add(smartSensorParentNode)
      }
      
      var before : [String] = [String]()
      var after  : [String] = [String]()
      for disk in (self.mediaNode?.children)! {
        let productNameNode : HWTreeNode = disk as! HWTreeNode
        let modelAndSerial : String = (productNameNode.sensorData?.sensor?.key)! + (productNameNode.sensorData?.sensor)!.title
        before.append(modelAndSerial)
      }
      for disk in newMediaNode.children! {
        let productNameNode : HWTreeNode = disk as! HWTreeNode
        let modelAndSerial : String = (productNameNode.sensorData?.sensor?.key)! + (productNameNode.sensorData?.sensor)!.title
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
      
      let copy : NSArray = self.sensorList?.copy() as! NSArray
      for i in copy {
        let node = i as! HWTreeNode
        let sensor = node.sensorData?.sensor
        if let sensorType = node.sensorData?.sensor?.sensorType {
          if sensorType == .hdSmartLife || sensorType == .hdSmartTemp {
            for disk in newMediaNode.children! {
              let productNameNode : HWTreeNode = disk as! HWTreeNode
              var same = false
              for n in productNameNode.children! {
                let ln : HWTreeNode = n as! HWTreeNode
                if ln.sensorData?.sensor?.sensorType == sensorType && (ln.sensorData?.sensor?.key)! == sensor?.key {
                  sensor?.stringValue = (ln.sensorData?.sensor?.stringValue)!
                  sensor?.doubleValue = (ln.sensorData?.sensor?.doubleValue)!
                  sensor?.characteristics = (ln.sensorData?.sensor?.characteristics)!
                  (ln.parent as! HWTreeNode).sensorData?.sensor?.characteristics  = (ln.sensorData?.sensor?.characteristics)!
                  same = true
                  break
                }
              }
              if same {
                break
              }
            }
          }
        }
      }
      self.updateStatuBar()
    }
  }

  
  @objc func updateBatterySensors() {
    if self.initiated && (self.batteriesNode != nil) {
      let newBattery = AppSd.sensorScanner.getBattery()
      
      let copy : NSArray = self.sensorList?.copy() as! NSArray
      for i in copy {
        let node = i as! HWTreeNode
        let sensor = node.sensorData!.sensor
        let sensorType = node.sensorData?.sensor?.sensorType
        
        for newSensor in newBattery {
          if (newSensor.sensorType == sensorType) &&
            (newSensor.title == sensor?.title) &&
            (newSensor.key == sensor?.key) {
            sensor?.stringValue = newSensor.stringValue
            sensor?.doubleValue = newSensor.doubleValue
          }
        }
      }
      self.updateStatuBar()
    }
  }
  
  func updateStatuBar() {
    if !self.initiated || self.statusIsUpdating { return }
    self.statusIsUpdating  = true
    let copy : NSArray = self.sensorList?.copy() as! NSArray
    var components : [String] = [String]()
    AppSd.statusItem.attributedTitle = nil
    
    let useGadget : Bool = (self.gadgetWC != nil)

    for i in copy {
      let node = i as! HWTreeNode
      if let sensor = node.sensorData?.sensor {
        if sensor.favorite {
          if components.count <= 12 {
            components.append("\(sensor.stringValue)\(sensor.unit.rawValue.locale())")
          } else {
            sensor.favorite = false
          }
        }
        //ensure the node is visible before reload its view (no sense otherwise)
        let nodeIndex = self.outline.row(forItem: node)
        if self.outline.isItemExpanded(node.parent) && (nodeIndex >= 0) {
          self.outline.reloadData(forRowIndexes: IndexSet(integer: nodeIndex),
                                  columnIndexes: IndexSet(integer: 2))
        }
      }
    }

    let useOneLine : Bool = true
    var statusString = ""
    let style = NSMutableParagraphStyle()
    var f = NSFont(name: "Lucida Grande Bold", size: 9.0)!
    
    if useGadget {
      if useOneLine {
        style.lineSpacing = 0.0
        statusString = components.joined(separator: " ")
      } else {
        if components.count > 6 {
          f = NSFont(name: "Lucida Grande Bold", size: 8.0)!
          style.lineSpacing = 0.1
          for i in 0..<components.count {
            statusString += components[i]
            if i == 5 {
              statusString += "\n"
            } else {
              if i != (components.count - 1) {
                statusString += " "
              }
            }
          }
        } else {
          style.lineSpacing = 0.0
          statusString = components.joined(separator: " ")
        }
      }
    } else {
      style.lineSpacing = 0.0
      statusString = components.joined(separator: " ")
    }
    
    let title = NSMutableAttributedString(string: statusString as String, attributes: [NSAttributedString.Key.paragraphStyle : style])
    
    title.addAttributes([NSAttributedString.Key.font : f/*gPopOverFont*/, NSAttributedString.Key.kern : 1.0],
                        range: NSMakeRange(0, title.length))
    if useGadget {
      AppSd.statusItem.length = 23
      (self.gadgetWC?.contentViewController as! GadgetVC).statusField.animator().stringValue = title.string
    } else {
      AppSd.statusItem.attributedTitle = title
      AppSd.statusItem.length = (AppSd.statusItem.button?.intrinsicContentSize.width)! + 20
    }
    self.statusIsUpdating  = false
  }
}
