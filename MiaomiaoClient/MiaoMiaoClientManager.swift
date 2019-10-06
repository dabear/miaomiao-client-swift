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
        return proxy?.OnQueue_device

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

    public var miaomiaoService: MiaomiaoService

    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMResult) -> Void) {

        NSLog("dabear:: fetchNewDataIfNeeded called but we don't continue")

        completion(.noData)

    }

    public private(set) var lastConnected: Date?

    // This tighly tracks latestBackfill,
    // and is defined here so that the ui can have a way to fetch the latest
    // glucose value
    public static var latestGlucose: LibreGlucose?

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

    public static let localizedTitle = LocalizedString("Libre Bluetooth", comment: "Title for the CGMManager option")

    public let appURL: URL? = nil //URL(string: "spikeapp://")
    weak public var cgmManagerDelegate: CGMManagerDelegate?
    public let providesBLEHeartbeat = true
    public let shouldSyncToRemoteService = true

    private(set) public var lastValidSensorData: SensorData?

    public init() {
        lastConnected = nil
        //let isui = (self is CGMManagerUI)
        self.miaomiaoService = MiaomiaoService(keychainManager: keychain)

        os_log("dabear: MiaoMiaoClientManager will be created now")
        //proxy = MiaoMiaoBluetoothManager()
        proxy?.delegate = self

    }

    public var calibrationData: DerivedAlgorithmParameters? {
        return keychain.getLibreCalibrationData()
    }

    public func disconnect() {
       NSLog("dabear:: MiaoMiaoClientManager disconnect called")

        proxy?.disconnectManually()
        proxy?.delegate = nil

    }

    deinit {

        NSLog("dabear:: MiaoMiaoClientManager deinit called")
        //cleanup any references to events to this class
        disconnect()

    }

    private lazy var proxy: LibreBluetoothManager? = LibreBluetoothManager()

    private func readingToGlucose(_ data: SensorData, calibration: DerivedAlgorithmParameters) -> [LibreGlucose] {

        let last16 = data.trendMeasurements(derivedAlgorithmParameterSet: calibration)
        let history = data.historyMeasurements(derivedAlgorithmParameterSet: calibration)

        return LibreGlucose.fromTrendMeasurements(last16) + LibreGlucose.fromHistoryMeasurements(history)
    }

    public func handleGoodReading(data: SensorData?, _ callback: @escaping (LibreError?, [LibreGlucose]?) -> Void) {
        //only care about the once per minute readings here, historical data will not be considered

        guard let data=data else {
            callback(LibreError.noSensorData, nil)
            return

        }

        let calibrationdata = keychain.getLibreCalibrationData()

        if let calibrationdata = calibrationdata {
            NSLog("dabear:: calibrationdata loaded")

            if calibrationdata.isValidForFooterWithReverseCRCs == data.footerCrc.byteSwapped {
                NSLog("dabear:: calibrationdata correct for this sensor, returning last values")

                callback(nil, readingToGlucose(data, calibration: calibrationdata))
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

            callback(nil, self?.readingToGlucose(data, calibration: params))

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

        NotificationHelper.sendInvalidChecksumIfDeveloper(sensorData)

        guard sensorData.hasValidCRCs else {
            self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .error(LibreError.checksumValidationError))
            os_log("dit not get sensordata with valid crcs")
            return
        }

        guard sensorData.state == .ready ||  sensorData.state == .starting else {
            os_log("dabear:: got sensordata with valid crcs, but sensor is either expired or failed")
            self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .error(LibreError.expiredSensor))
            return
        }

        NSLog("dabear:: got sensordata with valid crcs, sensor was ready")
        self.lastValidSensorData = sensorData

        self.handleGoodReading(data: sensorData) { [weak self] (error, glucose) in
            guard let self = self else {
                NSLog("dabear:: handleGoodReading could not lock on self, aborting")
                return

            }
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

            // add one second to startdate to make this an exclusive (non overlapping) match
            let startDate = self.latestBackfill?.startDate.addingTimeInterval(1)
            let device = self.proxy?.device
            let newGlucose = glucose.filterDateRange(startDate, nil).filter({ $0.isStateValid }).map {


                return NewGlucoseSample(date: $0.startDate, quantity: $0.quantity, isDisplayOnly: false, syncIdentifier: "\(Int($0.startDate.timeIntervalSince1970))\($0.unsmoothedGlucose)", device: device)
            }

            self.latestBackfill = glucose.max { $0.startDate < $1.startDate}

            if newGlucose.count > 0 {
                NSLog("dabear:: handleGoodReading returned with \(newGlucose.count) new glucose samples")
                self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .newData(newGlucose))

            } else {
                NSLog("dabear:: handleGoodReading returned with no new data")
                self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .noData)

            }

        }

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
        return  proxy?.OnQueue_identifer?.uuidString ?? "n/a"

    }

    //cannot be called from managerQueue
    public var connectionState: String {
        return proxy?.connectionStateString ?? "n/a"

    }
    //cannot be called from managerQueue
    public var sensorSerialNumber: String {
        return proxy?.OnQueue_sensorData?.serialNumber ?? "n/a"
    }

    //cannot be called from managerQueue
    public var sensorAge: String {
        return proxy?.OnQueue_sensorData?.humanReadableSensorAge ?? "n/a"

    }

    //cannot be called from managerQueue
    public var sensorFooterChecksums: String {
        if let crc = proxy?.OnQueue_sensorData?.footerCrc.byteSwapped {
            //if let crc = MiaoMiaoClientManager.proxy?.sensorData?.footerCrc.byteSwapped {
            return  "\(crc)"
        }
        return  "n/a"
    }

    //cannot be called from managerQueue
    public var sensorStateDescription: String {

        return proxy?.OnQueue_sensorData?.state.description ?? "n/a"
    }
    //cannot be called from managerQueue
    public var firmwareVersion: String {

        return proxy?.OnQueue_metadata?.firmware ?? "n/a"
    }

    //cannot be called from managerQueue
    public var hardwareVersion: String {

        return proxy?.OnQueue_metadata?.hardware ?? "n/a"

    }

    //cannot be called from managerQueue
    public var battery: String {
        if let bat = proxy?.OnQueue_metadata?.battery {
            return "\(bat)%"
        }
        return "n/a"
    }
}
