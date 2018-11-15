//
//  Extensions.swift
//  HWMonitorSMC2
//
//  Created by vector sigma on 25/04/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Foundation

extension String {
  public func locale() -> String {
    return NSLocalizedString(self, comment: "")
  }
  
  public func noSpaces() -> String {
    return self.trimmingCharacters(in: CharacterSet.whitespaces)
  }
  
  // require
  public func withFormat(_ arg: Any) -> String {
    return String(format: self, "\(arg)")
  }
}
  

extension Data {
  public func hexadecimal() -> String {
    var hex : String = ""
    for i in 0..<self.count {
      hex += String(format: "%02x ", self[i])
    }
    return hex.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

extension UInt8 {
  var data: Data {
    var p = self
    return Data(bytes: &p, count: MemoryLayout<UInt8>.size)
  }
}

extension UInt16 {
  var data: Data {
    var p = self
    return Data(bytes: &p, count: MemoryLayout<UInt16>.size)
  }
}

extension UInt32 {
  var data: Data {
    var p = self
    return Data(bytes: &p, count: MemoryLayout<UInt32>.size)
  }
}

// HWMonitorSMC2 debug
extension NSDictionary {
  public func writeIOAcc(with name: String) {
    let dir = NSHomeDirectory() + "/Desktop/HWGraphics"
    if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Desktop/HWGraphics") {
      self.write(toFile: "\(dir)/IOAccelerator_\(name).plist", atomically: true)
    }
  }
  
  public func writeGraphicsInf(with name: String) {
    let dir = NSHomeDirectory() + "/Desktop/HWGraphics"
    if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Desktop/HWGraphics") {
      self.write(toFile: "\(dir)/Inf_\(name).plist", atomically: true)
    }
  }
}
