//
//  SpikeClientManager.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import LoopKit
import HealthKit


public class SpikeClientManager: CGMManager {
    public static var managerIdentifier = "DexSpikeClient1"

    public init() {
        spikeService = SpikeService(keychainManager: keychain)
    }

    required convenience public init?(rawState: CGMManager.RawStateValue) {
        self.init()
    }

    public var rawState: CGMManager.RawStateValue {
        return [:]
    }

    private let keychain = KeychainManager()

    public var spikeService: SpikeService {
        didSet {
            try! keychain.setSpikeUsername(spikeService.username, password: spikeService.password, url: spikeService.url)
        }
    }

    public static let localizedTitle = LocalizedString("Spike", comment: "Title for the CGMManager option")

    public let appURL: URL? = URL(string: "spikeapp://")

    weak public var cgmManagerDelegate: CGMManagerDelegate?

    public let providesBLEHeartbeat = false

    public let shouldSyncToRemoteService = false

    public var sensorState: SensorDisplayable? {
        return latestBackfill
    }

    public let managedDataInterval: TimeInterval? = nil

    public private(set) var latestBackfill: SpikeGlucose?
    
    public var latestSpikeCollector: String? {
        if let glucose = latestBackfill, let collector = glucose.collector, collector != "unknown" {
            return collector
        }
        return nil
    }

    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMResult) -> Void) {
        guard let spikeClient = spikeService.client else {
            completion(.noData)
            return
        }

        // If our last glucose was less than 4.5 minutes ago, don't fetch.
        if let latestGlucose = latestBackfill, latestGlucose.startDate.timeIntervalSinceNow > -TimeInterval(minutes: 4.5) {
            completion(.noData)
            return
        }

        spikeClient.fetchLast(6) { (error, glucose) in
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
        }
    }

    public var device: HKDevice? {
        
        return HKDevice(
            name: "SpikeClient",
            manufacturer: "Spike",
            model: latestSpikeCollector,
            hardwareVersion: nil,
            firmwareVersion: nil,
            softwareVersion: nil,
            localIdentifier: nil,
            udiDeviceIdentifier: nil
        )
    }

    public var debugDescription: String {
        return [
            "## SpikeClientManager",
            "latestBackfill: \(String(describing: latestBackfill))",
            "latestCollector: \(String(describing: latestSpikeCollector))",
            ""
        ].joined(separator: "\n")
    }
}
