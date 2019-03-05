//
//  LibreError.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 05/03/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation

public enum LibreError: Error {
    case noSensorData
    case noCalibrationData
    case invalidCalibrationData
}
