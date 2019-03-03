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
    
    public static var managerIdentifier = "DexMiaomiaoClient1"

    public init() {
        os_log("dabear:: MiaomiaoClientManager init")
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

    public static let localizedTitle = ""

    public let appURL: URL? = nil //URL(string: "spikeapp://")

    weak public var cgmManagerDelegate: CGMManagerDelegate?

    public let providesBLEHeartbeat = false

    public let shouldSyncToRemoteService = false

   

    public let managedDataInterval: TimeInterval? = nil

    //public private(set) var latestBackfill: SpikeGlucose?

    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMResult) -> Void) {
        
        
        
        completion(.noData)
        
       
    }
   
    public var device: HKDevice? {
        return nil
    }

    public var debugDescription: String {
       return "somedebugdescription"
    }
}
