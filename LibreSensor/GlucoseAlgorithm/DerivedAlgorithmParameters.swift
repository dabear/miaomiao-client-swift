//
//  DerivedAlgorithmParameters.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 05/03/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import Foundation
 // Parameters for temperature compensation algo, see here: https://github.com/UPetersen/LibreMonitor/wiki/Libre-OOP-Investigation#variation-of-temperature
public struct DerivedAlgorithmParameters: Codable, CustomStringConvertible {
    public var slope_slope: Double
    public var slope_offset: Double
    public var offset_slope: Double
    public var offset_offset: Double
    public var isValidForFooterWithReverseCRCs: Int
    public var extraSlope: Double = 1
    public var extraOffset: Double = 0

    public var description: String {
        "DerivedAlgorithmParameters(slope_slope: \(slope_slope), slope_offset: \(slope_offset), offset_slope: \(offset_slope), offset_offset: \(offset_offset), isValidForFooterWithReverseCRCs: \(isValidForFooterWithReverseCRCs), extraSlope: \(extraSlope)), extraOffset: \(extraOffset))"
    }

    public init(slope_slope: Double, slope_offset: Double, offset_slope: Double, offset_offset: Double, isValidForFooterWithReverseCRCs: Int, extraSlope: Double, extraOffset: Double) {
        self.slope_slope = slope_slope
        self.slope_offset = slope_offset
        self.offset_slope = offset_slope
        self.offset_offset = offset_offset
        self.isValidForFooterWithReverseCRCs = isValidForFooterWithReverseCRCs
        self.extraSlope = extraSlope
        self.extraOffset = extraOffset
    }
}
