//
//  Graphics.swift
//  HWMonitorSMC2
//
//  Created by vector sigma on 30/04/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Foundation
import Metal

public struct Graphics {
  fileprivate var Intel_ID  : Data = Data([0x86, 0x80, 0x00, 0x00])
  fileprivate var AMD_ID    : Data = Data([0x02, 0x10, 0x00, 0x00])
  fileprivate var NVidia_ID : Data = Data([0xDE, 0x10, 0x00, 0x00])
  
  /*
   The public getGraphicsInfo() function return a detailed log for each
   pci-GPU in the System
   */
  public func getGraphicsInfo() -> String {
    var log : String = ""
    var vramLogged : Bool = false
    let list = Graphics.listGraphicsInfo()
    for i in 0..<list.count {
      let dict = list[i]
      //print(dict)
      log += "VIDEO CARD \(i + 1):\n"
      
      // expected value:
      var model             : String = "Unknown" // model can be String/Data
      let modelValue        : Any? = dict.object(forKey: "model")
      let vendorID          : Data = dict.object(forKey: "vendor-id") as! Data
      let deviceID          : Data = dict.object(forKey: "device-id") as! Data
      let classcode         : Data = dict.object(forKey: "class-code") as! Data
      let revisionID        : Data = dict.object(forKey: "revision-id") as! Data
      let subsystemID       : Data = dict.object(forKey: "subsystem-id") as! Data
      let subsystemVendorID : Data = dict.object(forKey: "subsystem-vendor-id") as! Data
      
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
      if let ioName : String = dict.object(forKey: "IOName") as? String {
        log += "\tIOName:\t\t\t\t\(ioName)\n"
      }
      if let pcidebug : String = dict.object(forKey: "pcidebug") as? String {
        log += "\tpcidebug:\t\t\t\t\(pcidebug)\n"
      }
      if let builtin : Data = dict.object(forKey: "built-in") as? Data {
        log += "\tbuilt-in:\t\t\t\t\(builtin.hexadecimal())\n"
      }
      if let compatible : Data = dict.object(forKey: "compatible") as? Data {
        log += "\tcompatible:\t\t\t\(String(data: compatible, encoding: .utf8) ?? "Unknown")\n"
      }
      if let acpipath : String = dict.object(forKey: "acpi-path") as? String {
        log += "\tacpi-path:\t\t\t\t\(acpipath)\n"
      }
      if let hdagfx : Data = dict.object(forKey: "hda-gfx") as? Data {
        log += "\thda-gfx:\t\t\t\t\(String(data: hdagfx, encoding: .utf8) ?? "Unknown")\n"
      }

      // NVidia property (mostly)
      if let rmBoardNm : Data = dict.object(forKey: "rm_board_number") as? Data {
        log += "\trm_board_number:\t\t\(rmBoardNm.hexadecimal())\n"
      }
      if let noEFI : Data = dict.object(forKey: "NVDA,noEFI") as? Data {
        log += "\tNVDA,noEFI:\t\t\t\(String(data: noEFI, encoding: .utf8) ?? "Unknown")\n"
      }
      if let nVArch : String = dict.object(forKey: "NVArch") as? String {
        log += "\tNVArch:\t\t\t\t\t\(nVArch)\n"
      }
      if let romRev : Data = dict.object(forKey: "rom-revision") as? Data {
        log += "\trom-revision:\t\t\t\t\(String(data: romRev, encoding: .utf8) ?? "Unknown")\n"
      }
      if let nVClass : String = dict.object(forKey: "NVCLASS") as? String {
        log += "\tNVCLASS:\t\t\t\t\(nVClass)\n"
      }
      if let ncCap : Data = dict.object(forKey: "NVCAP") as? Data {
        log += "\tNVCAP:\t\t\t\t\(ncCap.hexadecimal())\n"
      }
      if let aspm : NSNumber = dict.object(forKey: "pci-aspm-default") as? NSNumber {
        log += "\tpci-aspm-default:\t\t\t\t\(String(format: "0x%X", aspm.intValue))\n"
      }
      if let vram : Data = dict.object(forKey: "VRAM,totalMB") as? Data {
        log += "\tVRAM,totalMB:\t\t\t\(vram.hexadecimal())\n"
        vramLogged = true
      }
      if let deviceType : Data = dict.object(forKey: "device_type") as? Data {
        log += "\tdevice_type:\t\t\t\(String(data: deviceType, encoding: .utf8) ?? "Unknown")\n"
      }
      if let accelLoaded : Data = dict.object(forKey: "NVDA,accel-loaded") as? Data {
        log += "\tNVDA,accel-loaded:\t\t\(accelLoaded.hexadecimal())\n"
      }
      if let vbiosRev : Data = dict.object(forKey: "vbios-revision") as? Data {
        log += "\tvbios-revision:\t\t\t\(vbiosRev.hexadecimal())\n"
      }
      if let nvdaFeatures : Data = dict.object(forKey: "NVDA,Features") as? Data {
        log += "\tvNVDA,Features:\t\t\t\(nvdaFeatures.hexadecimal())\n"
      }
      if let nvramProperty : Bool = dict.object(forKey: "IONVRAMProperty") as? Bool {
        log += "\tIONVRAMProperty:\t\t\t\(nvramProperty)\n"
      }
      if let initgl : String = dict.object(forKey: "NVDAinitgl_created") as? String {
        log += "\tNVDAinitgl_created:\t\t\(initgl)\n"
      }
      if let pciMSImode : Bool = dict.object(forKey: "IOPCIMSIMode") as? Bool {
        log += "\tIOPCIMSIMode\t\t\t\(pciMSImode)\n"
      }
      if let nvdaType : String = dict.object(forKey: "NVDAType") as? String {
        log += "\tNVDAType:\t\t\t\t\(nvdaType)\n"
      }

      log += "\tAdditional Properties:\n"
      if let aapls = getProperties(with: "AAPL", in: dict) {
        for key in (aapls.keys) {
          log += "\(key)\(aapls[key]!)\n"
        }
      }
      if let snail = getProperties(with: "@", in: dict) {
        for key in (snail.keys) {
          log += "\(key)\(snail[key]!)\n"
        }
      }
      if let aty = getProperties(with: "ATY", in: dict) {
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
          acceleratorDict = Graphics.listAcceleratorsInfo(with: metal.registryID, primaryMatch: primaryMatch)
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
    
    let fontAttr =  [NSAttributedStringKey.font : gLogFont!] // need to count a size with proportional font
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
          let raw : Any = dict.object(forKey: key)! // unrapped because we know it exist
          if raw is NSString {
            value = (raw as! String)
          } else if raw is NSData {
            let data : Data = (raw as! Data)
            value = "\(data.hexadecimal())"
          } else if raw is NSNumber {
            value = "\((raw as! NSNumber).intValue)"
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
      if KERN_SUCCESS == err  {
        repeat {
          serviceObject = IOIteratorNext(iter)
          let opt : IOOptionBits = IOOptionBits(kIORegistryIterateParents | kIORegistryIterateRecursively)
          var serviceDictionary : Unmanaged<CFMutableDictionary>?
          if IORegistryEntryCreateCFProperties(serviceObject, &serviceDictionary, kCFAllocatorDefault, opt) != kIOReturnSuccess {
            IOObjectRelease(serviceObject)
            continue
          }
          if let info : NSDictionary = serviceDictionary?.takeUnretainedValue() {
            if (info.object(forKey: "model") != nil) && (info.object(forKey: "class-code") != nil) {
              if let classcode : Data = info.object(forKey: "class-code") as? Data {
                if classcode == Data([0x00, 0x00, 0x03, 0x00]) {
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
   listAcceleratorsInfo(with entryID, primaryMatch) return a dictionary
   for the IOAccelerator object that match the vendor/device id string
   */
  fileprivate static func listAcceleratorsInfo(with entryID : UInt64, primaryMatch: String) -> NSDictionary? {
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
          if let info : NSDictionary = serviceDictionary?.takeUnretainedValue() {
            if let IOPCIPrimaryMatch : String = info.object(forKey: "IOPCIPrimaryMatch") as? String {
              if (IOPCIPrimaryMatch.lowercased().range(of: primaryMatch) != nil) {
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
          if let info : NSDictionary = serviceDictionary?.takeUnretainedValue() {
            if let classcode : String = info.object(forKey: "IOPCIClassMatch") as? String{
              if classcode.lowercased() == "0x03000000&0xff000000" && ((info.object(forKey: "IOPCIPrimaryMatch") != nil)) {
                cards.append(info)
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
   getPerformanceStatistics() return a dictionary with object and keys already formatted for our log
   */
  fileprivate func getPerformanceStatistics(in dict : NSDictionary) -> [String: String]? {
    let fontAttr =  [NSAttributedStringKey.font : gLogFont!] // need to count a size with proportional font
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
      let raw : Any = dict.object(forKey: key)! // unrapped because we know it exist
      if raw is NSString {
        value = (raw as! String)
      } else if raw is NSData {
        let data : Data = (raw as! Data)
        value = "\(data.hexadecimal())"
      } else if raw is NSNumber {
        value = "\((raw as! NSNumber).intValue)"
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
