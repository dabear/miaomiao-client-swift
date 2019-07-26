//
//  BluetoothSearch.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 26/07/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation


//
import Foundation
import UIKit
import CoreBluetooth
import os.log



struct CompatibleBluetoothDevice : Hashable {
    var identifer: String
    var name: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifer.hashValue)
    }
    
    static func == (lhs: CompatibleBluetoothDevice, rhs: CompatibleBluetoothDevice) -> Bool {
        return lhs.identifer == rhs.identifer
    }
    
}





protocol BluetoothSearchDelegate: class {
    func didDiscoverCompatibleDevice(_ device: CompatibleBluetoothDevice, allCompatibleDevices: [CompatibleBluetoothDevice])
}

final class BluetoothSearchManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("did update state for central")
        if central.state == .poweredOn {
            scanForMiaoMiao()
        }
    }
    
    
  
    
    static let bt_log = OSLog(subsystem: "com.LibreMonitor", category: "BluetoothSearchManager")
    
    
    var centralManager: CBCentralManager!
   
   
    
    fileprivate let deviceNames = ["miaomiao"]
    //fileprivate let serviceUUIDs:[CBUUID]? = [CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")]
    
    
    private var discoveredDevices = [CompatibleBluetoothDevice]()
    
    public func addDiscoveredDevice(_ device: CompatibleBluetoothDevice) {
        discoveredDevices.append(device)
        discoverDelegate.didDiscoverCompatibleDevice(device, allCompatibleDevices: discoveredDevices)
        
    }
    
    
    
    
    // MARK: - Methods
    weak var discoverDelegate: BluetoothSearchDelegate!
    init(discoverDelegate: BluetoothSearchDelegate) {
        self.discoverDelegate = discoverDelegate
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        //        slipBuffer.delegate = self
        os_log("miaomiaomanager init called ", log: BluetoothSearchManager.bt_log)
        
    }
    
    func scanForMiaoMiao() {
        
        //        print(centralManager.debugDescription)
        if centralManager.state == .poweredOn {
            os_log("Before scan for MiaoMiao while central manager state %{public}@", log: BluetoothSearchManager.bt_log, type: .default, String(describing: centralManager.state.rawValue))
            
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            
          
    }
    
    
    func disconnectManually() {
       print("did disconnect manually")
        //        NotificationManager.scheduleDebugNotification(message: "Timer fired in Background", wait: 3)
        //        _ = Timer(timeInterval: 150, repeats: false, block: {timer in NotificationManager.scheduleDebugNotification(message: "Timer fired in Background", wait: 0.5)})
        centralManager.stopScan()
    
      
    }
    
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        os_log("Central Manager did update state to %{public}@", log: BluetoothSearchManager.bt_log, type: .default, String(describing: central.state.rawValue))
        
        
        switch central.state {
        case .poweredOff, .resetting, .unauthorized, .unknown, .unsupported:
            os_log("Central Manager was either .poweredOff, .resetting, .unauthorized, .unknown, .unsupported: %{public}@", log: BluetoothSearchManager.bt_log, type: .default, String(describing: central.state))
        case .poweredOn:
                //os_log("Central Manager was powered on, scanningformiaomiao: state: %{public}@", log: MiaoMiaoBluetoothManager.bt_log, type: .default, String(describing: state))
            
                scanForMiaoMiao() // power was switched on, while app is running -> reconnect.
            }
            
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else {
            print("could not find name for device \(peripheral.identifier.uuidString)")
            return
        }
        let device = CompatibleBluetoothDevice(identifer: peripheral.identifier.uuidString, name: name)
        
        if deviceNames.contains(name) {
    
            
            print("did recognize device: \(name): \(peripheral.identifier)")
            self.addDiscoveredDevice(device)
            
            
        } else {
            print("did not add unknown device: \(String(describing: peripheral.name)): \(peripheral.identifier)")
            
            // TODO: for testing, remove after testing complete
            self.addDiscoveredDevice(device)
        }
        
        
        
       
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
       
        //self.lastConnectedIdentifier = peripheral.identifier.uuidString
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        print("did fail to connect")
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        
       print("did didDisconnectPeripheral")
    }
    
    
    // MARK: - CBPeripheralDelegate
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        os_log("Did discover services", log: BluetoothSearchManager.bt_log, type: .default)
        if let error = error {
            os_log("Did discover services error: %{public}@", log: BluetoothSearchManager.bt_log, type: .error ,  "\(error.localizedDescription)")
        }
        
        
        if let services = peripheral.services {
            
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
                
                os_log("Did discover service: %{public}@", log: BluetoothSearchManager.bt_log, type: .default, String(describing: service.debugDescription))
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        os_log("Did discover characteristics for service %{public}@", log: BluetoothSearchManager.bt_log, type: .default, String(describing: peripheral.name))
        
        if let error = error {
            os_log("Did discover characteristics for service error: %{public}@", log: BluetoothSearchManager.bt_log, type: .error ,  "\(error.localizedDescription)")
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                os_log("Did discover characteristic: %{public}@", log: BluetoothSearchManager.bt_log, type: .default, String(describing: characteristic.debugDescription))
             
              
                if (characteristic.properties.intersection(.notify)) == .notify && characteristic.uuid == CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") {
                    peripheral.setNotifyValue(true, for: characteristic)
                    os_log("Set notify value for this characteristic", log: BluetoothSearchManager.bt_log, type: .default)
                }
                if (characteristic.uuid == CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")) {
                    //writeCharacteristic = characteristic
                }
            }
        } else {
            os_log("Discovered characteristics, but no characteristics listed. There must be some error.", log: BluetoothSearchManager.bt_log, type: .default)
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        os_log("Did update notification state for characteristic: %{public}@", log: BluetoothSearchManager.bt_log, type: .default, String(describing: characteristic.debugDescription))
        
        
       
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        os_log("Did update value for characteristic: %{public}@", log: BluetoothSearchManager.bt_log, type: .default, String(describing: characteristic.debugDescription))
        
       
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        os_log("Did Write value %{public}@ for characteristic %{public}@", log: BluetoothSearchManager.bt_log, type: .default, String(characteristic.value.debugDescription), String(characteristic.debugDescription))
    }
    
    // Miaomiao specific commands
    
    
    
    
    
    deinit {
        
        os_log("dabear:: miaomiaomanager deinit called")
        
        
    }
    
}
