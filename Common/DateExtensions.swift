//
//  DateExtensions.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 07/03/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation

extension Date {
    
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
}
