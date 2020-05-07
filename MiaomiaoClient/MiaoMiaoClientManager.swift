//
//  MiaomiaoClient.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 25/02/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import Foundation
import LoopKit
import LoopKitUI
import UIKit
import UserNotifications

import CoreBluetooth
import HealthKit
import os.log

public final class MiaoMiaoClientManager: CGMManager, LibreTransmitterDelegate {
    public func libreManagerDidRestoreState(found peripherals: [CBPeripheral], connected to: CBPeripheral?) {
        let devicename = to?.name  ?? "no device"
        let id = to?.identifier.uuidString ?? "null"
        let msg = "Bluetooth State restored (Loop restarted?). Found \(peripherals.count) peripherals, and connected to \(devicename) with identifier \(id)"
        NotificationHelper.sendRestoredStateNotification(msg: msg)
    }


    public func noLibreTransmitterSelected() {
        NotificationHelper.sendNoTransmitterSelectedNotification()
    }

    public var cgmManagerDelegate: CGMManagerDelegate? {
        get {
            return delegate.delegate
        }
        set {
            delegate.delegate = newValue
        }
    }

    public var delegateQueue: DispatchQueue! {
        get {
            return delegate.queue
        }
        set {
            delegate.queue = newValue
        }
    }

    public let delegate = WeakSynchronizedDelegate<CGMManagerDelegate>()

    public var sensorState: SensorDisplayable? /*{
        
        return latestBackfill
    }*/

    public var managedDataInterval: TimeInterval?

    public var device: HKDevice? {
         //proxy?.OnQueue_device
        proxy?.viaManagerQueue.device
    }

    private func getPersistedSensorDataForDebug() -> String {
        guard let data = UserDefaults.standard.queuedSensorData else {
            return "nil"
        }

        let c =  self.calibrationData?.description ?? "no calibrationdata"
        return data.array.map {
            "SensorData(uuid: \"0123\".data(using: .ascii)!, bytes: \($0.bytes))!"
        }
        .joined(separator: ",\n")
        + ",\n Calibrationdata: \(c)"

    }

    public var debugDescription: String {
        [
            "## MiaomiaoClientManager",
            "Testdata: foo",
            "lastConnected: \(String(describing: lastConnected))",
            "Connection state: \(connectionState)",
            "Sensor state: \(sensorStateDescription)",
            "transmitterbattery: \(batteryString)",
            "SensorData: \(getPersistedSensorDataForDebug())",
            "Metainfo::\n\(AppMetaData.allProperties)",
            ""
        ].joined(separator: "\n")
    }

    public var miaomiaoService: MiaomiaoService

    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMResult) -> Void) {
        NSLog("dabear:: fetchNewDataIfNeeded called but we don't continue")

        completion(.noData)
    }

    public private(set) var lastConnected: Date?

    public private(set) var latestBackfill: LibreGlucose? {
        willSet(newValue) {
            guard let newValue = newValue else {
                return
            }

            var trend: GlucoseTrend?
            var oldValue = latestBackfill

            defer {
                NSLog("dabear:: sending glucose notification")
                NotificationHelper.sendGlucoseNotitifcationIfNeeded(glucose: newValue,
                                                                    oldValue: oldValue,
                                                                    trend: trend,
                                                                    battery: batteryString)
            }

            NSLog("dabear:: latestBackfill set, newvalue is \(newValue)")

            if let oldValue = oldValue {
                // the idea here is to use the diff between the old and the new glucose to calculate slope and direction, rather than using trend from the glucose value.
                // this is because the old and new glucose values represent earlier readouts, while the trend buffer contains somewhat more jumpy (noisy) values.
                let timediff = LibreGlucose.timeDifference(oldGlucose: oldValue, newGlucose: newValue)
                NSLog("dabear:: timediff is \(timediff)")
                let oldIsRecentEnough = timediff <= TimeInterval.minutes(15)

                trend = oldIsRecentEnough ? newValue.GetGlucoseTrend(last: oldValue) : nil

                var batteries : [(name: String, percentage: Int)]?
                if let metaData = metaData, let battery = battery {
                    batteries = [(name: metaData.name, percentage: battery)]
                }

                self.sensorState = ConcreteSensorDisplayable(isStateValid: newValue.isStateValid, trendType: trend, isLocal: true, batteries: batteries)
            } else {
                //could consider setting this to ConcreteSensorDisplayable with trendtype GlucoseTrend.flat, but that would be kinda lying
                self.sensorState = nil
            }
        }
    }

    public static var managerIdentifier = "DexMiaomiaoClient1"

    public required convenience init?(rawState: CGMManager.RawStateValue) {
        os_log("dabear:: MiaomiaoClientManager will init from rawstate")
        self.init()
    }

    public var rawState: CGMManager.RawStateValue {
        [:]
    }

    public let keychain = KeychainManager()

    public static let localizedTitle = LocalizedString("Libre Bluetooth", comment: "Title for the CGMManager option")

    public let appURL: URL? = nil //URL(string: "spikeapp://")

    public let providesBLEHeartbeat = true
    public var shouldSyncToRemoteService: Bool {
        UserDefaults.standard.mmSyncToNs
    }

    public private(set) var lastValidSensorData: SensorData?

    public init() {
        lastConnected = nil
        //let isui = (self is CGMManagerUI)
        self.miaomiaoService = MiaomiaoService(keychainManager: keychain)

        os_log("dabear: MiaoMiaoClientManager will be created now")
        //proxy = MiaoMiaoBluetoothManager()
        proxy?.delegate = self
    }

    public var calibrationData: DerivedAlgorithmParameters? {
        keychain.getLibreCalibrationData()
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

    private lazy var proxy: LibreTransmitterManager? = LibreTransmitterManager()

    private func readingToGlucose(_ data: SensorData, calibration: DerivedAlgorithmParameters) -> [LibreGlucose] {
        let last16 = data.trendMeasurements(derivedAlgorithmParameterSet: calibration)

        var entries = LibreGlucose.fromTrendMeasurements(last16, returnAll: UserDefaults.standard.mmBackfillFromTrend)

        let text = entries.map{ $0.description}.joined(separator: ",")
        NSLog("dabear:: trend entries count: \(entries.count): \n \(text)" )
        if UserDefaults.standard.mmBackfillFromHistory {
            let history = data.historyMeasurements(derivedAlgorithmParameterSet: calibration)
            entries += LibreGlucose.fromHistoryMeasurements(history)
        }


        return entries
    }

    public func handleGoodReading(data: SensorData?, _ callback: @escaping (LibreError?, [LibreGlucose]?) -> Void) {
        //only care about the once per minute readings here, historical data will not be considered

        guard let data = data else {
            callback(.noSensorData, nil)
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

        guard let (accessToken, url) = self.keychain.getAutoCalibrateWebCredentials() else {
            NSLog("dabear:: could not calibrate, accesstoken or url was nil")
            callback(.invalidAutoCalibrationCredentials, nil)
            return
        }

        NotificationHelper.sendCalibrationNotification(.starting)
        calibrateSensor(accessToken: accessToken, site: url.absoluteString, sensordata: data) { [weak self] calibrationparams  in
            guard let params = calibrationparams else {
                NotificationHelper.sendCalibrationNotification(.noCalibration)
                callback(.noCalibrationData, nil)
                return
            }

            do {
                try self?.keychain.setLibreCalibrationData(params)
            } catch {
                NotificationHelper.sendCalibrationNotification(.invalidCalibrationData)
                callback(.invalidCalibrationData, nil)
                return
            }
            //here we assume success, data is not changed,
            //and we trust that the remote endpoint returns correct data for the sensor

            NotificationHelper.sendCalibrationNotification(.success)
            callback(nil, self?.readingToGlucose(data, calibration: params))
        }
    }

    //will be called on utility queue
    public func libreTransmitterStateChanged(_ state: BluetoothmanagerState) {
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
    public func libreTransmitterReceivedMessage(_ messageIdentifier: UInt16, txFlags: UInt8, payloadData: Data) {
        guard let packet = MiaoMiaoResponseState(rawValue: txFlags) else {
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
            NotificationHelper.sendSensorChangeNotificationIfNeeded()
        case .noSensor:
            NSLog("dabear:: no libresensor detected")
            NotificationHelper.sendSensorNotDetectedNotificationIfNeeded(noSensor: true, devicename: transmitterName)
        case .frequencyChangedResponse:
            NSLog("dabear:: transmitter readout interval has changed!")

        default:
            //we don't care about the rest!
            break
        }

        return
    }

    var transmitterName = "Unknown device"

    func tryPersistSensorData(with sensorData: SensorData) {
        guard UserDefaults.standard.shouldPersistSensorData else {
            return
        }

        //yeah, we really really need to persist any changes right away
        var data = UserDefaults.standard.queuedSensorData ?? LimitedQueue<SensorData>()
        data.enqueue(sensorData)
        UserDefaults.standard.queuedSensorData = data
    }

    private var countTimesWithoutData : Int = 0
    //will be called on utility queue
    public func libreTransmitterDidUpdate(with sensorData: SensorData, and Device: LibreTransmitterMetadata) {
        print("dabear:: got sensordata: \(sensorData), bytescount: \( sensorData.bytes.count), bytes: \(sensorData.bytes)")

        NotificationHelper.sendLowBatteryNotificationIfNeeded(device: Device)
        NotificationHelper.sendInvalidSensorNotificationIfNeeded(sensorData: sensorData)
        NotificationHelper.sendInvalidChecksumIfDeveloper(sensorData)

        tryPersistSensorData(with: sensorData)

        guard sensorData.hasValidCRCs else {
            self.delegateQueue.async {
                self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .error(LibreError.checksumValidationError))
            }

            os_log("dit not get sensordata with valid crcs")
            return
        }

        NotificationHelper.sendSensorExpireAlertIfNeeded(sensorData: sensorData)

        transmitterName = Device.name

        guard sensorData.state == .ready || sensorData.state == .starting else {
            os_log("dabear:: got sensordata with valid crcs, but sensor is either expired or failed")
            self.delegateQueue.async {
            self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .error(LibreError.expiredSensor))
            }
            return
        }

        NSLog("dabear:: got sensordata with valid crcs, sensor was ready")
        self.lastValidSensorData = sensorData

        self.handleGoodReading(data: sensorData) { [weak self] error, glucose in
            guard let self = self else {
                NSLog("dabear:: handleGoodReading could not lock on self, aborting")
                return
            }
            if let error = error {
                NSLog("dabear:: handleGoodReading returned with error: \(error)")
                self.delegateQueue.async {
                    self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .error(error))
                }
                return
            }

            guard let glucose = glucose else {
                NSLog("dabear:: handleGoodReading returned with no data")
                self.delegateQueue.async {
                    self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .noData)
                }
                return
            }

            //We prefer to use local cached glucose value for the date to filter
            var startDate = self.latestBackfill?.startDate

            //
            // but that might not be available when loop is restarted for example
            //
            if startDate == nil {
                self.delegateQueue.sync {
                    startDate = self.cgmManagerDelegate?.startDateToFilterNewData(for: self)
                }
            }

            // add one second to startdate to make this an exclusive (non overlapping) match
            startDate = startDate?.addingTimeInterval(1)

            let device = self.proxy?.device
            let newGlucose = glucose
                .filterDateRange(startDate, nil)
                .filter { $0.isStateValid }
                .map {
                NewGlucoseSample(date: $0.startDate,
                                 quantity: $0.quantity,
                                 isDisplayOnly: false,
                                 syncIdentifier: $0.syncId,
                                 device: device)
                }


            if newGlucose.isEmpty {

                self.countTimesWithoutData &+= 1
            } else {
                self.latestBackfill = glucose.max { $0.startDate < $1.startDate }
                NSLog("dabear:: latestbackfill set to \(self.latestBackfill)")
                self.countTimesWithoutData = 0
            }


            NSLog("dabear:: handleGoodReading returned with \(newGlucose.count) entries")
            self.delegateQueue.async {
                var result : CGMResult
                // If several readings from a valid and running sensor come out empty,
                // we have (with a large degree of confidence) a sensor that has been
                // ripped off the body
                if self.countTimesWithoutData > 1 {
                    result = .error(LibreError.noValidSensorData)
                } else {
                    result = newGlucose.isEmpty ? .noData : .newData(newGlucose)
                }
                self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: result)
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
        //proxy?.OnQueue_identifer?.uuidString ?? "n/a"
        proxy?.viaManagerQueue.identifier?.uuidString ?? "n/a"
    }

    public var metaData: LibreTransmitterMetadata? {
        //proxy?.OnQueue_metadata
         proxy?.viaManagerQueue.metadata
    }

    //cannot be called from managerQueue
    public var connectionState: String {
        //proxy?.connectionStateString ?? "n/a"
        proxy?.viaManagerQueue.connectionStateString ?? "n/a"
    }
    //cannot be called from managerQueue
    public var sensorSerialNumber: String {
        //proxy?.OnQueue_sensorData?.serialNumber ?? "n/a"
        proxy?.viaManagerQueue.sensorData?.serialNumber ?? "n/a"
    }

    //cannot be called from managerQueue
    public var sensorAge: String {
        //proxy?.OnQueue_sensorData?.humanReadableSensorAge ?? "n/a"
        proxy?.viaManagerQueue.sensorData?.humanReadableSensorAge ?? "n/a"
    }

    //cannot be called from managerQueue
    public var sensorFooterChecksums: String {
        //(proxy?.OnQueue_sensorData?.footerCrc.byteSwapped).map(String.init)
        (proxy?.viaManagerQueue.sensorData?.footerCrc.byteSwapped).map(String.init)

            ?? "n/a"
    }

    //cannot be called from managerQueue
    public var sensorStateDescription: String {
        //proxy?.OnQueue_sensorData?.state.description ?? "n/a"
        proxy?.viaManagerQueue.sensorData?.state.description ?? "n/a"
    }
    //cannot be called from managerQueue
    public var firmwareVersion: String {
        proxy?.viaManagerQueue.metadata?.firmware ?? "n/a"
    }

    //cannot be called from managerQueue
    public var hardwareVersion: String {
        proxy?.viaManagerQueue.metadata?.hardware ?? "n/a"
    }

    //cannot be called from managerQueue
    public var batteryString: String {
        proxy?.viaManagerQueue.metadata?.batteryString ?? "n/a"
    }

    public var battery: Int? {
        proxy?.viaManagerQueue.metadata?.battery
    }

    public func getDeviceType() -> String {
        proxy?.viaManagerQueue.shortTransmitterName ?? "Unknown"
    }
    public func getSmallImage() -> UIImage? {
        proxy?.activePluginType?.smallImage ?? UIImage(named: "libresensor", in: Bundle.current, compatibleWith: nil)
    }
}
