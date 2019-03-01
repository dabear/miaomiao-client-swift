//
//  ShareService.swift
//  Loop
//
//  Created by Nate Racklyeft on 7/2/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation
import LoopKit
import os.log

// Encapsulates the Dexcom Share client service and its authentication
public class MiaomiaoService: ServiceAuthentication {
    public var credentialValues: [String?]

    public let title: String = LocalizedString("MiaomiaoService", comment: "The title of the MiaomiaoService")

    public init() {

        
        credentialValues = [""]
        isAuthorized = true
        client = MiaoMiaoProxy()
        //client?.connect()
        
    }

    // The share client
    private(set) var client: MiaoMiaoProxy?

    
   

    public var isAuthorized: Bool = false

    public func verify(_ completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        client = MiaoMiaoProxy()

        /*let client = MiaomiaoClient()
        /*client.fetchLast(1) { (error, _) in
            completion(true, error)

        }*/
        self.client = client*/
        //TODO: don't always assume success
        completion(true, nil)
    }

    public func reset() {
        os_log("dabear:: miaomiaoservice reset called")
        isAuthorized = false
        client = nil
    }
    
    deinit {
        os_log("dabear:: miaomiaoservice deinit called")
        client?.disconnectManually()
        client = nil
    }
}



private let SpikeGlucoseServiceLabel = "MiaomiaoClient1"


