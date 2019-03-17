//
//  MiaomiaoClient.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 25/02/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import LoopKit
//import LoopKitUI

import os.log
import HealthKit

public final class MiaoMiaoClientManager: CGMManager, MiaoMiaoBluetoothManagerDelegate {
    public var sensorState: SensorDisplayable?
    
    public var managedDataInterval: TimeInterval?
    
    public var device: HKDevice? {
        
        return HKDevice(
            name: "MiaomiaoClient",
            manufacturer: "Tomato",
            model: nil, //latestSpikeCollector,
            hardwareVersion: hardwareVersion,
            firmwareVersion: firmwareVersion,
            softwareVersion: nil,
            localIdentifier: nil,
            udiDeviceIdentifier: nil
        )
    }
    
    public var debugDescription: String {
        
        return [
            "## MiaomiaoClientManager",
            "Testdata: foo",
            "lastConnected: \(String(describing: lastConnected))",
            "Connection state: \(connectionState)",
            "Sensor state: \(sensorStateDescription)",
            "bridge battery: \(battery)",
            //"latestBackfill: \(String(describing: "latestBackfill))",
            //"latestCollector: \(String(describing: latestSpikeCollector))",
            ""
            ].joined(separator: "\n")
    }
    
    private static var sharedInstance: MiaomiaoService?
    public class var miaomiaoService : MiaomiaoService {
        guard let sharedInstance = self.sharedInstance else {
            let sharedInstance = MiaomiaoService()
            self.sharedInstance = sharedInstance
            return sharedInstance
        }
        return sharedInstance
    }
    
    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMResult) -> Void) {
        guard proxy != nil else {
            completion(.noData)
            return
        }
        NSLog("dabear:: fetchNewDataIfNeeded called but we don't continue")
        self.autoconnect()
        completion(.noData)
        /*
        self.getLastSensorValues { (error, glucose) in
            if let error = error {
                NSLog("dabear:: getLastSensorValues returned with error")
                completion(.error(error))
                return
            }
            
            guard let glucose = glucose else {
                NSLog("dabear:: getLastSensorValues returned with no data")
                completion(.noData)
                return
            }
            
            let startDate = self.latestBackfill?.startDate
            let newGlucose = glucose.filterDateRange(startDate, nil).filter({ $0.isStateValid }).map {
                return NewGlucoseSample(date: $0.startDate, quantity: $0.quantity, isDisplayOnly: false, syncIdentifier: "\(Int($0.startDate.timeIntervalSince1970))", device: self.device)
            }
            
            self.latestBackfill = glucose.first
            
            if newGlucose.count > 0 {
                completion(.newData(newGlucose))
            } else {
                completion(.noData)
            }
            
        } */
    }
    
    
    
    public private(set) var lastConnected : Date?
   
    public private(set) var latestBackfill: LibreGlucose?
    public static var managerIdentifier = "DexMiaomiaoClient1"
    
    required convenience public init?(rawState: CGMManager.RawStateValue) {
        os_log("dabear:: MiaomiaoClientManager will init from rawstate")
        self.init()
    }
    
    public var rawState: CGMManager.RawStateValue {
        return [:]
    }
    
    private let keychain = KeychainManager()
    
    //public var miaomiaoService: MiaomiaoService
    
    public static let localizedTitle = LocalizedString("Miaomiao", comment: "Title for the CGMManager option")
    
    public let appURL: URL? = nil //URL(string: "spikeapp://")
    
    weak public var cgmManagerDelegate: CGMManagerDelegate?
    
    public let providesBLEHeartbeat = false
    
    public let shouldSyncToRemoteService = true

    
    private var lastValidSensorData : SensorData? = nil
    
    
    
    private var proxy : MiaoMiaoBluetoothManager?
    public init(){
        lastConnected = nil
        
        //if !(self is CGMManagerUI) {
            os_log("dabear: miaomiaomanager will be created now")
            proxy = MiaoMiaoBluetoothManager()
            proxy?.delegate = self
            //proxy?.connect()
        //}
        
        
    }
    
    public var connectionState : String {
        return proxy?.state.rawValue ?? "n/a"
        
    }
    
    public var sensorStateDescription : String {
        return proxy?.sensorData?.state.description ?? "n/a"
    }
    
    public var firmwareVersion : String {
        return proxy?.miaoMiao?.firmware ?? "n/a"
    }
    
    public var hardwareVersion : String {
        return proxy?.miaoMiao?.hardware ?? "n/a"
    }
    
    public var battery : String {
        if let bat = proxy?.miaoMiao?.battery {
            return "\(bat)%"
        }
        return "n/a"
    }
    
    public func disconnect(){
       
        proxy?.disconnectManually()
        proxy?.delegate = nil
        proxy = nil
    }
    
    func autoconnect(){
        guard let proxy = proxy else {
            os_log("dabear: could not do autoconnect, proxy was nil")
            return
        }
        
        // force trying to reconnect every time a we detect
        // a disconnected state while fetching
        switch (proxy.state) {
        case .Unassigned:
            break
            //proxy.scanForMiaoMiao()
        case .Scanning:
            break
        case .Connected, .Connecting, .Notifying:
            break
        case .Disconnected, .DisconnectingDueToButtonPress:
            proxy.connect()
        }
    }
    private func trendToLibreGlucose(_ measurements: [Measurement]) -> [LibreGlucose]?{
        var arr = [LibreGlucose]()
        
        for trend in measurements {
            let glucose = LibreGlucose(glucose: UInt16(trend.temperatureAlgorithmGlucose.rounded().rawValue), trend: UInt8(GlucoseTrend.flat.rawValue), timestamp: trend.date, collector: "MiaoMiao")
            arr.append(glucose)
        }
        
        return arr
    }
    
    public func getLastSensorValues(_ callback: @escaping (LibreError?, [LibreGlucose]?) -> Void) {
        //only care about the once per minute readings here, historical data will not be considered
        
        guard let data=lastValidSensorData else {
            callback(LibreError.noSensorData, nil)
            return
            
        }
        
        
        let calibrationdata = keychain.getLibreCalibrationData()
        
        
        if let calibrationdata = calibrationdata{
            NSLog("dabear:: calibrationdata loaded")
            
            if calibrationdata.isValidForFooterWithReverseCRCs == data.footerCrc.byteSwapped {
                NSLog("dabear:: calibrationdata correct for this sensor, returning last values")
                let last16 = data.trendMeasurements(derivedAlgorithmParameterSet: calibrationdata)
                callback(nil, trendToLibreGlucose(last16) )
                return
                
            } else {
                NSLog("dabear:: calibrationdata incorrect for this sensor, calibrationdata.isValidForFooterWithReverseCRCs: \(calibrationdata.isValidForFooterWithReverseCRCs),  data.footerCrc.byteSwapped: \(data.footerCrc.byteSwapped)")
            }
            
        } else {
            NSLog("dabear:: calibrationdata was nil")
            
        }
        
        calibrateSensor(data) { [weak self] (params)  in
            guard let params = params else {
                NSLog("dabear:: could not calibrate sensor, check libreoopweb permissions and internet connection")
                callback(LibreError.noCalibrationData, nil)
                return
            }
            
            do {
                try self?.keychain.setLibreCalibrationData(params)
            } catch {
                NSLog("dabear:: could not save calibrationdata")
                callback(LibreError.invalidCalibrationData, nil)
                return
            }
            //here we assume success, data is not changed,
            //and we trust that the remote endpoint returns correct data for the sensor
            let last16 = data.trendMeasurements(derivedAlgorithmParameterSet: calibrationdata)
            callback(nil, self?.trendToLibreGlucose(last16) )
            
            
        }
        
        
        
        
    }
    
    
   
    
    public func miaoMiaoBluetoothManagerPeripheralStateChanged(_ state: MiaoMiaoManagerState) {
        switch state {
        case .Connected:
            lastConnected = Date()
        default:
            break
        }
        return
    }
    
    public func miaoMiaoBluetoothManagerReceivedMessage(_ messageIdentifier: UInt16, txFlags: UInt8, payloadData: Data) {
        guard let packet = MiaoMiaoResponseState.init(rawValue: txFlags) else {
            // Incomplete package?
            // this would only happen if delegate is called manually with an unknown txFlags value
            // this was the case for readouts that were not yet complete
            // but that was commented out in MiaoMiaoManager.swift, see comment there:
            // "dabear-edit: don't notify on incomplete readouts"
            os_log("incomplete package or unknown response state")
            return
        }
        
        switch packet {
        case .newSensor:
            //invalidate any saved calibration parameters
            break
        case .noSensor:
            break
        //consider notifying user here that sensor is not found
        default:
            //we don't care about the rest!
            break
        }
        
        return
        
    }
    
    public func miaoMiaoBluetoothManagerDidUpdateSensorAndMiaoMiao(sensorData: SensorData, miaoMiao: MiaoMiao) {
        if sensorData.hasValidCRCs {
            
            if sensorData.state == .ready ||  sensorData.state == .starting {
                os_log("got sensordata with valid crcs, sensor was ready")
                self.lastValidSensorData = sensorData
                
                self.getLastSensorValues { (error, glucose) in
                    if let error = error {
                        NSLog("dabear:: getLastSensorValues returned with error")
                        
                        self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .error(error))
                        return
                    }
                    
                    guard let glucose = glucose else {
                        NSLog("dabear:: getLastSensorValues returned with no data")
                        self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .noData)
                        
                        return
                    }
                    
                    let startDate = self.latestBackfill?.startDate
                    let newGlucose = glucose.filterDateRange(startDate, nil).filter({ $0.isStateValid }).map {
                        return NewGlucoseSample(date: $0.startDate, quantity: $0.quantity, isDisplayOnly: false, syncIdentifier: "\(Int($0.startDate.timeIntervalSince1970))", device: self.device)
                    }
                    
                    self.latestBackfill = glucose.first
                    
                    if newGlucose.count > 0 {
                        self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .newData(newGlucose))
                        
                    } else {
                        self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .noData)
                        
                    }
                    
                }
                
            } else {
                os_log("got sensordata with valid crcs, but sensor is either expired or failed")
                self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .error(LibreError.expiredSensor))
            }
            
            
        } else {
            self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .error(LibreError.checksumValidationError))
            os_log("dit not get sensordata with valid crcs")
        }
        return
    }
    
    deinit {
        
        os_log("dabear:: miaomiaoproxy deinit called2")
        
        
        //cleanup any references to events to this class
        disconnect()
        
        
    }
    
    
}
