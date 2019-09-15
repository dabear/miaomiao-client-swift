//
//  MiaomiaoClient.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 25/02/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import LoopKit
import LoopKitUI
import UIKit
import UserNotifications

import os.log
import HealthKit

public final class MiaoMiaoClientManager: CGMManager, LibreBluetoothManagerDelegate {
    public var sensorState: SensorDisplayable? {
        return latestBackfill
    }
    
    public var managedDataInterval: TimeInterval?
    
    
    
    
    
    public func getSmallImage() -> UIImage? {
        let bundle = Bundle.current

        return UserDefaults.standard.preSelectedDevice?.smallImage ??
            UIImage(named: "libresensor", in: bundle, compatibleWith: nil)
        
    }
    
   
    
    public var device: HKDevice? {
        return MiaoMiaoClientManager.proxy?.OnQueue_device
        /*return HKDevice(
            name: "MiaomiaoClient",
            manufacturer: MiaoMiaoClientManager.proxy?.OnQueue_manufacturer,
            model: nil, //latestSpikeCollector,
            hardwareVersion: hardwareVersion,
            firmwareVersion: firmwareVersion,
            softwareVersion: nil,
            localIdentifier: identifier,
            udiDeviceIdentifier: nil
        )*/
    }
    
    
    
    public var debugDescription: String {
        
        return [
            "## MiaomiaoClientManager",
            "Testdata: foo",
            "lastConnected: \(String(describing: lastConnected))",
            "Connection state: \(connectionState)",
            "Sensor state: \(sensorStateDescription)",
            "Bridge battery: \(battery)",
            //"Notification glucoseunit: \(glucoseUnit)",
            //"shouldSendGlucoseNotifications: \(shouldSendGlucoseNotifications)",
            //"latestBackfill: \(String(describing: "latestBackfill))",
            //"latestCollector: \(String(describing: latestSpikeCollector))",
            ""
            ].joined(separator: "\n")
    }
    
    
    
    

    
    public var miaomiaoService : MiaomiaoService
    
    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMResult) -> Void) {
        guard MiaoMiaoClientManager.proxy != nil else {
            completion(.noData)
            return
        }
        NSLog("dabear:: fetchNewDataIfNeeded called but we don't continue")
        
        completion(.noData)
       
    }
    
    
    
    public private(set) var lastConnected : Date?
   
    // This tighly tracks latestBackfill,
    // and is defined here so that the ui can have a way to fetch the latest
    // glucose value
    public static var latestGlucose : LibreGlucose?
    
    public private(set) var latestBackfill: LibreGlucose? {
        didSet(oldValue) {
            NSLog("dabear:: latestBackfill set, newvalue is \(latestBackfill)")
            if let latestBackfill = latestBackfill {
                MiaoMiaoClientManager.latestGlucose = latestBackfill
                NSLog("dabear:: sending glucose notification")
                NotificationHelper.sendGlucoseNotitifcationIfNeeded(glucose: latestBackfill, oldValue: oldValue)
            }
            
        }
    }
    public static var managerIdentifier = "DexMiaomiaoClient1"
    
    required convenience public init?(rawState: CGMManager.RawStateValue) {
        os_log("dabear:: MiaomiaoClientManager will init from rawstate")
        self.init()
        
    }
    
    public var rawState: CGMManager.RawStateValue {
        return [:]
    }
    
    public let keychain = KeychainManager()
    
    //public var miaomiaoService: MiaomiaoService
    
    public static let localizedTitle = LocalizedString("Libre Bluetooth", comment: "Title for the CGMManager option")
    
    public let appURL: URL? = nil //URL(string: "spikeapp://")
    
    weak public var cgmManagerDelegate: CGMManagerDelegate?
    
    public let providesBLEHeartbeat = true
    
    public let shouldSyncToRemoteService = true

    
    private(set) public var lastValidSensorData : SensorData? = nil
    
    
    
    
    public init(){
        lastConnected = nil
        //let isui = (self is CGMManagerUI)
        self.miaomiaoService = MiaomiaoService(keychainManager: keychain)
        
        os_log("dabear: MiaoMiaoClientManager will be created now")
        //proxy = MiaoMiaoBluetoothManager()
        MiaoMiaoClientManager.proxy?.delegate = self
            //proxy?.connect()
        
        MiaoMiaoClientManager.instanceCount += 1
        
        
        
        
    }
    
    
    
    public var calibrationData : DerivedAlgorithmParameters? {
        return keychain.getLibreCalibrationData()
    }
    
    public func disconnect(){
       NSLog("dabear:: MiaoMiaoClientManager disconnect called")
        
        
        MiaoMiaoClientManager.proxy?.disconnectManually()
        MiaoMiaoClientManager.proxy?.delegate = nil
        //MiaoMiaoClientManager.proxy = nil
    }
    
    deinit {
        
        NSLog("dabear:: MiaoMiaoClientManager deinit called")
        
        
        //cleanup any references to events to this class
        disconnect()
        MiaoMiaoClientManager.instanceCount -= 1
    }

    
    private static var instanceCount = 0 {
        didSet {
            
            //this is to workaround a bug where multiple managers might exist
            os_log("dabear:: MiaoMiaoClientManager instanceCount changed to %{public}@", type: .default, String(describing: instanceCount))
            if instanceCount < 1 {
                os_log("dabear:: instancecount is 0, deiniting service", type: .default)
                MiaoMiaoClientManager.sharedProxy = nil
                //MiaoMiaoClientManager.sharedInstance = nil
            }
            //this is another attempt to workaround a bug where multiple managers might exist
            if oldValue > instanceCount {
                os_log("dabear:: MiaoMiaoClientManager decremented, stop all miaomiao bluetooth services")
                MiaoMiaoClientManager.sharedProxy = nil
                //MiaoMiaoClientManager.sharedInstance = nil
            }
            
            
        }
    }
    
    
    private static var sharedProxy: LibreBluetoothManager?
    private class var proxy : LibreBluetoothManager? {
        guard let sharedProxy = self.sharedProxy else {
            let sharedProxy = LibreBluetoothManager()
            self.sharedProxy = sharedProxy
            return sharedProxy
        }
        return sharedProxy
    }
    
   
   
    private func trendToLibreGlucose(_ measurements: [Measurement]) -> [LibreGlucose]?{
        var origarr = [LibreGlucose]()
        
        //whether or not to return all the 16 latest trends or just every fifth element
        let returnAllTrends = true
        
        
        
        for trend in measurements {
            let glucose = LibreGlucose(unsmoothedGlucose: trend.temperatureAlgorithmGlucose, glucoseDouble: 0.0, trend: UInt8(GlucoseTrend.flat.rawValue), timestamp: trend.date, collector: "MiaoMiao")
            origarr.append(glucose)
        }
        //NSLog("dabear:: glucose samples before smoothing: \(String(describing: origarr))")
        var arr : [LibreGlucose]
        arr = CalculateSmothedData5Points(origtrends: origarr)
        
        
        
        for i in 0 ..< arr.count {
            var trend = arr[i]
            //we know that the array "always" (almost) will contain 16 entries
            //the last five entries will get a trend arrow of flat, because it's not computable when we don't have
            //more entries in the array to base it on
            let arrow = TrendArrowCalculation.GetGlucoseDirection(current: trend, last: arr[safe: i+5])
            arr[i].trend = UInt8(arrow.rawValue)
            NSLog("Date: \(trend.timestamp), before: \(trend.unsmoothedGlucose), after: \(trend.glucose), arrow: \(trend.trend)")
        }
        
        
        
        
        if returnAllTrends {
            return arr
        }
        
        var filtered = [LibreGlucose]()
        for elm in arr.enumerated() where elm.offset % 5 == 0 {
            filtered.append(elm.element)
        }
        
        //NSLog("dabear:: glucose samples after smoothing: \(String(describing: arr))")
        return filtered
    }
    
    public func handleGoodReading(data: SensorData?,_ callback: @escaping (LibreError?, [LibreGlucose]?) -> Void) {
        //only care about the once per minute readings here, historical data will not be considered
        
        guard let data=data else {
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
        
        guard let (accessToken, url) =  self.keychain.getAutoCalibrateWebCredentials() else {
            NSLog("dabear:: could not calibrate, accesstoken or url was nil")
            callback(LibreError.invalidAutoCalibrationCredentials, nil)
            return
        }
        
        
        
        calibrateSensor(accessToken: accessToken, site: url.absoluteString, sensordata: data) { [weak self] (calibrationparams)  in
            guard let params = calibrationparams else {
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
            let last16 = data.trendMeasurements(derivedAlgorithmParameterSet: params)
            callback(nil, self?.trendToLibreGlucose(last16) )
            
            
        }
        
        
        
        
    }
    
    
   
    //will be called on utility queue
    public func libreBluetoothManagerPeripheralStateChanged(_ state: BluetoothmanagerState) {
        switch state {
        case .Connected:
            lastConnected = Date()
        case .powerOff:
            NotificationHelper.sendBluetoothPowerOffNotification()
        default:
            break
        }
        return
    }
    
    //will be called on utility queue
    public func libreBluetoothManagerReceivedMessage(_ messageIdentifier: UInt16, txFlags: UInt8, payloadData: Data) {
        guard let packet = MiaoMiaoResponseState.init(rawValue: txFlags) else {
            // Incomplete package?
            // this would only happen if delegate is called manually with an unknown txFlags value
            // this was the case for readouts that were not yet complete
            // but that was commented out in MiaoMiaoManager.swift, see comment there:
            // "dabear-edit: don't notify on incomplete readouts"
            NSLog("dabear:: incomplete package or unknown response state")
            return
        }
        
        switch packet {
        case .newSensor:
            NSLog("dabear:: new libresensor detected")
            NotificationHelper.sendSensorChangeNotificationIfNeeded(hasChanged: true)
            break
        case .noSensor:
            NSLog("dabear:: no libresensor detected")
            NotificationHelper.sendSensorNotDetectedNotificationIfNeeded(noSensor: true)
            break
        case .frequencyChangedResponse:
            NSLog("dabear:: miaomiao readout interval has changed!")
            break
        
        default:
            //we don't care about the rest!
            break
        }
        
        return
        
    }
    
    //will be called on utility queue
    public func libreBluetoothManagerDidUpdate(sensorData: SensorData, and Device: BluetoothBridgeMetaData) {
        
        print("dabear:: got sensordata: \(sensorData), bytescount: \(sensorData.bytes.count), bytes: \(sensorData.bytes)")
        
        NotificationHelper.sendLowBatteryNotificationIfNeeded(device: Device)
        NotificationHelper.sendInvalidSensorNotificationIfNeeded(sensorData: sensorData)
        NotificationHelper.sendSensorExpireAlertIfNeeded(sensorData: sensorData)
        
        if sensorData.hasValidCRCs {
            
            if sensorData.state == .ready ||  sensorData.state == .starting {
                NSLog("dabear:: got sensordata with valid crcs, sensor was ready")
                self.lastValidSensorData = sensorData
                
                self.handleGoodReading(data: sensorData) { (error, glucose) in
                    if let error = error {
                        NSLog("dabear:: handleGoodReading returned with error: \(error)")
                        
                        self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .error(error))
                        return
                    }
                    
                    guard let glucose = glucose else {
                        NSLog("dabear:: handleGoodReading returned with no data")
                        self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .noData)
                        
                        return
                    }
                    
                    let startDate = self.latestBackfill?.startDate
                    let newGlucose = glucose.filterDateRange(startDate, nil).filter({ $0.isStateValid }).map {
                        return NewGlucoseSample(date: $0.startDate, quantity: $0.quantity, isDisplayOnly: false, syncIdentifier: "\(Int($0.startDate.timeIntervalSince1970))", device: MiaoMiaoClientManager.proxy?.device)
                    }
                    
                    self.latestBackfill = glucose.first
                    
                    if newGlucose.count > 0 {
                        NSLog("dabear:: handleGoodReading returned with \(newGlucose.count) new glucose samples")
                        self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .newData(newGlucose))
                        
                    } else {
                        NSLog("dabear:: handleGoodReading returned with no new data")
                        self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .noData)
                        
                    }
                    
                }
                
            } else {
                os_log("dabear:: got sensordata with valid crcs, but sensor is either expired or failed")
                self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .error(LibreError.expiredSensor))
            }
            
            
        } else {
            self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .error(LibreError.checksumValidationError))
            os_log("dit not get sensordata with valid crcs")
        }
        return
    }
    
    
    
    
}

/*
 These are formatted versions of properties existing in the bluetoothmanager proxy
 The bluetooth manager has all these properties living on a special utility queue,
 so we call them on the same queue, but return them on the main queue
 */
extension MiaoMiaoClientManager {
    //cannot be called from managerQueue
    public var identifier: String {
        return  MiaoMiaoClientManager.proxy?.OnQueue_identifer?.uuidString ?? "n/a"
        
    }
    
    
    //cannot be called from managerQueue
    public var connectionState : String {
        return MiaoMiaoClientManager.proxy?.connectionStateString ?? "n/a"
        
    }
    //cannot be called from managerQueue
    public var sensorSerialNumber: String {
        return MiaoMiaoClientManager.proxy?.OnQueue_sensorData?.serialNumber ?? "n/a"
    }
    
    //cannot be called from managerQueue
    public var sensorAge: String {
        return MiaoMiaoClientManager.proxy?.OnQueue_sensorData?.humanReadableSensorAge ?? "n/a"
        
    }
    
    //cannot be called from managerQueue
    public var sensorFooterChecksums: String {
        if let crc = MiaoMiaoClientManager.proxy?.OnQueue_sensorData?.footerCrc.byteSwapped {
            //if let crc = MiaoMiaoClientManager.proxy?.sensorData?.footerCrc.byteSwapped {
            return  "\(crc)"
        }
        return  "n/a"
    }
    
    //cannot be called from managerQueue
    public var sensorStateDescription : String {
        
        return MiaoMiaoClientManager.proxy?.OnQueue_sensorData?.state.description ?? "n/a"
    }
    //cannot be called from managerQueue
    public var firmwareVersion : String {
        
        return MiaoMiaoClientManager.proxy?.OnQueue_metadata?.firmware ?? "n/a"
    }
    
    //cannot be called from managerQueue
    public var hardwareVersion : String {
        
        return MiaoMiaoClientManager.proxy?.OnQueue_metadata?.hardware ?? "n/a"
        
    }
    
    
    
    //cannot be called from managerQueue
    public var battery : String {
        if let bat = MiaoMiaoClientManager.proxy?.OnQueue_metadata?.battery {
            return "\(bat)%"
        }
        return "n/a"
    }
}
