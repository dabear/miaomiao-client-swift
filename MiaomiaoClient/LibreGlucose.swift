//
//  MiaomiaoClient.h
//  MiaomiaoClient
//
//  Created by Mark Wilson on 5/7/16.
//  Copyright © 2016 Mark Wilson. All rights reserved.
//

import Foundation
import LoopKit
import HealthKit

public struct LibreGlucose {
    public let unsmoothedGlucose: Double
    public var glucoseDouble: Double
    public var glucose: UInt16 {
        return UInt16(glucoseDouble.rounded())
    }
    public var trend: UInt8
    public let timestamp: Date
    public let collector: String?
}

extension LibreGlucose: GlucoseValue {
    public var startDate: Date {
        return timestamp
    }

    public var quantity: HKQuantity {
        return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(glucose))
    }
}

extension LibreGlucose: SensorDisplayable {
    public var isStateValid: Bool {
        return glucose >= 39
    }

    public var trendType: GlucoseTrend? {
        return GlucoseTrend(rawValue: Int(trend))
    }

    public var isLocal: Bool {
        return true
    }
}

extension LibreGlucose {
    static func fromHistoryMeasurements(_ measurements: [Measurement]) -> [LibreGlucose] {
        var arr = [LibreGlucose]()

        for historical in measurements {
            let glucose = LibreGlucose(unsmoothedGlucose: historical.temperatureAlgorithmGlucose, glucoseDouble: historical.temperatureAlgorithmGlucose, trend: UInt8(GlucoseTrend.flat.rawValue), timestamp: historical.date, collector: "MiaoMiao")
            arr.append(glucose)
        }

        return arr
    }

    static func fromTrendMeasurements(_ measurements: [Measurement]) -> [LibreGlucose] {
        var origarr = [LibreGlucose]()

        //whether or not to return all the 16 latest trends or just every fifth element
        let returnAllTrends = true

        for trend in measurements {
            let glucose = LibreGlucose(unsmoothedGlucose: trend.temperatureAlgorithmGlucose, glucoseDouble: 0.0, trend: UInt8(GlucoseTrend.flat.rawValue), timestamp: trend.date, collector: "MiaoMiao")
            origarr.append(glucose)
        }
        //NSLog("dabear:: glucose samples before smoothing: \(String(describing: origarr))")
        var arr: [LibreGlucose]
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

}

