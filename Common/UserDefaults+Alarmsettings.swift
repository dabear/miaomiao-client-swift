//
//  Userdefaults+Alarmsettings.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 20/04/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    private enum Key: String {
        case glucoseSchedules = "no.bjorninge.glucoseschedules"
    }
    
    var glucoseSchedules: GlucoseScheduleList? {
        get {

            if let savedGlucoseSchedules = object(forKey: Key.glucoseSchedules.rawValue) as? Data {
                let decoder = JSONDecoder()
                if let loadedGlucoseSchedules = try? decoder.decode(GlucoseScheduleList.self, from: savedGlucoseSchedules) {
                    return loadedGlucoseSchedules
                }
            }
            
            return nil
        }
        set {
            let encoder = JSONEncoder()
            if let val = newValue, let encoded = try? encoder.encode(val) {
                set(encoded, forKey: Key.glucoseSchedules.rawValue)
            }
            
           
        }
    }
}
