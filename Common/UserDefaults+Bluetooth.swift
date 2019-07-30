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
        case bluetoothDeviceUUID = "no.bjorninge.bluetoothDeviceUUID"
        case bluetoothDevice = "no.bjorninge.bluetoothDevice"
        
        
    }
    
    var preSelectedDevice : CompatibleLibreBluetoothDevice? {
        
        get {
            
            if let savedPreSelectedDevice = object(forKey: Key.bluetoothDevice.rawValue) as? Data {
                let decoder = JSONDecoder()
                if let loadedPreselectedDevice = try? decoder.decode(CompatibleLibreBluetoothDevice.self, from: savedPreSelectedDevice) {
                    return loadedPreselectedDevice
                }
            }
            
            return nil
        }
        set {
            let encoder = JSONEncoder()
            if let val = newValue {
                if let encoded = try? encoder.encode(val) {
                    set(encoded, forKey: Key.bluetoothDevice.rawValue)
                }
            } else {
                set("", forKey: Key.bluetoothDevice.rawValue)
            }
        }
    }
   
   
    

    
}
