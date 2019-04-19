//
//  GlucoseSchedules.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 19/04/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import HealthKit


class GlucoseSchedule: CustomStringConvertible {
    var from: DateComponents?
    var to: DateComponents?
    var lowAlarm: NSNumber?
    var highAlarm: NSNumber?
    var glucoseUnit: HKUnit?
    var enabled: Bool?
    
    init() {
        
    }
    
    var description : String {
        get {
            return "from: \(from), to: \(to), low: \(lowAlarm), high: \(highAlarm), glucoseUnit: \(glucoseUnit), enabled: \(enabled)"
        }
    }
}
