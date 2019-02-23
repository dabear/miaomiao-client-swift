//
//  MiaomiaoClient.h
//  MiaomiaoClient
//
//  Created by Mark Wilson on 5/7/16.
//  Copyright © 2016 Mark Wilson. All rights reserved.
//

import Foundation

public struct LibreGlucose {
    public let glucose: UInt16
    public let trend: UInt8
    public let timestamp: Date
    public let collector: String?
}
/*
extension SpikeGlucose: GlucoseValue {
    public var startDate: Date {
        return timestamp
    }
    
    public var quantity: HKQuantity {
        return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(glucose))
    }
}


extension SpikeGlucose: SensorDisplayable {
    public var isStateValid: Bool {
        return glucose >= 39
    }
    
    public var trendType: GlucoseTrend? {
        return GlucoseTrend(rawValue: Int(trend))
    }
    
    public var isLocal: Bool {
        return false
    }
}
*/


    

