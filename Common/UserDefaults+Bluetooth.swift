//
//  UserDefaults+Bluetooth.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 27/07/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
extension UserDefaults {
    
    private enum Key: String {
        case bluetoothDeviceUUID = "no.bjorninge.bluetoothDeviceUUID"
        
        
    }
   
    var selectedBluetoothDeviceIdentifer : String? {
        get {
            let val =  string(forKey: Key.bluetoothDeviceUUID.rawValue)
            if let val = val, val == "" {
                return nil
            }
            return val
        }
        set {
            set(newValue ?? "", forKey: Key.bluetoothDeviceUUID.rawValue)
        }
    }
    
    

    
}
