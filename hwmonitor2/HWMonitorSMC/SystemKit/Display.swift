//
//  Display.swift
//  HWMonitorSMC2
//
//  Created by vector sigma on 25/04/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import IOKit.graphics
import Foundation

public struct Display {
  
  //--------------------------------------------------------------------------
  // MARK: PUBLIC INITIALIZERS
  //--------------------------------------------------------------------------
  
  
  public init() { }
  
  //--------------------------------------------------------------------------
  // MARK: public functions
  //--------------------------------------------------------------------------
  /**
   return detailed info about main screen only
   */
  public static func getMainScreenInfo() -> String {
    var displayLocations : [String] = [String]()
    if let screen = NSScreen.main {
      return self.getDisplayInfo(screen: screen, displayLocations: &displayLocations)
    }
    return ""
  }
  
  /**
   return detailed info about all screens
   */
  public static func getScreensInfo() -> String {
    var displayLocations : [String] = [String]()
    var log : String = ""
    let screens = NSScreen.screens
    var count : Int = 0
    for screen in screens {
      log += "   SCREEN \(count):\n"
      log += self.getDisplayInfo(screen: screen, displayLocations: &displayLocations)
      log += "\n"
      count += 1
    }
    return log
  }
  
  //--------------------------------------------------------------------------
  // MARK: Display Info
  //--------------------------------------------------------------------------
  
  /**
   function to find detailed info about NSScreen objects.
   Only one problem: users can have multiple displays with the same vendor id and product id,
   but kDisplaySerialString and kDisplaySerialNumber not always are present:
   the difference surely is the kIODisplayLocationKey (path in the IOService).
   Iterating screens the code should break only if "displayLocations" doesn't contains
   the current location.
   Hoping IOKit and NSScreen returns in the same order..but anyway.. who cares?
   */
  public static func getDisplayInfo(screen: NSScreen, displayLocations: inout [String]) -> String {
    var statusString : String = ""
    var productName : String = "Unknown"
    let deviceDescription = screen.deviceDescription
    let screenNumber : NSNumber = deviceDescription[NSDeviceDescriptionKey.init(rawValue: "NSScreenNumber")] as! NSNumber
    let size : NSSize = deviceDescription[NSDeviceDescriptionKey.init(rawValue: "NSDeviceSize")] as! NSSize
    
    
    statusString += "\tFramebuffer: \(String(format: "0x%X", screenNumber.uint32Value))\n"
    statusString += "\tSize: \(Int(size.width))x\(Int(size.height))\n"
    statusString += "\tDepth bits Per Pixel: \(screen.depth.bitsPerPixel)\n"
    statusString += "\tDepth bits Per Sample: \(screen.depth.bitsPerSample)\n"
    statusString += "\tDepth is Planar: \(screen.depth.isPlanar)\n"
    statusString += "\tFrame: \(screen.frame)\n"
    statusString += "\tVisible Frame: \(screen.visibleFrame)\n"
    statusString += "\tDepth backing Scale Factor: \(screen.backingScaleFactor)\n"
    
    if let info = GetInfoFromCGDisplayID(displayID: screenNumber.uint32Value, displayLocations: &displayLocations) {
      if let localizedNames : NSDictionary = info.object(forKey: kDisplayProductName) as? NSDictionary {
        if (localizedNames.object(forKey: "en_US") != nil) {
          productName = localizedNames.object(forKey: "en_US") as! String
        }
      }
      statusString += "\tName: \(productName)\n"
      if let vendorID : NSNumber = info.object(forKey: kDisplayVendorID) as? NSNumber {
        statusString += "\tVendor Id: \(String(format: "0x%X", vendorID.uint32Value)) (\(vendorID.uint32Value))\n"
      }
      if let productID : NSNumber = info.object(forKey: kDisplayProductID) as? NSNumber {
        statusString += "\tProduct Id: \(String(format: "0x%X", productID.uint32Value)) (\(productID.uint32Value))\n"
      }
      if let DisplaySerialNumber : NSNumber = info.object(forKey: kDisplaySerialNumber) as? NSNumber {
        statusString += "\tSerial Number: \(DisplaySerialNumber.intValue)\n"
      }
      if let DisplaySerialString : String = info.object(forKey: kDisplaySerialString) as? String {
        statusString += "\tSerial (string): \(DisplaySerialString)\n"
      }
      if let DisplayYearOfManufacture : NSNumber = info.object(forKey: kDisplayYearOfManufacture) as? NSNumber {
        statusString += "\tYear Of Manufacture: \(DisplayYearOfManufacture.intValue)\n"
      }
      if let DisplayWeekOfManufacture : NSNumber = info.object(forKey: kDisplayWeekOfManufacture) as? NSNumber {
        statusString += "\tWeek of Manufacture: \(DisplayWeekOfManufacture.intValue)\n"
      }
      if let DisplayBluePointX : NSNumber = info.object(forKey: kDisplayBluePointX) as? NSNumber {
        statusString += "\tBlue Point X: \(DisplayBluePointX.doubleValue)\n"
      }
      if let DisplayBluePointY : NSNumber = info.object(forKey: kDisplayBluePointY) as? NSNumber {
        statusString += "\tBlue Point Y: \(DisplayBluePointY.doubleValue)\n"
      }
      if let DisplayGreenPointX : NSNumber = info.object(forKey: kDisplayGreenPointX) as? NSNumber {
        statusString += "\tGreen Point Y: \(DisplayGreenPointX.doubleValue)\n"
      }
      if let DisplayGreenPointY : NSNumber = info.object(forKey: kDisplayGreenPointY) as? NSNumber {
        statusString += "\tGreen Point Y: \(DisplayGreenPointY.doubleValue)\n"
      }
      if let DisplayRedPointX : NSNumber = info.object(forKey: kDisplayRedPointX) as? NSNumber {
        statusString += "\tRed Point X: \(DisplayRedPointX.doubleValue)\n"
      }
      if let DisplayRedPointY : NSNumber = info.object(forKey: kDisplayRedPointY) as? NSNumber {
        statusString += "\tRed Point Y: \(DisplayRedPointY.doubleValue)\n"
      }
      if let DisplayWhitePointX : NSNumber = info.object(forKey: kDisplayWhitePointX) as? NSNumber {
        statusString += "\tWhite Point X: \(DisplayWhitePointX.doubleValue)\n"
      }
      if let DisplayWhitePointY : NSNumber = info.object(forKey: kDisplayWhitePointY) as? NSNumber {
        statusString += "\tWhite Point Y: \(DisplayWhitePointY.doubleValue)\n"
      }
      if let DisplayWhiteGamma : NSNumber = info.object(forKey: kDisplayWhiteGamma) as? NSNumber {
        statusString += "\tWhite Gamma: \(DisplayWhiteGamma.doubleValue)\n"
      }
      if let DisplayBrightnessAffectsGamma : NSNumber = info.object(forKey: kDisplayBrightnessAffectsGamma) as? NSNumber {
        statusString += "\tBrightness Affects Gamma: \(DisplayBrightnessAffectsGamma.boolValue)\n"
      }
      if let DisplayHorizontalImageSize : NSNumber = info.object(forKey: kDisplayHorizontalImageSize) as? NSNumber {
        statusString += "\tHorizontal Image Size: \(DisplayHorizontalImageSize.intValue)\n"
      }
      if let DisplayVerticalImageSize : NSNumber = info.object(forKey: kDisplayVerticalImageSize) as? NSNumber {
        statusString += "\tVertical Image Size: \(DisplayVerticalImageSize.intValue)\n"
      }
      if let IODisplayHasBacklight : NSNumber = info.object(forKey: kIODisplayHasBacklightKey) as? NSNumber {
        statusString += "\tHas Back light: \(IODisplayHasBacklight.boolValue)\n"
      }
      if let IODisplayIsDigital : NSNumber = info.object(forKey: kIODisplayIsDigitalKey) as? NSNumber {
        statusString += "\tIs Digital: \(IODisplayIsDigital.boolValue)\n"
      }
      if let IODisplayIsHDMISink : NSNumber = info.object(forKey: "IODisplayIsHDMISink") as? NSNumber {
        statusString += "\tIs HDMI Sink: \(IODisplayIsHDMISink.boolValue)\n"
      }
      
      //EDID
      if let IODisplayEDID : Data = info.object(forKey: kIODisplayEDIDKey) as? Data {
        let bytes = IODisplayEDID.withUnsafeBytes {
          [UInt8](UnsafeBufferPointer(start: $0, count: IODisplayEDID.count))
        }
        
        statusString += "\n\tEDID data:\n"
        var byte8Count = 0
        var byteCount = 0
        for byte in bytes {
          byte8Count += 1
          byteCount += 1
          let indent = (byte8Count == 1) ? "\t" : ""
          let eol = (byte8Count == 8) ? "\n" : ""
          
          if byte8Count == 8 {
            byte8Count = 0
          }
          // separating bytes with a comma helps developers ;-)
          statusString += indent + String(format: "0x%02X", byte) + ((byteCount < bytes.count) ? ", " : "") + eol
        }
        
        if let IODisplayEDIDOriginal : Data = info.object(forKey: kIODisplayEDIDOriginalKey) as? Data {
          statusString += (IODisplayEDIDOriginal == IODisplayEDID) ? "\n\tEDID comes from EEPROM" : "EDID is overriden\n"
        }
      }
    }
    
    return statusString
  }
  
  //--------------------------------------------------------------------------
  // MARK: Info Dictionary from displayID
  //--------------------------------------------------------------------------
  
  
  public static func GetInfoFromCGDisplayID(displayID: CGDirectDisplayID,
                                      displayLocations: inout [String]) -> NSDictionary? {
    var serv : io_object_t
    var iter = io_iterator_t()
    let matching = IOServiceMatching("IODisplayConnect")
    var dict : NSDictionary? = nil
    let err = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                           matching,
                                           &iter)
    if err == KERN_SUCCESS && iter != 0 {
      if KERN_SUCCESS == err  {
        repeat {
          serv = IOIteratorNext(iter)
          let opt : IOOptionBits = IOOptionBits(0)
          if let info : NSDictionary =
            IODisplayCreateInfoDictionary(serv, opt).takeRetainedValue() as NSDictionary? {
            let vendorID : NSNumber? = info.object(forKey: kDisplayVendorID) as? NSNumber
            let productID : NSNumber? = info.object(forKey: kDisplayProductID) as? NSNumber
            let location : String? = info.object(forKey: kIODisplayLocationKey) as? String
            if (vendorID != nil) &&
              (productID != nil) &&
              (location  != nil) &&
              CGDisplayVendorNumber(displayID) == vendorID?.uint32Value &&
              CGDisplayModelNumber(displayID) == productID?.uint32Value &&
              (!displayLocations.contains(location!)) {
              displayLocations.append(location!)
              dict = info
            }
          }
          IOObjectRelease(serv)
          if (dict != nil) {
            break
          }
        } while serv != 0
      }
      IOObjectRelease(iter)
    }
    return dict
  }
}
