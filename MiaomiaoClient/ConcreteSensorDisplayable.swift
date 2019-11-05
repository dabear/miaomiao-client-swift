//
//  ConcreteSensorDisplayable.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 04/11/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import HealthKit
import LoopKit

public struct ConcreteSensorDisplayable : SensorDisplayable {
    public var isStateValid: Bool

    public var trendType: GlucoseTrend?

    public var isLocal: Bool


}
