//
//  MiaomiaoClientManager.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import LoopKit
import HealthKit
import os.log


public class MiaomiaoClientManager: CGMManager {
    public var sensorState: SensorDisplayable?
    public private(set) var latestBackfill: LibreGlucose?
    public static var managerIdentifier = "DexMiaomiaoClient1"
    
    private static var instanceCount = 0 {
        didSet {
            
            //this is to workaround a bug where multiple managers might exist
            os_log("dabear:: MiaomiaoClientManager instanceCount changed to %s", type: .default, String(describing: instanceCount))
            if instanceCount < 1 {
                os_log("dabear:: instancecount is 0, deiniting service", type: .default)
                MiaomiaoClientManager.sharedInstance = nil
            }
            //this is another attempt to workaround a bug where multiple managers might exist
            if oldValue > instanceCount {
                os_log("dabear:: MiaomiaoClientManager decremented, stop all miaomiao bluetooth services")
                MiaomiaoClientManager.sharedInstance = nil
            }
           
            
        }
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

    public init() {
        let thisType = type(of: self)
        os_log("dabear:: MiaomiaoClientManager init, typeofself: %s", type:.default, String(describing: thisType))
        MiaomiaoClientManager.instanceCount += 1
       
    }
    
    deinit {
        os_log("dabear:: MiaomiaoClientManager deinit")
        MiaomiaoClientManager.instanceCount -= 1
    }

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

    public let shouldSyncToRemoteService = false

    /*public var sensorState: SensorDisplayable? {
        return latestBackfill
    }**/

    public let managedDataInterval: TimeInterval? = nil

    //public private(set) var latestBackfill: SpikeGlucose?

    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMResult) -> Void) {
        guard let client = MiaomiaoClientManager.miaomiaoService.client else {
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
        let client =  MiaomiaoClientManager.miaomiaoService.client
        //bla
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
        let client =  MiaomiaoClientManager.miaomiaoService.client
        return [
            "## MiaomiaoClientManager",
            "Testdata: foo",
            "lastConnected: \(String(describing: client?.lastConnected))",
            "Connection state: \(String(describing: client?.connectionState))",
            "Sensor state: \(String(describing: client?.sensorState))",
            "bridge battery: \(String(describing: client?.battery))",
            //"latestBackfill: \(String(describing: "latestBackfill))",
            //"latestCollector: \(String(describing: latestSpikeCollector))",
            ""
        ].joined(separator: "\n")
    }
}
