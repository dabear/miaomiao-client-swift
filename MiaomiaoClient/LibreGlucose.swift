//
//  MiaomiaoClient.h
//  MiaomiaoClient
//
//  Created by Mark Wilson on 5/7/16.
//  Copyright © 2016 Mark Wilson. All rights reserved.
//

import Foundation
import HealthKit
import LoopKit

public struct LibreGlucose {
    public let unsmoothedGlucose: Double
    public var glucoseDouble: Double
    public var glucose: UInt16 {
        UInt16(glucoseDouble.rounded())
    }
    public var trend: UInt8
    public let timestamp: Date
    public let collector: String?

    public static func timeDifference(oldGlucose: LibreGlucose, newGlucose: LibreGlucose) -> TimeInterval {
        newGlucose.startDate.timeIntervalSince(oldGlucose.startDate)
    }
}

extension LibreGlucose: GlucoseValue {
    public var startDate: Date {
        timestamp
    }

    public var quantity: HKQuantity {
         HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(glucose))
    }
}

extension LibreGlucose: SensorDisplayable {
    public var isStateValid: Bool {
        glucose >= 39
    }

    public var trendType: GlucoseTrend? {
        GlucoseTrend(rawValue: Int(trend))
    }

    public var isLocal: Bool {
        true
    }
}

extension LibreGlucose {
    static func fromHistoryMeasurements(_ measurements: [Measurement]) -> [LibreGlucose] {
        var arr = [LibreGlucose]()

        for historical in measurements {
            guard historical.temperatureAlgorithmGlucose > 0 else {
                print("dabear:: historical glucose not available, skipping: \(historical.temperatureAlgorithmGlucose)")
                continue
            }

            let glucose = LibreGlucose(unsmoothedGlucose: historical.temperatureAlgorithmGlucose, glucoseDouble: historical.temperatureAlgorithmGlucose, trend: UInt8(GlucoseTrend.flat.rawValue), timestamp: historical.date, collector: "MiaoMiao")
            arr.append(glucose)
        }

        return arr
    }

    static func fromTrendMeasurements(_ measurements: [Measurement], returnAll: Bool) -> [LibreGlucose] {
        var origarr = [LibreGlucose]()

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
            let arrow = TrendArrowCalculations.GetGlucoseDirection(current: trend, last: arr[safe: i + 5])
            arr[i].trend = UInt8(arrow.rawValue)
            //NSLog("Date: \(trend.timestamp), before: \(trend.unsmoothedGlucose), after: \(trend.glucose), arrow: \(trend.trend)")
        }

        if returnAll {
            return arr
        }

        if let first = arr.first {
            return [first]
        }

        return [LibreGlucose]()
        /*
        var filtered = [LibreGlucose]()
        for elm in arr.enumerated() where elm.offset % 5 == 0 {
            filtered.append(elm.element)
        }

        //NSLog("dabear:: glucose samples after smoothing: \(String(describing: arr))")
        return filtered
         */
    }
}
