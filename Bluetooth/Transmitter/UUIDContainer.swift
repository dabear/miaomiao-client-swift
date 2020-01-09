//
//  UUIDContainer.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 08/01/2020.
//  Copyright © 2020 Mark Wilson. All rights reserved.
//

import Foundation
import CoreBluetooth
public struct UUIDContainer: ExpressibleByStringLiteral{
    var value: CBUUID

    init(value: CBUUID) {
        self.value = value
    }
    public init(stringLiteral value: String) {
        self.value = CBUUID(string: value)
    }


}
