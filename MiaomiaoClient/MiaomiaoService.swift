//
//  ShareService.swift
//  Loop
//
//  Created by Nate Racklyeft on 7/2/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation
import LoopKit


// Encapsulates the Dexcom Share client service and its authentication
public class MiaomiaoService: ServiceAuthentication {
    public var credentialValues: [String?]

    public let title: String = LocalizedString("MiaomiaoService", comment: "The title of the MiaomiaoService")

    public init() {

        
        credentialValues = [""]
        isAuthorized = true
        client = MiaomiaoClient()
        
    }

    // The share client
    private(set) var client: MiaomiaoClient?

   

    public var isAuthorized: Bool = false

    public func verify(_ completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
       

        /*let client = MiaomiaoClient()
        /*client.fetchLast(1) { (error, _) in
            completion(true, error)

        }*/
        self.client = client*/
        //TODO: don't always assume success
        completion(true, nil)
    }

    public func reset() {
        isAuthorized = false
        client = nil
    }
}



private let SpikeGlucoseServiceLabel = "MiaomiaoClient1"


