//
//  Graphics.swift
//  HWMonitorSMC2
//
//  Created by vector sigma on 30/04/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa
import IOKit
import Metal

public struct Graphics {
  fileprivate let Intel_ID  : Data = Data([0x86, 0x80, 0x00, 0x00])
  fileprivate let AMD_ID    : Data = Data([0x02, 0x10, 0x00, 0x00])
  fileprivate let NVidia_ID : Data = Data([0xDE, 0x10, 0x00, 0x00])
  
  /*
   getVideoCardsSensorsFromAccelerator() is a replacement for RadeonSensor.kext
   when possible. NVIdia doesn't publish enough information ATM.
   */
  
  public func getVideoCardsSensorsFromAccelerator() -> [HWTreeNode] {
    //let ipg : Bool = AppSd.ipgInited
    var nodes : [HWTreeNode] = [HWTreeNode]()
    let list = Graphics.listGraphicsInfo()
    for i in 0..<list.count {
      let dict = list[i]
      //print("dict \(i):\n\(dict)\n-----------------------------------------------")
      let vendorID          : Data = dict.object(forKey: "vendor-id") as! Data
      let deviceID          : Data = dict.object(forKey: "device-id") as! Data
      var model             : String = "Unknown" // model can be String/Data
      let modelValue        : Any? = dict.object(forKey: "model")
      let acpiPath : String? = dict.object(forKey: "acpi-path") as? String

      var vendorString : String = "Unknown"
      if vendorID == NVidia_ID {
        vendorString = "nvidia"
      } else if vendorID == Intel_ID {
        vendorString = "intel"
      } else if vendorID == AMD_ID {
        vendorString = "amd"
      }
      
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
        if vendorID == NVidia_ID {
          if let apath : String = accDict.object(forKey: "acpi-path") as? String {
            if apath == acpiPath  {
              if let ps : NSDictionary = accDict.object(forKey: "PerformanceStatistics") as? NSDictionary {
                PerformanceStatistics = ps
                break
              }
            }
          }
        } else {
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
        
        
      }

    
      if (PerformanceStatistics != nil) {
        let ud = UserDefaults.standard
        let gpuNode : HWTreeNode = HWTreeNode(representedObject: HWSensorData(group: model,
                                                                              sensor: nil,
                                                                              isLeaf: false))
        let unique : String = "\(primaryMatch)\(i)"
        
        if let coreclock : NSNumber = PerformanceStatistics?.object(forKey: "Core Clock(MHz)﻿﻿") as? NSNumber {
          
          let ccSensor = HWMonitorSensor(key: "Core Clock" + unique,
                                         unit: HWUnit.GHz,
                                         type: "IOAcc",
                                         sensorType: .gpuIO_coreClock,
                                         title: "Core Clock".locale(),
                                         canPlot: false)
          
          ccSensor.favorite = ud.bool(forKey: ccSensor.key)
          ccSensor.characteristics = primaryMatch
          ccSensor.logType = .gpuLog
          ccSensor.doubleValue = Double(coreclock.doubleValue)
          ccSensor.stringValue = "\(coreclock.stringValue)" + ccSensor.unit.rawValue
          ccSensor.vendor = vendorString
          gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                 sensor: ccSensor,
                                                                                 isLeaf: true)))
        }
        
        if let temperature : NSNumber = PerformanceStatistics?.object(forKey: "Temperature(C)") as? NSNumber {
          
          let tempSensor = HWMonitorSensor(key: "Temperature" + unique,
                                         unit: HWUnit.C,
                                         type: "IOAcc",
                                         sensorType: .gpuIO_temp,
                                         title: "Temperature".locale(),
                                         canPlot: true)
          tempSensor.favorite = ud.bool(forKey: tempSensor.key)
          tempSensor.characteristics = primaryMatch
          tempSensor.logType = .gpuLog
          tempSensor.doubleValue = temperature.doubleValue
          tempSensor.stringValue = "\(temperature.stringValue)" + tempSensor.unit.rawValue
          tempSensor.vendor = vendorString
          gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                 sensor: tempSensor,
                                                                                 isLeaf: true)))
        }

        if let fanSpeed : NSNumber = PerformanceStatistics?.object(forKey: "Fan Speed(RPM)") as? NSNumber {
          
          let fanSensor = HWMonitorSensor(key: "Fan/Pump Speed" + unique,
                                          unit: HWUnit.RPM,
                                          type: "IOAcc",
                                          sensorType: .gpuIO_FanRPM,
                                          title: "Fan/Pump speed".locale(),
                                          canPlot: true)

          fanSensor.favorite = ud.bool(forKey: fanSensor.key)
          fanSensor.characteristics = primaryMatch
          fanSensor.logType = .gpuLog
          fanSensor.doubleValue = fanSpeed.doubleValue
          fanSensor.stringValue = "\(fanSpeed.stringValue)" + fanSensor.unit.rawValue
          fanSensor.vendor = vendorString
          gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                 sensor: fanSensor,
                                                                                 isLeaf: true)))
        }
        
        if let fanSpeed100 : NSNumber = PerformanceStatistics?.object(forKey: "Fan Speed(%)") as? NSNumber {
          
          let fan100Sensor = HWMonitorSensor(key: "Fan/Pump Speed rate" + unique,
                                             unit: HWUnit.Percent,
                                             type: "IOAcc",
                                             sensorType: .gpuIO_percent,
                                             title: "Fan/Pump speed rate".locale(),
                                             canPlot: true)
          
          fan100Sensor.favorite = ud.bool(forKey: fan100Sensor.key)
          fan100Sensor.characteristics = primaryMatch
          fan100Sensor.logType = .gpuLog
          fan100Sensor.doubleValue = fanSpeed100.doubleValue
          fan100Sensor.stringValue = "\(fanSpeed100.stringValue)" + fan100Sensor.unit.rawValue
          fan100Sensor.vendor = vendorString
          gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                 sensor: fan100Sensor,
                                                                                 isLeaf: true)))
        }
        
        //if (!ipg && vendorID == Intel_ID) || vendorID != Intel_ID {
          if let deviceUtilization : NSNumber = PerformanceStatistics?.object(forKey: "Device Utilization %") as? NSNumber {
            let duSensor = HWMonitorSensor(key: "Device Utilization" + unique,
                                           unit: HWUnit.Percent,
                                           type: "IOAcc",
                                           sensorType: .gpuIO_percent,
                                           title: "Device Utilization".locale(),
                                           canPlot: true)
            
            duSensor.favorite = ud.bool(forKey: duSensor.key)
            duSensor.characteristics = primaryMatch
            duSensor.logType = .gpuLog
            duSensor.doubleValue = deviceUtilization.doubleValue
            duSensor.stringValue = "\(deviceUtilization.stringValue)" + duSensor.unit.rawValue
            duSensor.vendor = vendorString
            gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                   sensor: duSensor,
                                                                                   isLeaf: true)))
          }
        //}
        
        if vendorID == NVidia_ID {
          if let gpuCoreUtilization : NSNumber = PerformanceStatistics?.object(forKey: "GPU Core Utilization") as? NSNumber {
            var gcuInt = gpuCoreUtilization.intValue
            if gcuInt >= 10000000 {
              gcuInt = gcuInt / 10000000
            }
            
            let gcuSensor = HWMonitorSensor(key: "GPU Core Utilization" + unique,
                                           unit: HWUnit.Percent,
                                           type: "IOAcc",
                                           sensorType: .gpuIO_percent,
                                           title: "Core Utilization".locale(),
                                           canPlot: true)
            
            gcuSensor.favorite = ud.bool(forKey: gcuSensor.key)
            gcuSensor.characteristics = primaryMatch
            gcuSensor.logType = .gpuLog
            gcuSensor.doubleValue = Double(gcuInt)
            gcuSensor.stringValue = "\(gcuInt)" + gcuSensor.unit.rawValue
            gcuSensor.vendor = vendorString
            gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                   sensor: gcuSensor,
                                                                                   isLeaf: true)))
          }
        }
        
        
        if let gpuActivity : NSNumber = PerformanceStatistics?.object(forKey: "GPU Activity(%)") as? NSNumber {
          
          let gaSensor = HWMonitorSensor(key: "GPU Activity" + unique,
                                         unit: HWUnit.Percent,
                                         type: "IOAcc",
                                         sensorType: .gpuIO_percent,
                                         title: "Activity".locale(),
                                         canPlot: true)
          
          gaSensor.favorite = ud.bool(forKey: gaSensor.key)
          gaSensor.characteristics = primaryMatch
          gaSensor.logType = .gpuLog
          gaSensor.doubleValue = gpuActivity.doubleValue
          gaSensor.stringValue = "\(gpuActivity.stringValue)" + gaSensor.unit.rawValue
          gaSensor.vendor = vendorString
          gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                 sensor: gaSensor,
                                                                                 isLeaf: true)))
        }
        
        //if !AppSd.ipgInited {
          for i in 0..<1 /*0x0A*/ { // limited to Device Unit 0 Utilization
            if let deunUtilization : NSNumber = PerformanceStatistics?.object(forKey: "Device Unit \(i) Utilization %") as? NSNumber {
              
              let dunuSensor = HWMonitorSensor(key: "Device Unit \(i) Utilization" + unique,
                                               unit: HWUnit.Percent,
                                               type: "IOAcc",
                                               sensorType: .gpuIO_percent,
                                               title: String(format: "Device Unit %d Utilization".locale(), i),
                                               canPlot: true)
              
              dunuSensor.favorite = ud.bool(forKey: dunuSensor.key)
              dunuSensor.characteristics = primaryMatch
              dunuSensor.logType = .gpuLog
              dunuSensor.doubleValue = deunUtilization.doubleValue
              dunuSensor.stringValue = "\(deunUtilization.stringValue)"  + dunuSensor.unit.rawValue
              dunuSensor.vendor = vendorString
              gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                     sensor: dunuSensor,
                                                                                     isLeaf: true)))
            }
          //}
        }
        
        if vendorID == NVidia_ID {
          if let gpuEngineUtilization : NSNumber = PerformanceStatistics?.object(forKey: "GPU Video Engine Utilization") as? NSNumber {
            
            let gveuSensor = HWMonitorSensor(key: "GPU Video Engine Utilization" + unique,
                                             unit: HWUnit.Percent,
                                             type: "IOAcc",
                                             sensorType: .gpuIO_percent,
                                             title: "Video Engine Utilization".locale(),
                                             canPlot: true)
            
            gveuSensor.favorite = ud.bool(forKey: gveuSensor.key)
            gveuSensor.characteristics = primaryMatch
            gveuSensor.logType =  .gpuLog
            gveuSensor.doubleValue = gpuEngineUtilization.doubleValue
            gveuSensor.stringValue = "\(gpuEngineUtilization.stringValue)"   + gveuSensor.unit.rawValue
            gveuSensor.vendor = vendorString
            gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                   sensor: gveuSensor,
                                                                                   isLeaf: true)))
          }
          
          if let vramUsedBytes : NSNumber = PerformanceStatistics?.object(forKey: "vramUsedBytes") as? NSNumber {
            let vrubSensor = HWMonitorSensor(key: "Used VRAM" + unique,
                                             unit: HWUnit.auto,
                                             type: "IOAcc",
                                             sensorType: .gpuIO_RamBytes,
                                             title: "Used VRAM".locale(),
                                             canPlot: false)
            
            vrubSensor.favorite = ud.bool(forKey: vrubSensor.key)
            vrubSensor.characteristics = primaryMatch
            vrubSensor.logType = .gpuLog
            vrubSensor.doubleValue = vramUsedBytes.doubleValue
            vrubSensor.stringValue = ByteCountFormatter.string(fromByteCount: vramUsedBytes.int64Value, countStyle: .memory)
            vrubSensor.vendor = vendorString
            gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                   sensor: vrubSensor,
                                                                                   isLeaf: true)))
          }
          
          if let vramFreeBytes : NSNumber = PerformanceStatistics?.object(forKey: "vramFreeBytes") as? NSNumber {
            let vrfbSensor = HWMonitorSensor(key: "Free VRAM" + unique,
                                             unit: HWUnit.auto,
                                             type: "IOAcc",
                                             sensorType: .gpuIO_RamBytes,
                                             title: "Free VRAM".locale(),
                                             canPlot: false)
            
            vrfbSensor.favorite = ud.bool(forKey: vrfbSensor.key)
            vrfbSensor.characteristics = primaryMatch
            vrfbSensor.logType = .gpuLog
            vrfbSensor.doubleValue = vramFreeBytes.doubleValue
            vrfbSensor.stringValue = ByteCountFormatter.string(fromByteCount: vramFreeBytes.int64Value, countStyle: .memory)
            vrfbSensor.vendor = vendorString
            gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                   sensor: vrfbSensor,
                                                                                   isLeaf: true)))
          }
        }
        
        nodes.append(gpuNode)
      }
    }
    
    return nodes
  }

  /*
   The public getGraphicsInfo() function return a detailed log for each
   pci-GPU in the System. If the acpi-path (or primaryMatch) is not nil this is used for a specific card at index
   */
  public func getGraphicsInfo(acpiPathOrPrimaryMatch: String?, index: Int) -> String {
    var log : String = ""
    let list = Graphics.listGraphicsInfo()
    for i in 0..<list.count {
      let path : String? = list[i].object(forKey: "acpi-path") as? String
      if (acpiPathOrPrimaryMatch != nil && path != nil) {
        if path != nil {
          if acpiPathOrPrimaryMatch?.lowercased() == path!.lowercased() && i == index {
            log += self.getVideoCardLog(from: list[i], cardNumber: i)
            break
          }
        }
        let vendorID : Data = list[i].object(forKey: "vendor-id") as! Data
        let deviceID : Data = list[i].object(forKey: "device-id") as! Data
        let pm : String = "0x" +
          String(format: "%02x", deviceID[1]) +
          String(format: "%02x", deviceID[0]) +
          String(format: "%02x", vendorID[1]) +
          String(format: "%02x", vendorID[0])
        if pm.lowercased() == acpiPathOrPrimaryMatch?.lowercased() && i == index {
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
    let acpiPath : String? = (dictionary.object(forKey: "acpi-path") as? String)

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
    
    log += "\tacpi-path:\t\t\t\t\(acpiPath ?? "unknown")\n"
    
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
        acceleratorDict = Graphics.acceleratorsInfo(with: metal.registryID, acpiPathOrPrimaryMatch: acpiPath ?? primaryMatch)
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
          if (IOPCIPrimaryMatch.lowercased().range(of: primaryMatch.lowercased()) != nil) {
            acceleratorDict = card
            break // We have the IOAccelerator info
          }
        } else if let IOPCIMatch : String = card.object(forKey: "IOPCIMatch") as? String {
          if (IOPCIMatch.lowercased().range(of: primaryMatch.lowercased()) != nil) {
            acceleratorDict = card
            break // We have the IOAccelerator info
          }
        }
        // alive?
        if let path : String = card.object(forKey: "acpi-path") as? String {
          if path == acpiPath {
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
   This ensure that all of it are shown in the log without effectively be aware of them.
   */
  fileprivate func getProperties(with prefix: String, in dict : NSDictionary) -> [String: String]? {
    // black listed keys: they are too long to be showned in the log
    //TODO: make a new method to format text with long data lenght with the possibility of truncate it or not
    let blackList : [String] = ["ATY,bin_image", "ATY,PlatformInfo", "AAPL,EMC-Display-List"]
    
    let fontAttr =  [NSAttributedString.Key.font : gLogFont] // need to count a size with proportional font
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
    let GPU_CLASS_CODE : Data = Data([0x00, 0x00, 0x03, 0x00])
    let GPU_CLASS_CODE_OTHER : Data = Data([0x00, 0x80, 0x03, 0x00])
    let GPU_CLASS_CODE_3D : Data = Data([0x00, 0x02, 0x03, 0x00])
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
          if IORegistryEntryCreateCFProperties(serviceObject,
                                               &serviceDictionary,
                                               kCFAllocatorDefault, opt) != kIOReturnSuccess {
            IOObjectRelease(serviceObject)
            continue
          }
          if let info : NSMutableDictionary = serviceDictionary?.takeRetainedValue() {
            if (info.object(forKey: "model") != nil) && (info.object(forKey: "class-code") != nil) {
              if let classcode : Data = info.object(forKey: "class-code") as? Data {
                if classcode == GPU_CLASS_CODE ||
                  classcode == GPU_CLASS_CODE_OTHER ||
                  classcode == GPU_CLASS_CODE_3D {
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
   acceleratorsInfo(with entryID, acpiPath) return a dictionary
   for the IOAccelerator object that match the acpiPath string
   */
  fileprivate static func acceleratorsInfo(with entryID : UInt64, acpiPathOrPrimaryMatch: String) -> NSDictionary? {
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
          if IORegistryEntryCreateCFProperties(serviceObject,
                                               &serviceDictionary,
                                               kCFAllocatorDefault, opt) != kIOReturnSuccess {
            IOObjectRelease(serviceObject)
            continue
          }
          
          if let info : NSDictionary = serviceDictionary?.takeRetainedValue() {
            
            if let IOPCIPrimaryMatch : String = info.object(forKey: "IOPCIPrimaryMatch") as? String {
              if (IOPCIPrimaryMatch.lowercased().range(of: acpiPathOrPrimaryMatch) != nil) {
                dict = info
                IOObjectRelease(serviceObject)
                break
              }
            } else if let IOPCIMatch : String = info.object(forKey: "IOPCIMatch") as? String {
              if (IOPCIMatch.lowercased().range(of: acpiPathOrPrimaryMatch) != nil) {
                dict = info
                IOObjectRelease(serviceObject)
                break
              }
            }
            // loop alive?
            if let path : String = IORegistryEntrySearchCFProperty(serviceObject,
                                                                   kIOServicePlane,
                                                                   "acpi-path" as CFString,
                                                                   kCFAllocatorDefault, opt) as? String {
              if path == acpiPathOrPrimaryMatch {
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
   listAcceleratorsInfo() Return an array Dictionaries under IOAccelerator
   */
  fileprivate static func listAcceleratorsInfo() -> [NSDictionary] {
    var cards : [NSDictionary] = [NSDictionary]()
    var serviceObject : io_object_t
    var iter : io_iterator_t = 0
    let matching = IOServiceMatching(kIOAcceleratorClassName)
    let err = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                           matching,
                                           &iter)
    if err == KERN_SUCCESS && iter != 0 {
      if KERN_SUCCESS == err  {
        repeat {
          serviceObject = IOIteratorNext(iter)
          let opt : IOOptionBits = IOOptionBits(kIORegistryIterateParents | kIORegistryIterateRecursively)
          var serviceDictionary : Unmanaged<CFMutableDictionary>?
          if IORegistryEntryCreateCFProperties(serviceObject,
                                               &serviceDictionary,
                                               kCFAllocatorDefault, opt) != kIOReturnSuccess {
            IOObjectRelease(serviceObject)
            continue
          }
          if let info : NSMutableDictionary = serviceDictionary?.takeRetainedValue() {
            //print("info \(serviceObject):\n\(info)\n-----------------------------------------------")
            // look up for device-id and vendor-id (and more) that allow us to understand what card we are taliking about..
            if let vendorId : NSData = IORegistryEntrySearchCFProperty(serviceObject,
                                                                       kIOServicePlane,
                                                                       "vendor-id" as CFString,
                                                                       kCFAllocatorDefault, opt) as? NSData {
              info.setValue(vendorId, forKey: "vendor-id")
            }
            if let devId : NSData = IORegistryEntrySearchCFProperty(serviceObject,
                                                                    kIOServicePlane,
                                                                    "device-id" as CFString,
                                                                    kCFAllocatorDefault, opt) as? NSData {
              info.setValue(devId, forKey: "device-id")
            }
            if let revId : NSData = IORegistryEntrySearchCFProperty(serviceObject,
                                                                    kIOServicePlane,
                                                                    "revision-id" as CFString,
                                                                    kCFAllocatorDefault, opt) as? NSData {
              info.setValue(revId, forKey: "revision-id")
            }
            if let subSysId : NSData = IORegistryEntrySearchCFProperty(serviceObject,
                                                                       kIOServicePlane,
                                                                       "subsystem-id" as CFString,
                                                                       kCFAllocatorDefault, opt) as? NSData {
              info.setValue(subSysId, forKey: "subsystem-id")
            }
            if let subSysVenId : NSData = IORegistryEntrySearchCFProperty(serviceObject,
                                                                          kIOServicePlane,
                                                                          "subsystem-vendor-id" as CFString,
                                                                          kCFAllocatorDefault, opt) as? NSData {
              info.setValue(subSysVenId, forKey: "subsystem-vendor-id")
            }
            /*
            if let model : NSString = IORegistryEntrySearchCFProperty(serviceObject, kIOServicePlane, "model" as CFString, kCFAllocatorDefault, opt) as? NSString {
              print(model)
              info.setValue(model, forKey: "model")
            }*/
            if let acpipath : NSString = IORegistryEntrySearchCFProperty(serviceObject,
                                                                         kIOServicePlane,
                                                                         "acpi-path" as CFString,
                                                                         kCFAllocatorDefault, opt) as? NSString {
              //print(acpipath)
              info.setValue(acpipath, forKey: "acpi-path")
            } else {
              info.setValue("unknown" as NSString, forKey: "acpi-path")
            }
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
    let fontAttr =  [NSAttributedString.Key.font : gLogFont] // need to count a size with proportional font
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
