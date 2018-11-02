//
//  IntelPowerGadget.swift
//  HWMonitorSMC2
//
//  Created by Vector Sigma on 07/10/2018.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

func getIntelPowerGadgetGPUSensors() -> [HWMonitorSensor] {
  var sensors : [HWMonitorSensor] = [HWMonitorSensor]()
  if IsGTAvailable() {
    /*
    var gpuutil : Float = 0
    if GetGPUUtilization(&gpuutil) {
      let sensor = HWMonitorSensor(key: "IGPU Utilization",
                                   unit: .Percent,
                                   type: "IPG",
                                   sensorType: .percent,
                                   title: "Utilization".locale(),
                                   canPlot: true)
      sensor.logType = .cpuLog;
      sensor.stringValue = String(format: "%.2f", Double(gpuutil)) + sensor.unit.rawValue
      sensor.doubleValue = Double(gpuutil)
      sensor.favorite = UDs.bool(forKey: sensor.key)
      sensors.append(sensor)
    }*/
    
    
    
    var gtFreq : Int32 = 0
    if GetGTFrequency(&gtFreq) {
      let sensor = HWMonitorSensor(key: "IGPU Frequency",
                               unit: .MHz,
                               type: "IPG",
                               sensorType: .intelGPUFrequency,
                               title: "Frequency".locale(),
                               canPlot: true)
      
      
      sensor.logType = .cpuLog;
      sensor.stringValue = String(format: "%d", gtFreq) + sensor.unit.rawValue
      sensor.doubleValue = Double(gtFreq)
      sensor.favorite = UDs.bool(forKey: sensor.key)
      sensors.append(sensor)
    }
    
    var gtMaxFreq : Int32 = 0
    if GetGpuMaxFrequency(&gtMaxFreq) {
      if gtMaxFreq > 0 {
        let sensor = HWMonitorSensor(key: "Max Frequency",
                                 unit: .MHz,
                                 type: "IPG",
                                 sensorType: .intelGPUFrequency,
                                 title: "Max Frequency".locale(),
                                 canPlot: true)
        
        sensor.isInformativeOnly = true
        sensor.logType = .cpuLog;
        sensor.stringValue = String(format: "%d", gtMaxFreq) + sensor.unit.rawValue
        sensor.doubleValue = Double(gtMaxFreq)
        sensor.favorite = UDs.bool(forKey: sensor.key)
        sensors.append(sensor)
      }
    }
    
  }
  return sensors
}

func getIntelPowerGadgetCPUSensors() -> [HWMonitorSensor] {
  var sensors : [HWMonitorSensor] = [HWMonitorSensor]()
  var cpuFrequency      : Double = 0
  var processorPower    : Double = 0
  //var processorEnergy1  : Double = 0
  //var processorEnergy2  : Double = 0
  var packageTemp       : Double = 0
  var packagePowerLimit : Double = 0
  
  /*
  // Returns true if we have platform energy MSRs available
  bool IsPlatformEnergyAvailable();
  
  // Returns true if we have platform energy MSRs available
  bool IsDramEnergyAvailable();
  */
  let dramEnergy : Bool = IsDramEnergyAvailable() || IsPlatformEnergyAvailable()
  
  var numMsrs : Int32 = 0
  
  GetNumMsrs(&numMsrs)
  //TODO: numMsrs must be > 0
  
  ReadSample()
  
  for j in 0..<numMsrs {
    var funcID : Int32 = 0
    let szName = UnsafeMutablePointer<Int8>.allocate(capacity: 1024)
    GetMsrFunc(j, &funcID)
    GetMsrName(j, szName)
    var nData: Int32 = 0
    let data = UnsafeMutablePointer<Double>.allocate(capacity: 3)
    GetPowerData(0, j, data, &nData)
    
    if funcID == MSR_FUNC_FREQ {
      cpuFrequency = data[0]
    } else if (funcID == MSR_FUNC_POWER && dramEnergy) {
      processorPower = data[0]
      //processorEnergy1 = data[1]
      //processorEnergy2 = data[2]
    } else if funcID == MSR_FUNC_TEMP {
      packageTemp = data[0]
    } else if funcID == MSR_FUNC_LIMIT {
      packagePowerLimit = data[0]
    }
    
    szName.deallocate()
    data.deallocate()
  }
  /*
   var TDP : Double = 0
   GetTDP(0, &TDP)*/
  
  var maxTemp : Int32 = 0
  GetMaxTemperature(0, &maxTemp);
  
  var temp : Int32 = 0
  GetTemperature(0, &temp);
  
  var degree1C : Int32 = 0
  var degree2C : Int32 = 0
  GetThresholds(0, &degree1C, &degree2C)
  
  var baseFrequency : Double = 0
  GetBaseFrequency(0, &baseFrequency)
  
  var cpuutil : Int32 = 0
  GetCpuUtilization(0, &cpuutil)
  
  var sensor = HWMonitorSensor(key: "CPU Frequency",
                               unit: .MHz,
                               type: "IPG",
                               sensorType: .intelCPUFrequency,
                               title: "Frequency".locale(),
                               canPlot: true)
  
  
  sensor.logType = .cpuLog;
  sensor.stringValue = String(format: "%.f", cpuFrequency) + sensor.unit.rawValue
  sensor.doubleValue = cpuFrequency
  sensor.favorite = UDs.bool(forKey: sensor.key)
  sensors.append(sensor)
  
  sensor = HWMonitorSensor(key: "Base Frequency",
                           unit: .MHz,
                           type: "IPG",
                           sensorType: .intelCPUFrequency,
                           title: "Base Frequency".locale(),
                           canPlot: false)
  
  
  sensor.isInformativeOnly = true
  sensor.logType = .cpuLog;
  sensor.stringValue = String(format: "%.f", baseFrequency) + sensor.unit.rawValue
  sensor.doubleValue = baseFrequency
  sensor.favorite = false
  sensors.append(sensor)
  
  
  sensor = HWMonitorSensor(key: "CPU Utilization",
                           unit: .Percent,
                           type: "IPG",
                           sensorType: .percent,
                           title: "Utilization".locale(),
                           canPlot: true)
  
  sensor.logType = .cpuLog;
  sensor.stringValue = String(format: "%.2f", Double(cpuutil)) + sensor.unit.rawValue
  sensor.doubleValue = Double(cpuutil)
  
  sensor.favorite = UDs.bool(forKey: sensor.key)
  sensors.append(sensor)
  
  sensor = HWMonitorSensor(key: "Package Temp",
                           unit: .C,
                           type: "IPG",
                           sensorType: .intelTemp,
                           title: "Package Temperature".locale(),
                           canPlot: true)
  
  
  sensor.logType = .cpuLog;
  sensor.stringValue = String(format: "%.2f", packageTemp) + sensor.unit.rawValue
  sensor.doubleValue = packageTemp
  sensor.favorite = UDs.bool(forKey: sensor.key)
  sensors.append(sensor)
  
  sensor = HWMonitorSensor(key: "Max Temperature",
                           unit: .C,
                           type: "IPG",
                           sensorType: .intelTemp,
                           title: "Max Temperature".locale(),
                           canPlot: false)
  
  sensor.isInformativeOnly = true
  sensor.logType = .cpuLog;
  sensor.stringValue = String(format: "%d", maxTemp) + sensor.unit.rawValue
  sensor.doubleValue = Double(maxTemp)
  sensor.favorite = false
  sensors.append(sensor)
  
  sensor = HWMonitorSensor(key: "Thresholds",
                           unit: .C,
                           type: "IPG",
                           sensorType: .intelTemp,
                           title: "Thresholds".locale(),
                           canPlot: false)
  
  sensor.isInformativeOnly = true
  sensor.logType = .cpuLog;
  sensor.stringValue = String(format: "%d/%d", degree1C, degree2C) + sensor.unit.rawValue
  sensor.doubleValue = Double(degree2C)
  sensor.favorite = false
  sensors.append(sensor)
  
  if dramEnergy {
    sensor = HWMonitorSensor(key: "Processor Power",
                             unit: .Watt,
                             type: "IPG",
                             sensorType: .intelWatt,
                             title: "DRAM".locale(),
                             canPlot: true)
    
    
    sensor.logType = .cpuLog;
    sensor.stringValue = String(format: "%.2f", processorPower) + sensor.unit.rawValue
    sensor.doubleValue = processorPower
    sensor.favorite = UDs.bool(forKey: sensor.key)
    sensors.append(sensor)
    /*
    sensor = HWMonitorSensor(key: "Processor Energy1",
                             unit: .Joule,
                             type: "IPG",
                             sensorType: .intelJoule,
                             title: "DRAM".locale(),
                             canPlot: false)
    
    
    sensor.logType = .cpuLog;
    sensor.stringValue = String(format: "%.2f", processorEnergy1) + sensor.unit.rawValue
    sensor.doubleValue = processorEnergy1
    sensor.favorite = UDs.bool(forKey: sensor.key)
    sensors.append(sensor)
    
    sensor = HWMonitorSensor(key: "Processor Energy2",
                             unit: .mWh,
                             type: "IPG",
                             sensorType: .intelmWh,
                             title: "DRAM".locale(),
                             canPlot: false)
    
    
    sensor.logType = .cpuLog;
    sensor.stringValue = String(format: "%.2f", processorEnergy2) + sensor.unit.rawValue
    sensor.doubleValue = processorEnergy2
    sensor.favorite = UDs.bool(forKey: sensor.key)
    sensors.append(sensor)
    */
  }
  
  
  sensor = HWMonitorSensor(key: "Package Power Limit (TDP)",
                           unit: .Watt,
                           type: "IPG",
                           sensorType: .intelWatt,
                           title: "Package Power Limit (TDP)".locale(),
                           canPlot: false)
  
  sensor.isInformativeOnly = true
  sensor.logType = .cpuLog;
  sensor.stringValue = String(format: "%.2f", packagePowerLimit) + sensor.unit.rawValue
  sensor.doubleValue = packagePowerLimit
  sensor.favorite = false
  sensors.append(sensor)

  return sensors
}

