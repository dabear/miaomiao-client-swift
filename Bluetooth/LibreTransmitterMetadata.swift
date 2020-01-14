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
    public let hardware: String
    // software number
    public let firmware: String
    // battery level, percentage between 0 % and 100 %
    public let battery: Int
    // battery level String
    public let batteryString: String

    public let macAddress: String?

    public let name: String

    init(hardware: String, firmware: String, battery: Int, name:String, macAddress: String?) {
        self.hardware = hardware
        self.firmware = firmware
        self.battery = battery
        self.batteryString = "\(battery) %"
        self.macAddress = macAddress
        self.name = name
    }

    public var description: String {
         "Hardware: \(hardware), firmware: \(firmware), battery: \(batteryString), macAddress: \(macAddress)"
    }
}
