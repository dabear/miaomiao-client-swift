//
//  MiaomiaoClient.h
//  MiaomiaoClient
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
    //trend is deprecated here, it should only be calculated once in latestbackfill
    //public var trend: UInt8
    public let timestamp: Date
    //public let collector: String?

    public static func timeDifference(oldGlucose: LibreGlucose, newGlucose: LibreGlucose) -> TimeInterval {
        newGlucose.startDate.timeIntervalSince(oldGlucose.startDate)
    }

    public var syncId : String {
        "\(Int(self.startDate.timeIntervalSince1970))\(self.unsmoothedGlucose)"
    }

    public var isStateValid: Bool {
        // We know that the official libre algorithm doesn't produce values
        // below 39. However, both the raw sensor contents and the derived algorithm
        // supports values down to 0 without issues. A bit uncertain if nightscout and loop will work with values below 1, so we restrict this to 1
        glucose >= 1
    }
}

extension LibreGlucose: GlucoseValue {
    public var startDate: Date {
        timestamp
    }

    public var quantity: HKQuantity {
        .init(unit: .milligramsPerDeciliter, doubleValue: glucoseDouble)
    }
}

extension LibreGlucose {

    public var description : String{
        guard let glucoseUnit = UserDefaults.standard.mmGlucoseUnit, let formatter = LibreGlucose.dynamicFormatter, let formatted = formatter.string(from: self.quantity, for: glucoseUnit) else {
            NSLog("dabear:: glucose unit was not recognized, aborting")
            return "Unknown"
        }

        return formatted

    }
    private static var glucoseFormatterMgdl: QuantityFormatter = {
        let formatter = QuantityFormatter()
        formatter.setPreferredNumberFormatter(for: HKUnit.milligramsPerDeciliter)
        return formatter
    }()

    private static var glucoseFormatterMmol: QuantityFormatter = {
        let formatter = QuantityFormatter()
        formatter.setPreferredNumberFormatter(for: HKUnit.millimolesPerLiter)
        return formatter
    }()

    public static var dynamicFormatter: QuantityFormatter? {
        guard let glucoseUnit = UserDefaults.standard.mmGlucoseUnit else {
            NSLog("dabear:: glucose unit was not recognized, aborting")
            return nil
        }

        return (glucoseUnit == HKUnit.milligramsPerDeciliter ? glucoseFormatterMgdl : glucoseFormatterMmol)
    }

    public static func glucoseDiffDesc(oldValue: Self, newValue: Self)  -> String{
        guard let glucoseUnit = UserDefaults.standard.mmGlucoseUnit else {
            NSLog("dabear:: glucose unit was not recognized, aborting")
            return "Unknown"
        }

        var stringValue = [String]()

        var diff = newValue.glucoseDouble - oldValue.glucoseDouble
        let sign = diff < 0 ? "-" : "+"

        if diff == 0 {
            stringValue.append( "\(sign) 0")
        } else {
            diff = abs(diff)
            let asObj = LibreGlucose(
                unsmoothedGlucose: diff,
                glucoseDouble: diff,
                timestamp: Date())
            if let formatted = dynamicFormatter?.string(from: asObj.quantity, for: glucoseUnit) {
                stringValue.append( "\(sign) \(formatted)")
            }
        }

        return stringValue.joined(separator: ",")
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

            let glucose = LibreGlucose(
                unsmoothedGlucose: historical.temperatureAlgorithmGlucose,
                glucoseDouble: historical.temperatureAlgorithmGlucose,
                timestamp: historical.date)
            arr.append(glucose)
        }

        return arr
    }

    static func fromTrendMeasurements(_ measurements: [Measurement], returnAll: Bool) -> [LibreGlucose] {
        var arr = [LibreGlucose]()

        var shouldSmoothGlucose = true
        for trend in measurements {
            // if sensor is ripped off body while transmitter is attached, values below 1 might be created
            // this will also disable smoothing for sensors started less than 16 minuttes ago
            if trend.temperatureAlgorithmGlucose < 1 {
                shouldSmoothGlucose = false
                continue
            }
            // trend arrows on each libreglucose value is not needed
            // instead we calculate it once when latestbackfill is set, which in turn sets
            // the sensordisplayable property
            let glucose = LibreGlucose(
                unsmoothedGlucose: trend.temperatureAlgorithmGlucose,
                glucoseDouble: 0.0,
                timestamp: trend.date)
            arr.append(glucose)
        }
        //NSLog("dabear:: glucose samples before smoothing: \(String(describing: origarr))")

        if shouldSmoothGlucose {
            arr = CalculateSmothedData5Points(origtrends: arr)
        } else {
            for i in 0 ..< arr.count {
                arr[i].glucoseDouble = arr[i].unsmoothedGlucose
            }
        }



        if !returnAll, let first = arr.first {
            return [first]
        }

        return arr



    }
}
