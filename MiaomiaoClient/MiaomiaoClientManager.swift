//
//  MiaomiaoClientManager.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import LoopKit
import HealthKit


public class MiaomiaoClientManager: CGMManager {
    public var sensorState: SensorDisplayable?
    
    public static var managerIdentifier = "DexMiaomiaoClient1"

    public init() {
        miaomiaoService = MiaomiaoService()
    }

    required convenience public init?(rawState: CGMManager.RawStateValue) {
        self.init()
    }

    public var rawState: CGMManager.RawStateValue {
        return [:]
    }

    private let keychain = KeychainManager()

    public var miaomiaoService: MiaomiaoService

    public static let localizedTitle = LocalizedString("Miaomiao", comment: "Title for the CGMManager option")

    public let appURL: URL? = nil //URL(string: "spikeapp://")

    weak public var cgmManagerDelegate: CGMManagerDelegate?

    public let providesBLEHeartbeat = false

    public let shouldSyncToRemoteService = false

    /*public var sensorState: SensorDisplayable? {
        return latestBackfill
    }**/

    public let managedDataInterval: TimeInterval? = nil

    //public private(set) var latestBackfill: SpikeGlucose?

    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMResult) -> Void) {
        guard let client = miaomiaoService.client else {
            completion(.noData)
            return
        }
        
        client.autoconnect()
        
        completion(.noData)
        
        // If our last glucose was less than 4.5 minutes ago, don't fetch.
        /*if let latestGlucose = latestBackfill, latestGlucose.startDate.timeIntervalSinceNow > -TimeInterval(minutes: 4.5) {
            completion(.noData)
            return
        }*/

        /*spikeClient.fetchLast(6) { (error, glucose) in
            if let error = error {
                completion(.error(error))
                return
            }
            guard let glucose = glucose else {
                completion(.noData)
                return
            }

            // Ignore glucose values that are up to a minute newer than our previous value, to account for possible time shifting in Share data
            let startDate = self.cgmManagerDelegate?.startDateToFilterNewData(for: self)?.addingTimeInterval(TimeInterval(minutes: 1))
            let newGlucose = glucose.filterDateRange(startDate, nil).filter({ $0.isStateValid }).map {
                return NewGlucoseSample(date: $0.startDate, quantity: $0.quantity, isDisplayOnly: false, syncIdentifier: "\(Int($0.startDate.timeIntervalSince1970))", device: self.device)
            }

            self.latestBackfill = glucose.first

            if newGlucose.count > 0 {
                completion(.newData(newGlucose))
            } else {
                completion(.noData)
            }
        }*/
    }

    public var device: HKDevice? {
        let client =  miaomiaoService.client
        
        return HKDevice(
            name: "MiaomiaoClient",
            manufacturer: "Tomato",
            model: nil, //latestSpikeCollector,
            hardwareVersion: client?.hardwareVersion,
            firmwareVersion: client?.firmwareVersion,
            softwareVersion: nil,
            localIdentifier: nil,
            udiDeviceIdentifier: nil
        )
    }

    public var debugDescription: String {
        let client =  miaomiaoService.client
        return [
            "## MiaomiaoClientManager",
            "Testdata: foo",
            "lastConnected: \(String(describing: client?.lastConnected)))",
            "Connection state: \(String(describing: client?.connectionState)))",
            "Sensor state: \(String(describing: client?.sensorState)))",
            "bridge battery: \(String(describing: client?.battery)))",
            //"latestBackfill: \(String(describing: "latestBackfill))",
            //"latestCollector: \(String(describing: latestSpikeCollector))",
            ""
        ].joined(separator: "\n")
    }
}
