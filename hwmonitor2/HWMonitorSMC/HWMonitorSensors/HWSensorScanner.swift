//
//  HWSensorsScanner.swift
//  HWMonitorSMC2
//
//  Created by Vector Sigma on 23/10/2018.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

//MARK: Decoding functions
func smcFormat(_ num: Int) -> String {
  if num > 15 {
    let GZ = (0..<20).map({Character(UnicodeScalar("G".unicodeScalars.first!.value + $0)!)})
    for c in GZ {
      let i = Int(c.unicodeScalars.first!.value) - 55
      if i == num {
        return "\(c)"
      }
    }
  }
  return String(format: "%.1X", num)
}

fileprivate func swapBytes(_ value: UInt) -> UInt {
  return UInt(((Int(value) & 0xff00) >> 8) | ((Int(value) & 0xff) << 8))
}

fileprivate func getIndexOfHex(char: Character) -> Int {
  let v = Int(char.unicodeScalars.first!.value)
  return v > 96 && v < 103 ? v - 87 : v > 47 && v < 58 ? v - 48 : 0
}

fileprivate func decodeNumericValue(from data: Data, dataType: DataType) -> Double {
  if data.count > 0 {
    let type = [Character](dataType.type.toString())
    if (type[0] == "u" || type[0] == "s") && type[1] == "i" {
      let signd : Bool = type[0] == "s"
      
      switch type[2] {
      case "8":
        if data.count == 1 {
          var encoded : UInt8 = 0
          bcopy((data as NSData).bytes, &encoded, 1)
          
          if signd && (Int(encoded) & 1 << 7) > 0 {
            encoded &= ~(1 << 7)
            return -Double(encoded)
          }
          return Double(encoded)
        }
      case "1":
        if type[3] == "6" && data.count == 2 {
          var encoded: UInt16 = 0
          
          bcopy((data as NSData).bytes, &encoded, 2)
          encoded = UInt16(bigEndian: encoded)
          
          if signd && (Int(encoded) & 1 << 15) > 0 {
            encoded &= ~(1 << 15)
            return -Double(encoded)
          }
          return Double(encoded)
        }
      case "3":
        if type[3] == "2" && data.count == 4 {
          var encoded: UInt32 = 0
          
          bcopy((data as NSData).bytes, &encoded, 4)
          encoded = UInt32(bigEndian: encoded)
          
          if signd && (Int(encoded) & 1 << 31) > 0 {
            encoded &= ~(1 << 31)
            return -Double(encoded)
          }
          return Double(encoded)
        }
      default:
        break
      }
    } else if (type[0] == "f" || type[0] == "s") && type[1] == "p" && data.count == 2 {
      
      var encoded: UInt16 = 0
      bcopy((data as NSData).bytes, &encoded, 2)
      let i = getIndexOfHex(char: type[2])
      let f = getIndexOfHex(char: type[3])
      
      if (i + f) != ((type[0] == "s") ? 15 : 16) {
        return 0
      }
      
      var swapped = UInt16(bigEndian: encoded)
      let signd : Bool = type[0] == "s"
      let minus : Bool = (Int(swapped) & 1 << 15) > 0
      
      if signd && minus {
        swapped &= ~(1 << 15)
      }
      return (Double(swapped) / Double(1 << f)) * ((signd && minus) ? -1 : 1)
    }
  }
  return 0
}

class HWSensorsScanner: NSObject {
  func getType(_ key: String) -> DataType? {
    let type : DataType? = gSMC.getType(key: FourCharCode.init(fromString: key))
    return type
  }
  
  //MARK:  Monitoring functions
  func getMemory() -> [HWMonitorSensor] {
    var arr = [HWMonitorSensor]()
    let percentage : Bool = UDs.bool(forKey: "useMemoryPercentage")
    let unit : HWUnit = percentage ? HWUnit.Percent : HWUnit.MB
    let sensorType : HWSensorType = .memory
    let logtype : LogType = .memoryLog
    let type = "RAM"
    let format = "%.f"
    
    var s = HWMonitorSensor(key: "RAM TOTAL",
                            unit: HWUnit.MB,
                            type: type,
                            sensorType: sensorType,
                            title: "Total".locale(),
                            canPlot: false)
    s.logType = logtype
    s.format = format
    s.favorite = UDs.bool(forKey: s.key)
    s.doubleValue = SSMemoryInfo.totalMemory()
    s.stringValue = "\(NSNumber(value: s.doubleValue).intValue)"
    arr.append(s)
    
    s = HWMonitorSensor(key: "RAM ACTIVE",
                        unit: unit,
                        type: type,
                        sensorType: sensorType,
                        title: "Active".locale(),
                        canPlot: true)
    s.logType = logtype
    s.format = format
    s.unit = unit
    s.favorite = UDs.bool(forKey: s.key)
    s.doubleValue = SSMemoryInfo.activeMemory(percentage)
    s.stringValue = String(format: format, s.doubleValue)
    arr.append(s)
    
    s = HWMonitorSensor(key: "RAM INACTIVE",
                        unit: unit,
                        type: type,
                        sensorType: sensorType,
                        title: "Inactive".locale(),
                        canPlot: true)
    s.logType = logtype
    s.format = format
    s.unit = unit
    s.favorite = UDs.bool(forKey: s.key)
    s.doubleValue = SSMemoryInfo.inactiveMemory(percentage)
    s.stringValue = String(format: format, s.doubleValue)
    arr.append(s)
    
    s = HWMonitorSensor(key: "RAM FREE",
                        unit: unit,
                        type: type,
                        sensorType: sensorType,
                        title: "Free".locale(),
                        canPlot: true)
    s.logType = logtype
    s.format = format
    s.unit = unit
    s.favorite = UDs.bool(forKey: s.key)
    s.doubleValue = SSMemoryInfo.freeMemory(percentage)
    s.stringValue = String(format: format, s.doubleValue)
    arr.append(s)
    
    s = HWMonitorSensor(key: "RAM USED",
                        unit: unit,
                        type: type,
                        sensorType: sensorType,
                        title: "Used".locale(),
                        canPlot: true)
    s.logType = logtype
    s.format = format
    s.unit = unit
    s.favorite = UDs.bool(forKey: s.key)
    s.doubleValue = SSMemoryInfo.usedMemory(percentage)
    s.stringValue = String(format: format, s.doubleValue)
    arr.append(s)
    
    s = HWMonitorSensor(key: "RAM PURGEABLE",
                        unit: unit,
                        type: type,
                        sensorType: sensorType,
                        title: "Purgeable".locale(),
                        canPlot: true)
    s.logType = logtype
    s.format = format
    s.unit = unit
    s.favorite = UDs.bool(forKey: s.key)
    s.doubleValue = SSMemoryInfo.purgableMemory(percentage)
    s.stringValue = String(format: format, s.doubleValue)
    arr.append(s)
    
    s = HWMonitorSensor(key: "RAM WIRED",
                        unit: unit,
                        type: type,
                        sensorType: sensorType,
                        title: "Wired".locale(),
                        canPlot: true)
    s.logType = logtype
    s.format = format
    s.unit = unit
    s.favorite = UDs.bool(forKey: s.key)
    s.doubleValue = SSMemoryInfo.wiredMemory(percentage)
    s.stringValue = String(format: format, s.doubleValue)
    arr.append(s)
    
    // DIMM temperaturea. 16 Slots max (?)
    for i in 0..<16 {
      let a : String = smcFormat(i)
      let _ = self.addSMCSensorIfValid(key: SMC_DIMM_TEMP.withFormat(a),
                                       type: DataTypes.SP78,
                                       unit: .C,
                                       sensorType: .temperature,
                                       title: String(format: "DIMM %d".locale(), i),
                                       logType: logtype,
                                       canPlot: true,
                                       list: &arr)
    }
    return arr
  }
  
  /// returns CPU Power/voltages/Multipliers from both SMC and Intel Power Gadget
  func get_CPU_GlobalParameters() -> [HWMonitorSensor] {
    var arr = [HWMonitorSensor]()
    let logtype : LogType = .cpuLog
    let cpuCount = gCountPhisycalCores()
    
    let igp : Bool = AppSd.ipgInited
    
    // CPU Power
    if igp {
      arr.append(contentsOf: getIntelPowerGadgetCPUSensors())
    }
    
    let _ =  self.addSMCSensorIfValid(key: SMC_CPU_PROXIMITY_TEMP,
                                      type: DataTypes.SP78,
                                      unit: .C,
                                      sensorType: .temperature,
                                      title: "Proximity".locale(),
                                      logType: logtype,
                                      canPlot: false,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_CPU_PACKAGE_CORE_WATT,
                                      type: DataTypes.SP78,
                                      unit: .Watt,
                                      sensorType: .cpuPowerWatt,
                                      title: "Package Core".locale(),
                                      logType: logtype,
                                      canPlot: true,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_CPU_PACKAGE_TOTAL_WATT,
                                      type: DataTypes.SP78,
                                      unit: .Watt,
                                      sensorType: .cpuPowerWatt,
                                      title: "Package Total".locale(),
                                      logType: logtype,
                                      canPlot: true,
                                      list: &arr)
    
    
    let _ =  self.addSMCSensorIfValid(key: SMC_CPU_HEATSINK_TEMP,
                                      type: DataTypes.SP78,
                                      unit: .C,
                                      sensorType: .temperature,
                                      title: "Heatsink".locale(),
                                      logType: logtype,
                                      canPlot: false,
                                      list: &arr)
    
    // CPU voltages
    let _ =  self.addSMCSensorIfValid(key: SMC_CPU_VOLT,
                                      type: DataTypes.FP2E,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "Voltage".locale(),
                                      logType: logtype,
                                      canPlot: false,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_CPU_VRM_VOLT,
                                      type: DataTypes.FP2E,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "VRM Voltage".locale(),
                                      logType: logtype,
                                      canPlot: false,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_CPU_PACKAGE_MULTI_F,
                                      type: DataTypes.FP4C,
                                      unit: .none,
                                      sensorType: .multiplier,
                                      title: "Package Multiplier".locale(),
                                      logType: logtype,
                                      canPlot: false,
                                      list: &arr)
    
    for i in 0..<cpuCount {
      let a : String = smcFormat(i)
      let _ =  self.addSMCSensorIfValid(key: SMC_CPU_CORE_MULTI_F.withFormat(a),
                                        type: DataTypes.FP4C,
                                        unit: .none,
                                        sensorType: .multiplier,
                                        title: String(format: "Core %d Multiplier".locale(), i),
                                        logType: logtype,
                                        canPlot: false,
                                        list: &arr)
    }
    return arr
  }
  
  /// returns CPU cores Temperatures from the SMC
  func getSMC_SingleCPUTemperatures() -> [HWMonitorSensor] {
    var arr = [HWMonitorSensor]()
    let logtype : LogType = .cpuLog
    let cpuCount = gCountPhisycalCores() * gCPUPackageCount()
    
    let upper : Bool = getType(SMC_CPU_CORE_TEMP_NEW.withFormat(0)) == nil // TC0C vs TC0c
    for i in 0..<cpuCount {
      let a : String = smcFormat(i)
      let _ = self.addSMCSensorIfValid(key: (upper ? SMC_CPU_CORE_TEMP.withFormat(a) : SMC_CPU_CORE_TEMP_NEW.withFormat(a)),
                                       type: DataTypes.SP78,
                                       unit: .C,
                                       sensorType: .temperature,
                                       title: String(format: "Core %d".locale(), i),
                                       logType: logtype,
                                       canPlot: true,
                                       list: &arr)
    }
 
    for i in 0..<cpuCount {
      let a : String = smcFormat(i)
      let _ = self.addSMCSensorIfValid(key: SMC_CPU_CORE_DIODE_TEMP.withFormat(a),
                                       type: DataTypes.SP78,
                                       unit: .C,
                                       sensorType: .temperature,
                                       title: String(format: "Diode %d".locale(), i),
                                       logType: logtype,
                                       canPlot: true,
                                       list: &arr)
    }
    return arr
  }
  
  /// returns CPU cores Frequencies from the SMC (keys are not vanilla but IntelCPUMonitor stuff)
  func getSMC_SingleCPUFrequencies() -> [HWMonitorSensor] {
    var arr = [HWMonitorSensor]()
    let logtype : LogType = .cpuLog
    let cpuCount = gCountPhisycalCores() * gCPUPackageCount()
    
    for i in 0..<cpuCount {
      let a : String = smcFormat(i)
      let _ = self.addSMCSensorIfValid(key: SMC_CPU_CORE_FREQ_F.withFormat(a),
                                       type: DataTypes.FREQ,
                                       unit: .MHz,
                                       sensorType: .frequencyCPU,
                                       title: String(format: "Core %d".locale(), i),
                                       logType: logtype,
                                       canPlot: true,
                                       list: &arr)
    }
    return arr
  }
  
  /// returns GPUs sensors
  func getSMCGPU() -> [HWMonitorSensor] {
    var arr = [HWMonitorSensor]()
    let logtype : LogType = .cpuLog
    
    for i in 0..<10 {
      let a : String = smcFormat(i)
      let _ = self.addSMCSensorIfValid(key: SMC_GPU_FREQ_F.withFormat(a),
                                       type: DataTypes.FREQ,
                                       unit: .MHz,
                                       sensorType: .frequencyGPU,
                                       title: String(format: "GPU %d Core".locale(), i),
                                       logType: logtype,
                                       canPlot: true,
                                       list: &arr)
      let _ = self.addSMCSensorIfValid(key: SMC_GPU_SHADER_FREQ_F.withFormat(a),
                                       type: DataTypes.FREQ,
                                       unit: .MHz,
                                       sensorType: .frequencyGPU,
                                       title: String(format: "GPU %d Shaders".locale(), i),
                                       logType: logtype,
                                       canPlot: true,
                                       list: &arr)
      let _ = self.addSMCSensorIfValid(key: SMC_GPU_MEMORY_FREQ_F.withFormat(a),
                                       type: DataTypes.FREQ,
                                       unit: .MHz,
                                       sensorType: .frequencyGPU,
                                       title: String(format: "GPU %d Memory".locale(), i),
                                       logType: logtype,
                                       canPlot: true,
                                       list: &arr)
      let _ = self.addSMCSensorIfValid(key: SMC_GPU_VOLT.withFormat(a),
                                       type: DataTypes.FP2E,
                                       unit: .Volt,
                                       sensorType:.voltage,
                                       title: String(format: "GPU %d Voltage".locale(), i),
                                       logType: logtype,
                                       canPlot: false,
                                       list: &arr)
      let _ = self.addSMCSensorIfValid(key: SMC_GPU_BOARD_TEMP.withFormat(a),
                                       type: DataTypes.SP78,
                                       unit: .C,
                                       sensorType:.temperature,
                                       title: String(format: "GPU %d Board".locale(), i),
                                       logType: logtype,
                                       canPlot: true,
                                       list: &arr)
      let _ = self.addSMCSensorIfValid(key: SMC_GPU_PROXIMITY_TEMP.withFormat(a),
                                       type: DataTypes.SP78,
                                       unit: .C,
                                       sensorType:.temperature,
                                       title: String(format: "GPU %d Proximity".locale(), i),
                                       logType: logtype,
                                       canPlot: true,
                                       list: &arr)
    }
    return arr
  }
  
  func getIGPUPackagePower() -> HWMonitorSensor? {
    var arr : [HWMonitorSensor] = [HWMonitorSensor]()
    let _ =  self.addSMCSensorIfValid(key: SMC_IGPU_PACKAGE_WATT,
                                      type: DataTypes.SP78,
                                      unit: .Watt,
                                      sensorType: .cpuPowerWatt,
                                      title: "Package IGPU".locale(),
                                      logType: LogType.gpuLog,
                                      canPlot: true,
                                      list: &arr)
    return (arr.count > 0) ? arr[0] : nil
  }
  
  func getMotherboard() -> [HWMonitorSensor] {
    var arr = [HWMonitorSensor]()
    let logtype : LogType = .systemLog
    
    let _ =  self.addSMCSensorIfValid(key: SMC_NORTHBRIDGE_TEMP,
                                      type: DataTypes.SP78,
                                      unit: .C,
                                      sensorType: .temperature,
                                      title: "North Bridge".locale(),
                                      logType: logtype,
                                      canPlot: true,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_AMBIENT_TEMP,
                                      type: DataTypes.SP78,
                                      unit: .C,
                                      sensorType: .temperature,
                                      title: "Ambient".locale(),
                                      logType: logtype,
                                      canPlot: true,
                                      list: &arr)
    
    // voltages
    // VBAT, @maoyeye has it but is it Apple stuff?
    let _ =  self.addSMCSensorIfValid(key: SMC_PRAM_BATTERY_VOLT,
                                      type: DataTypes.SP4B,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "PRAM Battery".locale(),
                                      logType: logtype,
                                      canPlot: false,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_BUS_12V_VOLT,
                                      type: DataTypes.SP4B,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "+12V Bus Voltage".locale(),
                                      logType: logtype,
                                      canPlot: false,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_BUS_5V_VOLT,
                                      type: DataTypes.SP4B,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "+5V Bus Voltage".locale(),
                                      logType: logtype,
                                      canPlot: false,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_BUS_12VDIFF_VOLT,
                                      type: DataTypes.SP4B,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "-12V Bus Voltage".locale(),
                                      logType: logtype,
                                      canPlot: false,
                                      list: &arr)
    
    
    let _ =  self.addSMCSensorIfValid(key: SMC_BUS_5VDIFF_VOLT,
                                      type: DataTypes.SP4B,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "-5V Bus Voltage".locale(),
                                      logType: logtype,
                                      canPlot: false,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_BUS_3_3VCC_VOLT,
                                      type: DataTypes.FP2E,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "3.3 VCC Voltage".locale(),
                                      logType: logtype,
                                      canPlot: false,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_BUS_3_3VSB_VOLT,
                                      type: DataTypes.FP2E,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "3.3 VSB Voltage".locale(),
                                      logType: logtype,
                                      canPlot: false,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_BUS_3_3AVCC_VOLT,
                                      type: DataTypes.FP2E,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "3.3 AVCC Voltage".locale(),
                                      logType: logtype,
                                      canPlot: false,
                                      list: &arr)
    
    
    
    return arr
  }
  
  /// get Motherboard Fans (16 bytes) like the following fan 1: 01000100 4d422046 616e2031 00000000
  /// byte 0 is the type
  /// byte 1 is the zone
  /// byte 2 is the location
  /// byte 3 is reserved for future expansion
  /// byte [4-15] (12 in total) is a utf8 string containing the name
  func getFans() -> [HWMonitorSensor] {
    var arr = [HWMonitorSensor]()
    let logtype : LogType = .systemLog
    var FNum: Int = 0
    
    if let data : Data = gSMC.read(key: SMC_FAN_NUM_INT, type: getType(SMC_FAN_NUM_INT) ?? DataTypes.UI8) {
      bcopy([data[0]], &FNum, 1)
    } else {
      // FNum not even present
      FNum = 10
    }
    
    for i in 0..<FNum {
      let data : Data? = gSMC.read(key: SMC_FAN_ID_STR.withFormat(i),
                                   type: getType(SMC_FAN_ID_STR.withFormat(i)) ?? DataTypes.FDS)
      var name : String = String(format: "Fan %d".locale(), i)
      if (data != nil) && data!.count == 16 {
        name = String(data: data!.subdata(in: 4..<16), encoding: .utf8) ??
          String(format: "Fan %d".locale(), i)
      }
      
      let _ =  self.addSMCSensorIfValid(key: SMC_FAN_CURR_RPM.withFormat(i),
                                        type: DataTypes.FP2E,
                                        unit: .RPM,
                                        sensorType: .tachometer,
                                        title: "\(name.locale()) " + "speed".locale(),
                                        logType: logtype,
                                        canPlot: false,
                                        list: &arr)
      
      let _ =  self.addSMCSensorIfValid(key: SMC_FAN_MIN_RPM.withFormat(i),
                                        type: DataTypes.FP2E,
                                        unit: .RPM,
                                        sensorType: .tachometer,
                                        title: "\(name) " + "min speed".locale(),
                                        logType: logtype,
                                        canPlot: false,
                                        list: &arr)
      
      let _ =  self.addSMCSensorIfValid(key: SMC_FAN_MAX_RPM.withFormat(i),
                                        type: DataTypes.FP2E,
                                        unit: .RPM,
                                        sensorType: .tachometer,
                                        title: "\(name) " + "max speed".locale(),
                                        logType: logtype,
                                        canPlot: false,
                                        list: &arr)
      
    }
    return arr
  }
  
  /// returns Battery voltages and amperage. Taken from the driver
  func getBattery() -> [HWMonitorSensor] {
    var arr = [HWMonitorSensor]()
    let logtype : LogType = .batteryLog
    let pb : NSDictionary? = IOBatteryStatus.getIOPMPowerSource() as NSDictionary?
    if (pb != nil) {
      let voltage = IOBatteryStatus.getBatteryVoltage(from: pb as? [AnyHashable : Any])
      let amperage = IOBatteryStatus.getBatteryAmperage(from: pb as? [AnyHashable : Any])
      if voltage > -1 {
        let s = HWMonitorSensor(key: SMC_BATT0_VOLT,
                                unit: HWUnit.mV,
                                type: "BATT",
                                sensorType: .battery,
                                title: "Voltage".locale(),
                                canPlot: false)
        s.logType = logtype
        s.stringValue = String(format: "%d", voltage)
        s.doubleValue = Double(voltage)
        s.favorite = UDs.bool(forKey: s.key)
        arr.append(s)
      }
      
      if amperage > -1 {
        let s = HWMonitorSensor(key: SMC_BATT0_AMP,
                                unit: HWUnit.mA,
                                type: "BATT",
                                sensorType: .battery,
                                title: "Amperage".locale(),
                                canPlot: false)
        
        s.logType = logtype
        s.stringValue = String(format: "%d", amperage)
        s.doubleValue = Double(amperage)
        s.favorite = UDs.bool(forKey: s.key)
        
        arr.append(s)
      }
    }
    return arr
  }
  
  //MARK: SMC keys validation functions
  func validateValue(for sensor: HWMonitorSensor, data: Data, dataType: DataType) -> Bool {
    let v : Double = decodeNumericValue(from: data, dataType: dataType)
    var valid : Bool = false
    switch sensor.sensorType {
    case .temperature:
      if v > -15 && v < 150 {
        /*
         -10 min temp + 5 to ensure no one start a pc this way.
         150 (110 °C it is enough) to ensure reading is correct
         */
        sensor.stringValue = String(format: "%.f", v)
        sensor.doubleValue = v
        valid = true
      }
    case .battery: fallthrough /* only if from the smc */
    case .hdSmartLife:          /* only if from the smc */
      let t = data.withUnsafeBytes { (ptr: UnsafePointer<Int>) -> Int in
        return ptr.pointee
      }
      if t >= 0 && t <= 100 {
        sensor.stringValue = String(format: "%ld", t)
        sensor.doubleValue = v
        valid = true
      }
    case .voltage:
      sensor.stringValue = String(format: "%.3f", v)
      sensor.doubleValue = v
      valid = true // trusted?
    case .tachometer:
      sensor.stringValue = String(format: "%.0f", v)
      sensor.doubleValue = v
      valid = true // trusted?
    case .frequencyCPU:  fallthrough
    case .frequencyGPU:  fallthrough
    case .frequencyOther:
      var MHZ: UInt = 0
      bcopy((data as NSData).bytes, &MHZ, 2)
      MHZ = swapBytes(MHZ)
      if sensor.unit == .GHz {
        MHZ = MHZ / 1000
      }
      sensor.stringValue = String(format: "%d", MHZ)
      sensor.doubleValue = Double(MHZ)
      valid = true // trusted?
    case .cpuPowerWatt:
      sensor.stringValue = String(format: "%.2f", v)
      sensor.doubleValue = v
      valid = true // trusted?
    case .multiplier:
      var m: UInt = 0
      bcopy((data as NSData).bytes, &m, 2)
      sensor.stringValue = String(format: "x%.f", Double(m) / 10)
      sensor.doubleValue = Double(m)
      valid = true // trusted?
    default:
      break
    }
    
    return valid
  }
  
  
  func addSMCSensorIfValid(key: String,
                           type: DataType,
                           unit: HWUnit,
                           sensorType: HWSensorType,
                           title: String,
                           logType: LogType,
                           canPlot: Bool,
                           list: inout [HWMonitorSensor]) -> Bool {
    
    let kcount = key.count
    if kcount >= 3 && kcount <= 4 {
      let dt : DataType = getType(key) ?? type
      if let data : Data = gSMC.read(key: key, type: dt) {
        
        let s = HWMonitorSensor(key: key,
                                unit: unit,
                                type: dt.type.toString(),
                                sensorType: sensorType,
                                title: title,
                                canPlot: canPlot)
        
        if self.validateValue(for: s, data: data, dataType: dt) {
          s.logType = logType
          s.favorite = UDs.bool(forKey: key)
          list.append(s) // success
          return true
        }
      }
    }
    return false
  }
}
