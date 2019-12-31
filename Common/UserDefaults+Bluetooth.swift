//
//  UserDefaults+Bluetooth.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 27/07/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import MiaomiaoClient

extension UserDefaults {
    private enum Key: String {
        case bluetoothDeviceUUIDString = "no.bjorninge.bluetoothDeviceUUIDString"

    }

    public var preSelectedDevice: String? {
        get {
            print("getting Key.bluetoothDeviceUUIDString.rawValue: \(Key.bluetoothDeviceUUIDString.rawValue) ")
            if let astr = string(forKey: Key.bluetoothDeviceUUIDString.rawValue) {
                return astr.count > 0 ? astr : nil
            }
            return nil
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Key.bluetoothDeviceUUIDString.rawValue)
            } else {
                removeObject(forKey: Key.bluetoothDeviceUUIDString.rawValue)
            }

        }

    }
}
