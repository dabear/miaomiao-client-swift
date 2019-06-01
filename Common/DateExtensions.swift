//
//  DateExtensions.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 07/03/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation

public extension Date {
    
    func rounded(on amount: Int, _ component: Calendar.Component) -> Date {
        let cal = Calendar.current
        let value = cal.component(component, from: self)
        
        // Compute nearest multiple of amount:
        let roundedValue = lrint(Double(value) / Double(amount)) * amount
        let newDate = cal.date(byAdding: component, value: roundedValue - value, to: self)!
        
        return newDate.floorAllComponents(before: component)
    }
    
    func floorAllComponents(before component: Calendar.Component) -> Date {
        // All components to round ordered by length
        let components = [Calendar.Component.year, .month, .day, .hour, .minute, .second, .nanosecond]
        
        guard let index = components.index(of: component) else {
            fatalError("Wrong component")
        }
        
        let cal = Calendar.current
        var date = self
        
        components.suffix(from: index + 1).forEach { roundComponent in
            let value = cal.component(roundComponent, from: date) * -1
            date = cal.date(byAdding: roundComponent, value: value, to: date)!
        }
        
        return date
    }
    
    public static var LocaleWantsAMPM : Bool{
        return DateFormatter.dateFormat(fromTemplate: "j", options:0, locale:NSLocale.current)!.contains("a")
    }
    
}

extension DateComponents {
    func ToTimeString(wantsAMPM: Bool=Date.LocaleWantsAMPM) -> String {
        
        print("hour: \(self.hour) minute: \(self.minute)")
        let date = Calendar.current.date(bySettingHour: self.hour ?? 0, minute: self.minute ?? 0, second: 0, of: Date())!
        
        
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.long
        formatter.timeStyle = DateFormatter.Style.medium
        
        formatter.dateFormat = wantsAMPM ? "hh:mm a" : "HH:mm"
        return formatter.string(from: date)
        
    }
}

extension TimeInterval{
    
    func stringDaysFromTimeInterval() -> String {
        
        let aday = 86400.0 //in seconds
        let time = Double(self).magnitude
        
        let days = time / aday
        
        
        return days.twoDecimals
        
    }
}
