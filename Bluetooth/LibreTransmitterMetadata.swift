//
//  MiaoMiao.swift
//  LibreMonitor
//
//  Created by Uwe Petersen on 02.11.18.
//  Copyright © 2018 Uwe Petersen. All rights reserved.
//

import Foundation

public struct LibreTransmitterMetadata: CustomStringConvertible {
    // hardware number
    let hardware: String
    // software number
    let firmware: String
    // battery level, percentage between 0 % and 100 %
    let battery: Int
    // battery level String
    let batteryString: String

    let macAddress: String?

    init(hardware: String, firmware: String, battery: Int, macAddress: String?) {
        self.hardware = hardware
        self.firmware = firmware
        self.battery = battery
        self.batteryString = "\(battery) %"
        self.macAddress = macAddress
    }

    public var description: String {
         "Hardware: \(hardware), firmware: \(firmware), battery: \(batteryString), macAddress: \(macAddress)"
    }
}
