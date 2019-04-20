//
//  GlucoseSchedules.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 19/04/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import HealthKit

class GlucoseScheduleList : Codable, CustomStringConvertible {

    var description: String {
        get {
            return "(schedules: \(schedules) )"
        }
    }
    
    public var schedules : [GlucoseSchedule]? = [GlucoseSchedule]()
    
    
}

class GlucoseSchedule: Codable, CustomStringConvertible{
    

    var from: DateComponents?
    var to: DateComponents?
    var lowAlarm: Double?
    var highAlarm: Double?
    var glucoseUnitIsMgdl : Bool?
    var enabled: Bool?
    
    init() {
        
    }
    
    
    
    var description : String {
        get {
            return "(from: \(from), to: \(to), low: \(lowAlarm), high: \(highAlarm), glucoseUnitIsMgdl: \(glucoseUnitIsMgdl), enabled: \(enabled))"
        }
    }
}



