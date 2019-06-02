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
    
    public var schedules : [GlucoseSchedule] = [GlucoseSchedule]()
    
    
}

class GlucoseSchedule: Codable, CustomStringConvertible{
    

    var from: DateComponents?
    var to: DateComponents?
    var lowAlarm: Double?
    var highAlarm: Double?
    var enabled: Bool?
    
    init() {
        
    }
    
    public func storeLowAlarm(forUnit unit: HKUnit, lowAlarm: Double) {
        if unit == HKUnit.millimolesPerLiter {
            self.lowAlarm = lowAlarm * 18
            return
        }
        
        self.lowAlarm = lowAlarm
    }
    public func retrieveLowAlarm(forUnit unit: HKUnit) -> Double?{
        
        if let lowAlarm = self.lowAlarm {
            if unit == HKUnit.millimolesPerLiter {
                return (lowAlarm / 18).roundTo(places: 1)
            } else {
                return lowAlarm
            }
        }

        return nil
    }
    
    public func storeHighAlarm(forUnit unit: HKUnit, highAlarm: Double) {
        if unit == HKUnit.millimolesPerLiter {
            self.highAlarm = highAlarm * 18
            return
        }
        
        self.highAlarm = highAlarm
    }
    public func retrieveHighAlarm(forUnit unit: HKUnit) -> Double?{
        
        if let highAlarm = self.highAlarm {
            if unit == HKUnit.millimolesPerLiter {
                return (highAlarm / 18).roundTo(places: 1)
            }
            return highAlarm
                
            
        }
            
            
        
        
        return nil
    }
    
    
    
    
    /*public func glucose(forUnit wantsUnit:HKUnit, type glucoseType: GlucoseAlarmType)-> Double? {
        let value = glucoseType == GlucoseAlarmType.high ? highAlarm : lowAlarm
        
        if let value = value {

            if wantsUnit == HKUnit.millimolesPerLiter{
                return value / 18
            }
            return value
            
        }
        
        return nil
    }*/
    
    
    var description : String {
        get {
            return "(from: \(from), to: \(to), low: \(lowAlarm), high: \(highAlarm), enabled: \(enabled))"
        }
    }
}



