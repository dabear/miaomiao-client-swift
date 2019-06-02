//
//  GlucoseSchedules.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 19/04/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import HealthKit

enum GlucoseScheduleAlarmResult : Int, CaseIterable{

    case none = 0
    case low
    case high
    
}

class GlucoseScheduleList : Codable, CustomStringConvertible {

    var description: String {
        get {
            return "(schedules: \(schedules) )"
        }
    }
    
    public var schedules : [GlucoseSchedule] = [GlucoseSchedule]()
    
    public var enabledSchedules : [GlucoseSchedule]{
        get {
            
            let now = Date()
            let previousMidnight = Calendar.current.startOfDay(for: now)
            let helper  = Calendar.current.date(byAdding: .day, value: 1, to: previousMidnight)!
            let nextMidnight = Calendar.current.startOfDay(for: helper)
            return schedules.compactMap {
                if $0.enabled ?? false, let fromComponents = $0.from, let toComponents = $0.to{
                    
                    
                    
                    let fromDate : Date? =  Calendar.current.date(byAdding: fromComponents, to: previousMidnight)
                    var toDate : Date?
                    if  toComponents.minute == 0 && toComponents.hour == 0 {
                        toDate = nextMidnight
                   
                    } else {
                        toDate = Calendar.current.date(byAdding: toComponents, to: previousMidnight)!
                    }
                    
                    
                    
                    if let fromDate=fromDate, let toDate=toDate {
                        return (fromDate ... toDate).contains(now) ? $0 : nil
                    }
                    
                }
                return nil
            }
        }
    }
    
    public func getActiveAlarms(_ currentGlucoseInMGDL: Double) -> GlucoseScheduleAlarmResult{
        let mySchedules = self.enabledSchedules
        
        for schedule in mySchedules {
            if let lowAlarm = schedule.lowAlarm,  currentGlucoseInMGDL <= currentGlucoseInMGDL{
                return .low
            }
            if let highAlarm = schedule.highAlarm, currentGlucoseInMGDL >= currentGlucoseInMGDL {
                return .high
            }
        }
        return .none
    }
    
    
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
    
    
    
    
    
    
    
    var description : String {
        get {
            return "(from: \(from), to: \(to), low: \(lowAlarm), high: \(highAlarm), enabled: \(enabled))"
        }
    }
}



