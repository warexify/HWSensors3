//
//  Graphics.swift
//  HWMonitorSMC2
//
//  Created by vector sigma on 30/04/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Foundation
import IOKit
import Metal

public struct Graphics {
  fileprivate var Intel_ID  : Data = Data([0x86, 0x80, 0x00, 0x00])
  fileprivate var AMD_ID    : Data = Data([0x02, 0x10, 0x00, 0x00])
  fileprivate var NVidia_ID : Data = Data([0xDE, 0x10, 0x00, 0x00])
  /*
   getVideoCardsSensorsFromAccelerator() is a replacement for RadeonSensor.kext
   when possible. NVIdia doesn't publish enough information ATM.
   */
  public func getVideoCardsSensorsFromAccelerator() -> [HWTreeNode] {
    var nodes : [HWTreeNode] = [HWTreeNode]()
    let list = Graphics.listGraphicsInfo()
    for i in 0..<list.count {
      let dict = list[i]
      var model             : String = "Unknown" // model can be String/Data
      let modelValue        : Any? = dict.object(forKey: "model")
      let vendorID          : Data = dict.object(forKey: "vendor-id") as! Data
      let deviceID          : Data = dict.object(forKey: "device-id") as! Data

      if (modelValue != nil) {
        if modelValue is NSString {
          model = modelValue as! String
        } else if modelValue is NSData {
          model = String(data: modelValue as! Data , encoding: .utf8) ?? model
        }
      }
      let primaryMatch : String = "0x" +
        String(format: "%02x", deviceID[1]) +
        String(format: "%02x", deviceID[0]) +
        String(format: "%02x", vendorID[1]) +
        String(format: "%02x", vendorID[0])
      
      let accelerators = Graphics.listAcceleratorsInfo()
      var PerformanceStatistics : NSDictionary? = nil
      for i in 0..<accelerators.count {
        let accDict = accelerators[i]
        if let IOPCIPrimaryMatch : String = accDict.object(forKey: "IOPCIPrimaryMatch") as? String {
          if (IOPCIPrimaryMatch.lowercased().range(of: primaryMatch) != nil) {
            if let ps : NSDictionary = accDict.object(forKey: "PerformanceStatistics") as? NSDictionary {
              PerformanceStatistics = ps
            }
            break
          }
        } else if let IOPCIMatch : String = accDict.object(forKey: "IOPCIMatch") as? String {
          if (IOPCIMatch.lowercased().range(of: primaryMatch) != nil) {
            if let ps : NSDictionary = accDict.object(forKey: "PerformanceStatistics") as? NSDictionary {
              PerformanceStatistics = ps
            }
            break
          }
        }
      }

      if (PerformanceStatistics != nil /*&&
        PerformanceStatistics?.object(forKey: "Core Clock(MHz)﻿﻿") != nil &&
        PerformanceStatistics?.object(forKey: "Temperature(C)") != nil*/) {
        let ud = UserDefaults.standard
        let gpuNode : HWTreeNode = HWTreeNode(representedObject: HWSensorData(group: model,
                                                                              sensor: nil,
                                                                              isLeaf: false))
        let unique : String = "\(primaryMatch)\(i)"
        
        if let coreclock : NSNumber = PerformanceStatistics?.object(forKey: "Core Clock(MHz)﻿﻿") as? NSNumber {
          let ccSensor : HWMonitorSensor = HWMonitorSensor(key: "Core Clock"  + unique,
                                                           andType: "",
                                                           andGroup: UInt(GPUAcceleratorSensorGroup),
                                                           withCaption: "Core Clock")
          ccSensor.favorite = ud.bool(forKey: ccSensor.key)
          ccSensor.characteristics = primaryMatch
          ccSensor.logType = GPULog
          ccSensor.stringValue = "\(coreclock.stringValue)MHz"
          gpuNode.mutableChildren.add(ccSensor)
        }
        
        if let temperature : NSNumber = PerformanceStatistics?.object(forKey: "Temperature(C)") as? NSNumber {
          
          let tempSensor : HWMonitorSensor = HWMonitorSensor(key: "Temperature" + unique,
                                                             andType: "",
                                                             andGroup: UInt(GPUAcceleratorSensorGroup),
                                                             withCaption: "Temperature")
          tempSensor.favorite = ud.bool(forKey: tempSensor.key)
          tempSensor.characteristics = primaryMatch
          tempSensor.logType = GPULog
          tempSensor.stringValue = "\(temperature.stringValue)°"
          gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                 sensor: tempSensor,
                                                                                 isLeaf: true)))
        }

        if let fanSpeed : NSNumber = PerformanceStatistics?.object(forKey: "Fan Speed(RPM)") as? NSNumber {
          let fanSensor : HWMonitorSensor = HWMonitorSensor(key: "Fan/Pump Speed" + unique,
                                                             andType: "",
                                                             andGroup: UInt(GPUAcceleratorSensorGroup),
                                                             withCaption: NSLocalizedString("Fan/Pump Speed", comment: ""))
          fanSensor.favorite = ud.bool(forKey: fanSensor.key)
          fanSensor.characteristics = primaryMatch
          fanSensor.logType = GPULog
          fanSensor.stringValue = "\(fanSpeed.stringValue)RPM"
          gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                 sensor: fanSensor,
                                                                                 isLeaf: true)))
        }
        
        if let fanSpeed100 : NSNumber = PerformanceStatistics?.object(forKey: "Fan Speed(%)") as? NSNumber {
          let fan100Sensor : HWMonitorSensor = HWMonitorSensor(key: "Fan/Pump Speed rate" + unique,
                                                            andType: "",
                                                            andGroup: UInt(GPUAcceleratorSensorGroup),
                                                            withCaption: NSLocalizedString("Fan/Pump Speed rate", comment: ""))
          fan100Sensor.favorite = ud.bool(forKey: fan100Sensor.key)
          fan100Sensor.characteristics = primaryMatch
          fan100Sensor.logType = GPULog
          fan100Sensor.stringValue = "\(fanSpeed100.stringValue)%"
          gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                 sensor: fan100Sensor,
                                                                                 isLeaf: true)))
        }
        
        if let deviceUtilization : NSNumber = PerformanceStatistics?.object(forKey: "Device Utilization %") as? NSNumber {
          let duSensor : HWMonitorSensor = HWMonitorSensor(key: "Device Utilization" + unique,
                                                               andType: "",
                                                               andGroup: UInt(GPUAcceleratorSensorGroup),
                                                               withCaption: NSLocalizedString("Device Utilization", comment: ""))
          duSensor.favorite = ud.bool(forKey: duSensor.key)
          duSensor.characteristics = primaryMatch
          duSensor.logType = GPULog
          duSensor.stringValue = "\(deviceUtilization.stringValue)%"
          gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                 sensor: duSensor,
                                                                                 isLeaf: true)))
        }
        
        if let gpuActivity : NSNumber = PerformanceStatistics?.object(forKey: "GPU Activity(%)") as? NSNumber {
          let gaSensor : HWMonitorSensor = HWMonitorSensor(key: "GPU Activity" + unique,
                                                           andType: "",
                                                           andGroup: UInt(GPUAcceleratorSensorGroup),
                                                           withCaption: NSLocalizedString("GPU Activity", comment: ""))
          gaSensor.favorite = ud.bool(forKey: gaSensor.key)
          gaSensor.characteristics = primaryMatch
          gaSensor.logType = GPULog
          gaSensor.stringValue = "\(gpuActivity.stringValue)%"
          gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                 sensor: gaSensor,
                                                                                 isLeaf: true)))
        }
        nodes.append(gpuNode)
      }
    }
    
    return nodes
  }
  
  /*
   The public getGraphicsInfo() function return a detailed log for each
   pci-GPU in the System. If the primaryMatch is not nil this is used for a specific card at index
   */
  public func getGraphicsInfo(primaryMatch: String?, index: Int) -> String {
    var log : String = ""
    let list = Graphics.listGraphicsInfo()
    for i in 0..<list.count {
      if (primaryMatch != nil) {
        let vendorID : Data = list[i].object(forKey: "vendor-id") as! Data
        let deviceID : Data = list[i].object(forKey: "device-id") as! Data
        let pm : String = "0x" +
          String(format: "%02x", deviceID[1]) +
          String(format: "%02x", deviceID[0]) +
          String(format: "%02x", vendorID[1]) +
          String(format: "%02x", vendorID[0])
        if pm == primaryMatch && i == index {
          log += self.getVideoCardLog(from: list[i], cardNumber: i)
          break
        }
      } else {
        log += self.getVideoCardLog(from: list[i], cardNumber: i)
      }
    }
    return log
  }
  
  /*
   getVideoCardLog() returns a log for a specific card at index
   Anyway must match de device id to be sure..
   */
  fileprivate func getVideoCardLog(from dictionary: NSDictionary, cardNumber: Int) -> String {
    var log : String = ""
    var vramLogged : Bool = false
    log += "VIDEO CARD \(cardNumber + 1):\n"
    
    // expected values:
    var model             : String = "Unknown" // model can be String/Data
    let modelValue        : Any? = dictionary.object(forKey: "model")
    let vendorID          : Data = dictionary.object(forKey: "vendor-id") as! Data
    let deviceID          : Data = dictionary.object(forKey: "device-id") as! Data
    let classcode         : Data = dictionary.object(forKey: "class-code") as! Data
    let revisionID        : Data = dictionary.object(forKey: "revision-id") as! Data
    let subsystemID       : Data = dictionary.object(forKey: "subsystem-id") as! Data
    let subsystemVendorID : Data = dictionary.object(forKey: "subsystem-vendor-id") as! Data
    
    let primaryMatch : String = "0x" +
      String(format: "%02x", deviceID[1]) +
      String(format: "%02x", deviceID[0]) +
      String(format: "%02x", vendorID[1]) +
      String(format: "%02x", vendorID[0])
    
    
    if (modelValue != nil) {
      if modelValue is NSString {
        model = modelValue as! String
      } else if modelValue is NSData {
        model = String(data: modelValue as! Data , encoding: .utf8) ?? model
      }
    }
    
    log += "\tModel:\t\t\t\t\(model)\n"
    log += "\tVendor ID:\t\t\t\t\(vendorID.hexadecimal()) (\(vendorStringFromData(data: vendorID)))\n"
    log += "\tDevice ID:\t\t\t\t\(deviceID.hexadecimal())\n"
    log += "\tRevision ID:\t\t\t\(revisionID.hexadecimal())\n"
    log += "\tSubsystem Vendor ID:\t\t\(subsystemVendorID.hexadecimal())\n"
    log += "\tSubsystem ID:\t\t\t\(subsystemID.hexadecimal())\n"
    log += "\tclass-code:\t\t\t\t\(classcode.hexadecimal())\n"
    // optional values
    if let ioName : String = dictionary.object(forKey: "IOName") as? String {
      log += "\tIOName:\t\t\t\t\(ioName)\n"
    }
    if let pcidebug : String = dictionary.object(forKey: "pcidebug") as? String {
      log += "\tpcidebug:\t\t\t\t\(pcidebug)\n"
    }
    if let builtin : Data = dictionary.object(forKey: "built-in") as? Data {
      log += "\tbuilt-in:\t\t\t\t\(builtin.hexadecimal())\n"
    }
    if let compatible : Data = dictionary.object(forKey: "compatible") as? Data {
      log += "\tcompatible:\t\t\t\(String(data: compatible, encoding: .utf8) ?? "Unknown")\n"
    }
    if let acpipath : String = dictionary.object(forKey: "acpi-path") as? String {
      log += "\tacpi-path:\t\t\t\t\(acpipath)\n"
    }
    if let hdagfx : Data = dictionary.object(forKey: "hda-gfx") as? Data {
      log += "\thda-gfx:\t\t\t\t\(String(data: hdagfx, encoding: .utf8) ?? "Unknown")\n"
    }
    
    // NVidia property (mostly)
    if let rmBoardNm : Data = dictionary.object(forKey: "rm_board_number") as? Data {
      log += "\trm_board_number:\t\t\(rmBoardNm.hexadecimal())\n"
    }
    if let noEFI : Data = dictionary.object(forKey: "NVDA,noEFI") as? Data {
      log += "\tNVDA,noEFI:\t\t\t\(String(data: noEFI, encoding: .utf8) ?? "Unknown")\n"
    }
    if let nVArch : String = dictionary.object(forKey: "NVArch") as? String {
      log += "\tNVArch:\t\t\t\t\t\(nVArch)\n"
    }
    if let romRev : Data = dictionary.object(forKey: "rom-revision") as? Data {
      log += "\trom-revision:\t\t\t\t\(String(data: romRev, encoding: .utf8) ?? "Unknown")\n"
    }
    if let nVClass : String = dictionary.object(forKey: "NVCLASS") as? String {
      log += "\tNVCLASS:\t\t\t\t\(nVClass)\n"
    }
    if let ncCap : Data = dictionary.object(forKey: "NVCAP") as? Data {
      log += "\tNVCAP:\t\t\t\t\(ncCap.hexadecimal())\n"
    }
    if let aspm : NSNumber = dictionary.object(forKey: "pci-aspm-default") as? NSNumber {
      log += "\tpci-aspm-default:\t\t\t\t\(String(format: "0x%X", aspm.intValue))\n"
    }
    if let vram : Data = dictionary.object(forKey: "VRAM,totalMB") as? Data {
      log += "\tVRAM,totalMB:\t\t\t\(vram.hexadecimal())\n"
      vramLogged = true
    }
    if let deviceType : Data = dictionary.object(forKey: "device_type") as? Data {
      log += "\tdevice_type:\t\t\t\(String(data: deviceType, encoding: .utf8) ?? "Unknown")\n"
    }
    if let accelLoaded : Data = dictionary.object(forKey: "NVDA,accel-loaded") as? Data {
      log += "\tNVDA,accel-loaded:\t\t\(accelLoaded.hexadecimal())\n"
    }
    if let vbiosRev : Data = dictionary.object(forKey: "vbios-revision") as? Data {
      log += "\tvbios-revision:\t\t\t\(vbiosRev.hexadecimal())\n"
    }
    if let nvdaFeatures : Data = dictionary.object(forKey: "NVDA,Features") as? Data {
      log += "\tvNVDA,Features:\t\t\t\(nvdaFeatures.hexadecimal())\n"
    }
    if let nvramProperty : Bool = dictionary.object(forKey: "IONVRAMProperty") as? Bool {
      log += "\tIONVRAMProperty:\t\t\t\(nvramProperty)\n"
    }
    if let initgl : String = dictionary.object(forKey: "NVDAinitgl_created") as? String {
      log += "\tNVDAinitgl_created:\t\t\(initgl)\n"
    }
    if let pciMSImode : Bool = dictionary.object(forKey: "IOPCIMSIMode") as? Bool {
      log += "\tIOPCIMSIMode\t\t\t\(pciMSImode)\n"
    }
    if let nvdaType : String = dictionary.object(forKey: "NVDAType") as? String {
      log += "\tNVDAType:\t\t\t\t\(nvdaType)\n"
    }
    
    log += "\tAdditional Properties:\n"
    if let aapls = getProperties(with: "AAPL", in: dictionary) {
      for key in (aapls.keys) {
        log += "\(key)\(aapls[key]!)\n"
      }
    }
    if let snail = getProperties(with: "@", in: dictionary) {
      for key in (snail.keys) {
        log += "\(key)\(snail[key]!)\n"
      }
    }
    if let aty = getProperties(with: "ATY", in: dictionary) {
      for key in (aty.keys) {
        log += "\(key)\(aty[key]!)\n"
      }
    }
    
    // accelerator info
    /*
     We can get IOAccelerator info through Metal (if supported) or through the IOAccelerator class
     The Metal's registriID instance variable is only available in 10.13..
     */
    var acceleratorDict : NSDictionary? = nil
    if #available(OSX 10.13, *) {
      let metals = MTLCopyAllDevices()
      for metal in metals {
        acceleratorDict = Graphics.acceleratorsInfo(with: metal.registryID, primaryMatch: primaryMatch)
        if (acceleratorDict != nil) {
          log += "\tMetal support: true\n"
          log += "\tMetal properties:\n"
          log += "\t\tMax Threads Per Thread group: width \(metal.maxThreadsPerThreadgroup.width), height \(metal.maxThreadsPerThreadgroup.height), depth \(metal.maxThreadsPerThreadgroup.depth)\n"
          log += "\t\tMax Thread group Memory Length:\t\(metal.maxThreadgroupMemoryLength)\n"
          log += "\t\tRecommended Max Working Set Size:\t\(String(format: "0x%X", metal.recommendedMaxWorkingSetSize))\n"
          log += "\t\tDepth 24 Stencil 8 Pixel Format:\t\t\(metal.isDepth24Stencil8PixelFormatSupported)\n"
          log += "\t\tProgrammable Sample Positions:\t\t\(metal.areProgrammableSamplePositionsSupported)\n"
          log += "\t\tRead-Write Texture:\t\t\t\t\(metal.readWriteTextureSupport.rawValue)\n"
          log += "\t\tHeadless:\t\t\t\t\t\t\(metal.isHeadless)\n"
          log += "\t\tIs Low Power:\t\t\t\t\t\(metal.isLowPower)\n"
          log += "\t\tRemovable:\t\t\t\t\t\t\(metal.isRemovable)\n"
          break
        }
      }
    }
    
    if (acceleratorDict == nil) {
      if #available(OSX 10.13, *) {
        log += "\tMetal support: false\n"
      }
      let accelerators = Graphics.listAcceleratorsInfo()
      for card in accelerators {
        if let IOPCIPrimaryMatch : String = card.object(forKey: "IOPCIPrimaryMatch") as? String {
          if (IOPCIPrimaryMatch.range(of: primaryMatch) != nil) {
            acceleratorDict = card
            break // We have the IOAccelerator info
          }
        } else if let IOPCIMatch : String = card.object(forKey: "IOPCIMatch") as? String {
          if (IOPCIMatch.range(of: primaryMatch) != nil) {
            acceleratorDict = card
            break // We have the IOAccelerator info
          }
        }
      }
    }
    
    if (acceleratorDict != nil) {
      if let PerformanceStatistics : NSDictionary = acceleratorDict?.object(forKey: "PerformanceStatistics") as? NSDictionary {
        if let performances = getPerformanceStatistics(in: PerformanceStatistics) {
          log += "\tPerformance Statistics:\n"
          for key in (performances.keys) {
            log += "\(key)\(performances[key]!)\n"
          }
        }
      }
      if !vramLogged {
        if let vram : NSNumber = acceleratorDict?.object(forKey: "VRAM,totalMB") as? NSNumber {
          log += "\tVRAM,totalMB: \(vram.intValue)\n"
          vramLogged = true
        }
      }
    }
    return log
  }
  /*
   getProperties() return all properties that starts with a prefix (like "AAPL")! for the given dictionary
   This ensure that all of it are show in the log without effectively be aware of them.
   */
  fileprivate func getProperties(with prefix: String, in dict : NSDictionary) -> [String: String]? {
    // black listed keys: they are too long to be showned in the log
    //TODO: make a new method to format text with long data lenght with the possibility of truncate it or not
    let blackList : [String] = ["ATY,bin_image", "ATY,PlatformInfo", "AAPL,EMC-Display-List"]
    
    let fontAttr =  [NSAttributedStringKey.font : gLogFont] // need to count a size with proportional font
    var properties : [String: String] = [String: String]()
    let allKeys = dict.allKeys // are as [Any]
    var maxLength : Int = 0
    let sep = ": "
    let ind = "\t\t"
    
    // get the max length of the string and all the valid keys
    for k in allKeys {
      let key : String = (k as! String).trimmingCharacters(in: .whitespacesAndNewlines)
      if !blackList.contains(key) {
        if key.hasPrefix(prefix) {
          let keyL : Int = Int(key.size(withAttributes: fontAttr).width)
          if keyL > maxLength {
            maxLength = keyL
          }
          
          var value : String? = nil
          if let raw : Any = dict.object(forKey: key) {
            if raw is NSString {
              value = (raw as! String)
            } else if raw is NSData {
              let data : Data = (raw as! Data)
              value = "\(data.hexadecimal())"
            } else if raw is NSNumber {
              value = "\((raw as! NSNumber).intValue)"
            }
          }
          
          if (value != nil) {
            properties[key] = value
          }
        }
      }
    }
    
    if prefix.hasPrefix("@") {
      // don't know why, if string starts with @ needs the follow
      maxLength +=  Int("@".size(withAttributes: fontAttr).width)
    }
    
    // return with formmatted keys already
    if properties.keys.count > 0 {
      var validProperties : [String : String] = [String : String]()
      maxLength += Int(sep.size(withAttributes: fontAttr).width)
      for key in properties.keys {
        var keyPadded : String = key + sep
        while Int(keyPadded.size(withAttributes: fontAttr).width) < maxLength + 1 {
          keyPadded += " "
        }
        validProperties[ind + keyPadded + "\t"] = properties[key]
      }
      return validProperties
    }
    
    return nil
  }

  /*
   vendorStringFromData() return the GPU vendor name string
   */
  fileprivate func vendorStringFromData(data: Data) -> String {
    var vendor = "Unknown"
    if data ==  Intel_ID {
      vendor = "Intel"
    } else if data ==  AMD_ID {
      vendor = "ATI/AMD"
    } else if data ==  NVidia_ID {
      vendor = "NVidia"
    }
    return vendor
  }
  
  /*
   listGraphicsInfo() returns all the pci-GPU in the System
   */
  fileprivate static func listGraphicsInfo() -> [NSDictionary] {
    var cards : [NSDictionary] = [NSDictionary]()
    var serviceObject : io_object_t
    var iter : io_iterator_t = 0
    let matching = IOServiceMatching("IOPCIDevice")
    let err = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                           matching,
                                           &iter)
    if err == KERN_SUCCESS && iter != 0 {
      if KERN_SUCCESS == err {
        repeat {
          serviceObject = IOIteratorNext(iter)
          let opt : IOOptionBits = IOOptionBits(kIORegistryIterateParents | kIORegistryIterateRecursively)
          var serviceDictionary : Unmanaged<CFMutableDictionary>?
          if IORegistryEntryCreateCFProperties(serviceObject, &serviceDictionary, kCFAllocatorDefault, opt) != kIOReturnSuccess {
            IOObjectRelease(serviceObject)
            continue
          }
          if let info : NSMutableDictionary = serviceDictionary?.takeRetainedValue() {
            if (info.object(forKey: "model") != nil) && (info.object(forKey: "class-code") != nil) {
              if let classcode : Data = info.object(forKey: "class-code") as? Data {
                if classcode == Data([0x00, 0x00, 0x03, 0x00]) {
                  info.setValue(NSNumber(value: serviceObject), forKey: "ServiceMatching")
                  cards.append(info)
                }
              }
            }
          }
          IOObjectRelease(serviceObject)
        } while serviceObject != 0
      }
      IOObjectRelease(iter)
    }
    return cards
  }
  
  /*
   acceleratorsInfo(with entryID, primaryMatch) return a dictionary
   for the IOAccelerator object that match the vendor/device id string
   */
  fileprivate static func acceleratorsInfo(with entryID : UInt64, primaryMatch: String) -> NSDictionary? {
    var dict : NSDictionary? = nil
    var serviceObject : io_object_t
    var iter : io_iterator_t = 0
    let matching = IORegistryEntryIDMatching(entryID)
    let err = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                           matching,
                                           &iter)
    if err == KERN_SUCCESS && iter != 0 {
      if KERN_SUCCESS == err  {
        repeat {
          serviceObject = IOIteratorNext(iter)
          let opt : IOOptionBits = IOOptionBits(kIORegistryIterateParents | kIORegistryIterateRecursively)
          var serviceDictionary : Unmanaged<CFMutableDictionary>?
          if IORegistryEntryCreateCFProperties(serviceObject, &serviceDictionary, kCFAllocatorDefault, opt) != kIOReturnSuccess {
            IOObjectRelease(serviceObject)
            continue
          }
          if let info : NSDictionary = serviceDictionary?.takeRetainedValue() {
            if let IOPCIPrimaryMatch : String = info.object(forKey: "IOPCIPrimaryMatch") as? String {
              if (IOPCIPrimaryMatch.lowercased().range(of: primaryMatch) != nil) {
                dict = info
                IOObjectRelease(serviceObject)
                break
              }
            } else if let IOPCIMatch : String = info.object(forKey: "IOPCIMatch") as? String {
              if (IOPCIMatch.lowercased().range(of: primaryMatch) != nil) {
                dict = info
                IOObjectRelease(serviceObject)
                break
              }
            }
          }
          IOObjectRelease(serviceObject)
        } while serviceObject != 0
      }
      IOObjectRelease(iter)
    }

    return dict
  }
  
  /*
   listAcceleratorsInfo() Return an array Dictionaries under IOAccelerator that
   match GPUs class code and have a IOPCIPrimaryMatch entry
   The "IOPCIPrimaryMatch" key is used to see if contains certain device id
   */
  fileprivate static func listAcceleratorsInfo() -> [NSDictionary] {
    var cards : [NSDictionary] = [NSDictionary]()
    var serviceObject : io_object_t
    var iter : io_iterator_t = 0
    let matching = IOServiceMatching("IOAccelerator")
    let err = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                           matching,
                                           &iter)
    if err == KERN_SUCCESS && iter != 0 {
      if KERN_SUCCESS == err  {
        repeat {
          serviceObject = IOIteratorNext(iter)
          let opt : IOOptionBits = IOOptionBits(kIORegistryIterateParents | kIORegistryIterateRecursively)
          var serviceDictionary : Unmanaged<CFMutableDictionary>?
          if IORegistryEntryCreateCFProperties(serviceObject, &serviceDictionary, kCFAllocatorDefault, opt) != kIOReturnSuccess {
            IOObjectRelease(serviceObject)
            continue
          }
          if let info : NSDictionary = serviceDictionary?.takeRetainedValue() {
            cards.append(info)
          }
          IOObjectRelease(serviceObject)
        } while serviceObject != 0
      }
      IOObjectRelease(iter)
    }
    return cards
  }
  
  /*
   getPerformanceStatistics() return a dictionary with object and keys already formatted for our log
   */
  fileprivate func getPerformanceStatistics(in dict : NSDictionary) -> [String: String]? {
    let fontAttr =  [NSAttributedStringKey.font : gLogFont] // need to count a size with proportional font
    var properties : [String: String] = [String: String]()
    let allKeys = dict.allKeys // are as [Any]
    var maxLength : Int = 0
    let sep = ": "
    let ind = "\t\t"
    
    // get the max length of the string and all the valid keys
    for k in allKeys {
      let key : String = (k as! String).trimmingCharacters(in: .whitespacesAndNewlines)
      let keyL : Int = Int(key.size(withAttributes: fontAttr).width)
      if keyL > maxLength {
        maxLength = keyL
      }
      
      var value : String? = nil
      if let raw : Any = dict.object(forKey: key) {
        if raw is NSString {
          value = (raw as! String)
        } else if raw is NSData {
          let data : Data = (raw as! Data)
          value = "\(data.hexadecimal())"
        } else if raw is NSNumber {
          value = "\((raw as! NSNumber).intValue)"
        }
      }
      
      if (value != nil) {
        properties[key] = value
      }
    }
    
    // return with formmatted keys already
    if properties.keys.count > 0 {
      var validProperties : [String : String] = [String : String]()
      maxLength += Int(sep.size(withAttributes: fontAttr).width)
      for key in properties.keys {
        var keyPadded : String = key + sep
        while Int(keyPadded.size(withAttributes: fontAttr).width) < maxLength + 1 {
          keyPadded += " "
        }
        validProperties[ind + keyPadded + "\t"] = properties[key]
      }
      return validProperties
    }
    
    return nil
  }
}
