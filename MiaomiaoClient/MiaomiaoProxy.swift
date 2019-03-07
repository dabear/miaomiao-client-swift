//
//  MiaomiaoClient.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 25/02/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import LoopKit
import os.log

public final class MiaoMiaoProxy: MiaoMiaoManagerDelegate {
    public private(set) var lastConnected : Date?
    
    private var lastValidSensorData : SensorData? = nil
    
    private let keychain = KeychainManager()
    
    private var proxy : MiaoMiaoManager?
    public init(){
        lastConnected = nil
        os_log("dabear: miaomiaomanager will be created now")
        proxy = MiaoMiaoManager()
        proxy?.delegate = self
        //proxy?.connect()
    }
    
    public var connectionState : String {
        return proxy?.state.rawValue ?? "n/a"
        
    }
    
    public var sensorState : String {
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
    
    
   
    
    public func miaoMiaoManagerPeripheralStateChanged(_ state: MiaoMiaoManagerState) {
        switch state {
        case .Connected:
            lastConnected = Date()
        default:
            break
        }
        return
    }
    
    public func miaoMiaoManagerReceivedMessage(_ messageIdentifier: UInt16, txFlags: UInt8, payloadData: Data) {
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
    
    public func miaoMiaoManagerDidUpdateSensorAndMiaoMiao(sensorData: SensorData, miaoMiao: MiaoMiao) {
        if sensorData.hasValidCRCs {
            
            if sensorData.state == .ready ||  sensorData.state == .starting {
                os_log("got sensordata with valid crcs, sensor was ready")
                self.lastValidSensorData = sensorData
            } else {
                os_log("got sensordata with valid crcs, but sensor is either expired or failed")
            }
            
            
        } else {
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
