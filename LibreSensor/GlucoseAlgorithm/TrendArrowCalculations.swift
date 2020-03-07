//
//  TrendArrowCalculations.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 26/03/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import Foundation
import LoopKit

//https://github.com/dabear/FloatingGlucose/blob/master/FloatingGlucose/Classes/Utils/GlucoseMath.cs

enum TrendArrowCalculations {
    static func calculateSlope(current: LibreGlucose, last: LibreGlucose) -> Double {
        if current.timestamp == last.timestamp {
            return 0.0
        }

        let _curr = Double(current.timestamp.timeIntervalSince1970 * 1_000)
        let _last = Double(last.timestamp.timeIntervalSince1970 * 1_000)

        return (Double(last.unsmoothedGlucose) - Double(current.unsmoothedGlucose)) / (_last - _curr)
    }

    static func calculateSlopeByMinute(current: LibreGlucose, last: LibreGlucose) -> Double {
        return calculateSlope(current: current, last: last) * 60_000
    }

    static func GetGlucoseTrend(current: LibreGlucose?, last: LibreGlucose?) -> GlucoseTrend {
        //NSLog("GetGlucoseDirection:: current:\(current), last: \(last)")
        guard let current = current, let last = last else {
            return  .flat
        }

        let  s = calculateSlopeByMinute(current: current, last: last)
        //NSLog("Got trendarrow value of \(s))")

        switch s {
        case _ where s <= (-3.5):
            return .downDownDown
        case _ where s <= (-2):
            return .downDown
        case _ where s <= (-1):
            return .down
        case _ where s <= (1):
            return .flat
        case _ where s <= (2):
            return .up
        case _ where s <= (3.5):
            return .upUp
        case _ where s <= (40):
            return .flat //flat is the new (tm) "unknown"!

        default:
            NSLog("Got unknown trendarrow value of \(s))")
            return .flat
        }
    }
}
