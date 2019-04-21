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
    private func storedGlucoseUnit()-> HKUnit? {
        if let glucoseUnitIsMgdl = glucoseUnitIsMgdl {
            return glucoseUnitIsMgdl ? HKUnit.milligramsPerDeciliter : HKUnit.millimolesPerLiter
        }
        return nil
    }
    
    public func glucose(forUnit wantsUnit:HKUnit, type glucoseType: GlucoseAlarmType)-> Double? {
        let value = glucoseType == GlucoseAlarmType.high ? highAlarm : lowAlarm
        
        if let value = value {
            if let storedUnit = storedGlucoseUnit() {
                if storedUnit == wantsUnit {
                    // no convertion needed
                    return value
                }
                
                if storedUnit == HKUnit.milligramsPerDeciliter && wantsUnit == HKUnit.millimolesPerLiter{
                        return value / 18
                }
                
                if storedUnit == HKUnit.millimolesPerLiter && wantsUnit == HKUnit.millimolesPerLiter{
                        return value * 18
                    
                }
                
                
            }
        }
        
        return nil
    }
    
    
    var description : String {
        get {
            return "(from: \(from), to: \(to), low: \(lowAlarm), high: \(highAlarm), glucoseUnitIsMgdl: \(glucoseUnitIsMgdl), enabled: \(enabled))"
        }
    }
}



