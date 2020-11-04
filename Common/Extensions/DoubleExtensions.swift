//
//  DoubleExtensions.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 25/03/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import Foundation

extension Double {
    func roundTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    var twoDecimals: String {
        String(format: "%.2f", self)
    }
    var fourDecimals: String {
        String(format: "%.4f", self)
    }

    enum Number {
        static var formatter = NumberFormatter()
    }

    var scientificStyle: String {
        Number.formatter.numberStyle = .scientific
        Number.formatter.positiveFormat = "0.###E+0"
        Number.formatter.exponentSymbol = "e"
        let number = NSNumber(value: self)
        return Number.formatter.string(from: number) ?? description
    }
}
