//
//  MiaoMiaoManager.swift
//  LibreMonitor
//
//  Created by Uwe Petersen on 10.03.18.
//  Copyright © 2018 Uwe Petersen. All rights reserved.
//
//  How does the MiaoMiao work?
//
//    0.) Advertising
//        MiaoMiao advertises with the following data:
//        - key : "kCBAdvDataIsConnectable"     - value : 1
//        - key : "kCBAdvDataManufacturerData"  - value : <0034cb1c 53093fb4> -> This might be usable as a unique device id.
//        - key : "kCBAdvDataLocalName"         - value : miaomiao
//
//    1.) Services
///       The MiaoMiao has two bluetooth services, one provided for the open source community and one that is probably to be used by the Tomato app.
//        a) UUID: 6E400001-B5A3-F393-E0A9-E50E24DCCA9E -> Open Source Community
//           Did discover service: <CBService: 0x1c4673a00, isPrimary = YES, UUID = 6E400001-B5A3-F393-E0A9-E50E24DCCA9E>
//        b) UUID: 00001532-1212-EFDE-1523-785FEABCD123
//           Did discover service: <CBService: 0x1c0a61880, isPrimary = YES, UUID = 00001530-1212-EFDE-1523-785FEABCD123>
//
//    2.) Characteristics for open source service with UUID 6E400001-B5A3-F393-E0A9-E50E24DCCA9E
//
//        The service contains two characheristics:
//
//          a) Notify_Characteristic
//             UUID: 6E400003-B5A3-F393-E0A9-E50E24DCCA9E
//             "<CBCharacteristic: 0x1c02ae7c0, UUID = 6E400003-B5A3-F393-E0A9-E50E24DCCA9E, properties = 0x10, value = (null), notifying = NO>"
//                 ... with properties:
//             __C.CBCharacteristicProperties(rawValue: 16)
//             Broadcast:                            [false]
//             Read:                                 [false]
//             WriteWithoutResponse:                 [false]
//             Write:                                [false]
//             Notify:                               [true]
//             Indicate:                             [false]
//             AuthenticatedSignedWrites:            [false]
//             ExtendedProperties:                   [false]
//             NotifyEncryptionRequired:             [false]
//             BroaIndicateEncryptionRequireddcast:  [false]
//             Service for Characteristic:           ["<CBService: 0x1c087f940, isPrimary = YES, UUID = 6E400001-B5A3-F393-E0A9-E50E24DCCA9E>"]
//
//          b) Write_Characteristic
//             UUID: 6E400002-B5A3-F393-E0A9-E50E24DCCA9E
//             "<CBCharacteristic: 0x1c02a81c0, UUID = 6E400002-B5A3-F393-E0A9-E50E24DCCA9E, properties = 0xC, value = (null), notifying = NO>"
//                 ... with properties:
//             __C.CBCharacteristicProperties(rawValue: 12)
//             Broadcast:                            [false]
//             Read:                                 [false]
//             WriteWithoutResponse:                 [true]
//             Write:                                [true]
//             Notify:                               [false]
//             Indicate:                             [false]
//             AuthenticatedSignedWrites:            [false]
//             ExtendedProperties:                   [false]
//             NotifyEncryptionRequired:             [false]
//             BroaIndicateEncryptionRequireddcast:  [false]
//             Service for Characteristic:           ["<CBService: 0x1c087f940, isPrimary = YES, UUID = 6E400001-B5A3-F393-E0A9-E50E24DCCA9E>"]
//
//      3.) Characteristics for (possibly) Tomato app services with UUID 00001532-1212-EFDE-1523-785FEABCD123
//
//          The service contains three characteristics
//
//          a) Read characteristic
//             "<CBCharacteristic: 0x1c42a8c40, UUID = 00001534-1212-EFDE-1523-785FEABCD123, properties = 0x2, value = (null), notifying = NO>"
//                 ... with properties:
//             __C.CBCharacteristicProperties(rawValue: 2)
//             Broadcast:                            [false]
//             Read:                                 [true]
//             WriteWithoutResponse:                 [false]
//             Write:                                [false]
//             Notify:                               [false]
//             Indicate:                             [false]
//             AuthenticatedSignedWrites:            [false]
//             ExtendedProperties:                   [false]
//             NotifyEncryptionRequired:             [false]
//             BroaIndicateEncryptionRequireddcast:  [false]
//             Service for Characteristic:           ["<CBService: 0x1c0a61880, isPrimary = YES, UUID = 00001530-1212-EFDE-1523-785FEABCD123>"]
//
//          b) Write without respons characteristic
//             Characteristic:
//             "<CBCharacteristic: 0x1c42a2220, UUID = 00001532-1212-EFDE-1523-785FEABCD123, properties = 0x4, value = (null), notifying = NO>"
//             ... with properties:
//             __C.CBCharacteristicProperties(rawValue: 4)
//             Broadcast:                            [false]
//             Read:                                 [false]
//             WriteWithoutResponse:                 [true]
//             Write:                                [false]
//             Notify:                               [false]
//             Indicate:                             [false]
//             AuthenticatedSignedWrites:            [false]
//             ExtendedProperties:                   [false]
//             NotifyEncryptionRequired:             [false]
//             BroaIndicateEncryptionRequireddcast:  [false]
//             Service for Characteristic:           ["<CBService: 0x1c0a61880, isPrimary = YES, UUID = 00001530-1212-EFDE-1523-785FEABCD123>"]
//
//          c) Write and notify characteristic
//             "<CBCharacteristic: 0x1c02a8220, UUID = 00001531-1212-EFDE-1523-785FEABCD123, properties = 0x18, value = (null), notifying = NO>"
//                 ... with properties:
//             __C.CBCharacteristicProperties(rawValue: 24)
//             Broadcast:                            [false]
//             Read:                                 [false]
//             WriteWithoutResponse:                 [false]
//             Write:                                [true]
//             Notify:                               [true]
//             Indicate:                             [false]
//             AuthenticatedSignedWrites:            [false]
//             ExtendedProperties:                   [false]
//             NotifyEncryptionRequired:             [false]
//             BroaIndicateEncryptionRequireddcast:  [false]
//             Service for Characteristic:           ["<CBService: 0x1c0a61880, isPrimary = YES, UUID = 00001530-1212-EFDE-1523-785FEABCD123>"]
//
//  The MiaoMiao protocol
//  1.) Data
//      TX: 0xF0
//          Request all the data or the sensor. The bluetooth will return the data at a certain frequency (default is every 5 minutes) after the request
//      RX:
//          a) Data (363 bytes):
//             Pos.  0 (0x00): 0x28 +
//             Pos.  1 (0x01): Len[2 bytes] +
//             Pos.  3 (0x03): Index [2 bytes] (this is the minute counter of the Freestyle Libre sensor) +
//             Pos.  5 (0x05): ID [8 bytes] +
//             Pos. 13 (0x0D): xbattery level in percent [1 byte] (e.g. 0x64 which is 100 in decimal means 100%?)
//             Pos. 14 (0x0E): firmware version [2 bytes] +
//             Pos. 16 (0x10): hardware version [2 bytes] +
//             Pos. 18 (0x12): FRAM data (43 x 8 bytes = 344 bytes) +
//             Pos. end      : 0x29
//             Example: 28  07b3  5457  db353e01 00a007e0  64  0034 0001  11b6e84f050003 875104 57540000 00 000000 00000000 0000b94b 060f1600 c0da6a80 1600c0d6 6a801600
//                      0x28   -> marks begin of data response
//                      0x07b3 -> len is 1971 bytes (= 1952 for FRAM and 19 bytes for all the rest from 0x28 to 0x29, both of which are included)
//                                but as of 2018-03-12 only 1791 bytes are sent.
//                      0x5457 -> index is 21591
//                      0xdb353e0100a007e0 -> id, can be converted to serial number
//                      0x64   -> battery level (= 100%)
//                      0x0034 -> firmware version
//                      0x0001 -> hardware version
//                      0x11b6e84f05000387 FRAM block 0x00 (sensor is expired since byte 0x04 has value 0x05)
//                      0x5104575400000000 FRAM block 0x01
//                      0x0000000000000000 FRAM block 0x02
//                      0xb94b060f1600c0da FRAM block 0x03
//                       ...
//            28 07b3 182b  9a8150 0100a007 e0640034 0001539d
//          b) A new sensor has been detected
//             0x32
//          c) No sensor has been detected
//             0x34
//
//  2.) Confirm to replace the sensor (if a new sensor is detected and shall be used, send this)
//      TX: 0xD301
//  3.) Confirm not to replace the sensor (if a new sensor is detected and shall not be used, send this)
//      TX: 0xD300
//  4.) Change the frequence of data transmission
//      TX: 0xD1XX, where XX is the intervall time, 1 byte, e.g. 0x0A is 10 minutes
//      RX:
//          a) 0xD101 Success
//          b) 0xD100 Fail

import Foundation
import UIKit
import CoreBluetooth
import os.log
import HealthKit

public enum BluetoothmanagerState: String {
    case Unassigned = "Unassigned"
    case Scanning = "Scanning"
    case Disconnected = "Disconnected"
    case DelayedReconnect = "Will soon reconnect"
    case DisconnectingDueToButtonPress = "Disconnecting due to button press"
    case Connecting = "Connecting"
    case Connected = "Connected"
    case Notifying = "Notifying"
    case powerOff = "powerOff"
}




public enum SupportedDevices : Int, CaseIterable{
    case MiaoMiao = 0
    case Bubble = 1
    
    public var name: String {
        switch self {
        case .Bubble:
            return "bubble"
        case .MiaoMiao:
            return "miaomiao"
        }
    }
    public static func isSupported(_ peripheral: CBPeripheral ) -> Bool{
        if let name = peripheral.name?.lowercased() {
            return allNames.contains(name)
        }
        return false
        
    }
    public static var allNames : [String] {
        get {
            return SupportedDevices.allCases.map( { $0.name})
        }
    }
}

extension Bundle {
    static var current: Bundle {
        class __ { }
        return Bundle(for: __.self)
    }
}

public struct CompatibleLibreBluetoothDevice : Hashable, Codable {
    public var identifier: String
    public var name: String
    
    public var bridgeType : SupportedDevices?  {
        get{
            
            switch self.name.lowercased() {
            case let x where x.starts(with: "miaomiao"):
                return SupportedDevices.MiaoMiao
            case let x where x.starts(with: "bubble"):
                return SupportedDevices.Bubble
            default:
                return nil
            }
        }
    }
    
    public init(identifier:String, from type: SupportedDevices){
        self.init(identifier:identifier, name: type.name)
    }
    
    public init(identifier:String, name: String) {
        self.identifier = identifier
        self.name = name
    }
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier.hashValue)
        hasher.combine(name.hashValue)
    }
    
    public static func == (lhs: CompatibleLibreBluetoothDevice, rhs: CompatibleLibreBluetoothDevice) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.name == rhs.name
    }
    
    public var smallImage : UIImage? {
        let bundle = Bundle.current
        print("dabear:: bridgetype is \(bridgeType)")
        
        guard let bridgeType = bridgeType else {
            
            return nil
        }
        switch bridgeType {
        case .Bubble:
            return UIImage(named: "bubble", in: bundle, compatibleWith: nil)
        case .MiaoMiao:
            return UIImage(named: "miaomiao-small", in: bundle, compatibleWith: nil)
        }
        
    }
    
}



protocol LibreBluetoothManagerDelegate {
    func libreBluetoothManagerPeripheralStateChanged(_ state: BluetoothmanagerState)
    func libreBluetoothManagerReceivedMessage(_ messageIdentifier:UInt16, txFlags:UInt8, payloadData:Data)
    func libreBluetoothManagerDidUpdate(sensorData: SensorData, and Device: BluetoothBridgeMetaData) -> Void
}

public extension CBPeripheral {
    func asCompatibleBluetoothDevice() -> CompatibleLibreBluetoothDevice? {
        if SupportedDevices.isSupported(self), let name=self.name {
            return CompatibleLibreBluetoothDevice(identifier: self.identifier.uuidString, name: name)
        }
        
        return nil
    }
}

final class LibreBluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Properties
    private var wantsToTerminate = false
    //private var lastConnectedIdentifier : String?
    
    static let bt_log = OSLog(subsystem: "com.LibreMonitor", category: "MiaoMiaoManager")
    var metadata: BluetoothBridgeMetaData?
   
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral?
    //    var slipBuffer = SLIPBuffer()
    var writeCharacteristic: CBCharacteristic?
    
    var rxBuffer = Data()
    var sensorData: SensorData?
    
    
    public var identifier : UUID? {
        get {
            return peripheral?.identifier
        }
        
    }
    
   
    public func peripheralAsCompatibleDevice() -> CompatibleLibreBluetoothDevice?{
        return peripheral?.asCompatibleBluetoothDevice()
    }
    
    
    private let managerQueue = DispatchQueue(label: "no.bjorninge.bluetoothManagerQueue", qos: .utility)
    
    
    fileprivate let serviceUUIDs:[CBUUID]? = [CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")]
    fileprivate let writeCharachteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    fileprivate let notifyCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    
    var BLEScanDuration = 3.0
    weak var timer: Timer?
    
    var delegate: LibreBluetoothManagerDelegate? {
        didSet {
            // Help delegate initialize by sending current state directly after delegate assignment
            delegate?.libreBluetoothManagerPeripheralStateChanged(state)
        }
    }
    
    private var state: BluetoothmanagerState = .Unassigned {
        didSet {
            // Help delegate initialize by sending current state directly after delegate assignment
            delegate?.libreBluetoothManagerPeripheralStateChanged(state)
        }
    }
    
    private func syncOnQueue<T>( _ closure :@escaping @autoclosure ()-> T) -> T{
        var ret : T? = nil
            
        managerQueue.sync { [closure] in
            ret = closure()
        }
        
        return ret!
    }
    
    public var connectionStateString: String? {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        
        return syncOnQueue( self.state.rawValue )
        
    }
    
    
    // MARK: - Methods
    
    override init() {
        super.init()
        
        //        slipBuffer.delegate = self
        os_log("miaomiaomanager init called ", log: LibreBluetoothManager.bt_log)
        managerQueue.sync {
            centralManager = CBCentralManager(delegate: self, queue: managerQueue, options: nil)
        }
    }
    
    func scanForDevices() {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        os_log("Scan for MiaoMiao while internal state %{public}@, bluetooth state %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: state), String(describing: centralManager.state ))
        
        guard centralManager.state == .poweredOn else {
            return
        }
        //        print(centralManager.debugDescription)
        if centralManager.state == .poweredOn {
            os_log("Before scan for MiaoMiao while central manager state %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: centralManager.state.rawValue))
            
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            
            state = .Scanning
            
            //            print(centralManager.debugDescription)
        }
        //        // Set timer to check connection and reconnect if necessary
        //        timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: false) {_ in
        //            os_log("********** Reconnection timer fired in background **********", log: MiaoMiaoManager.bt_log, type: .default)
        //            if self.state != .Notifying {
        //                self.scanForMiaoMiao()
        //                //                NotificationManager.scheduleDebugNotification(message: "Reconnection timer fired in background", wait: 0.5)
        //            }
        //        }
    }
    
    private func connect(force forceConnect: Bool = false) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Connect while state %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: state.rawValue))
        if centralManager.isScanning {
            centralManager.stopScan()
        }
        if state == .DisconnectingDueToButtonPress && !forceConnect {
            os_log("Connect aborted, user has actively disconnected and a reconnect was not forced ", log: LibreBluetoothManager.bt_log, type: .default)
            return
        }
        
        if let peripheral = peripheral {
            peripheral.delegate = self
            
            centralManager.connect(peripheral, options: nil)
            state = .Connecting
        }
    }
    
    func disconnectManually() {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        os_log("Disconnect manually while state %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: state.rawValue))
    
        managerQueue.sync {
            
            switch state {
            case .Connected, .Connecting, .Notifying, .Scanning:
                self.state = .DisconnectingDueToButtonPress  // to avoid reconnect in didDisconnetPeripheral
                
                self.wantsToTerminate = true
            default:
                break
            }
            
            if centralManager.isScanning {
                os_log("stopping scan", log: LibreBluetoothManager.bt_log, type: .default)
                centralManager.stopScan()
            }
            if let peripheral = peripheral {
                centralManager.cancelPeripheralConnection(peripheral)
            }
        }
       
    }
    
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Central Manager did update state to %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: central.state.rawValue))
        
        
        switch central.state {
        case .poweredOff:
            state = .powerOff
        case .resetting, .unauthorized, .unknown, .unsupported:
            os_log("Central Manager was either .poweredOff, .resetting, .unauthorized, .unknown, .unsupported: %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: central.state))
            state = .Unassigned
            if central.isScanning {
                central.stopScan()
            }
        case .poweredOn:
            if state == .DisconnectingDueToButtonPress {
                os_log("Central Manager was powered on but sensorstate was DisconnectingDueToButtonPress:  %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: central.state))
            } else {
                os_log("Central Manager was powered on, scanningformiaomiao: state: %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: state))
                scanForDevices() // power was switched on, while app is running -> reconnect.
            }
            
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
            
        os_log("Did discover peripheral while state %{public}@ with name: %{public}@, wantstoterminate?:  %d", log: LibreBluetoothManager.bt_log, type: .default, String(describing: state.rawValue), String(describing: peripheral.name), self.wantsToTerminate)
        
        /*
         if peripheral.name == deviceName {
         
         self.peripheral = peripheral
         connect()
         return
         }*/
        guard peripheral.name?.lowercased() != nil else {
            os_log("discovered peripheral had no name, returning: %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: peripheral.identifier.uuidString))
            return
        }
        
        if SupportedDevices.isSupported(peripheral){
            
            if let preselected = UserDefaults.standard.preSelectedDevice {
                if peripheral.identifier.uuidString == preselected.identifier {
                    os_log("Did connect to preselected %{public}@ with identifier %{public}@,", log: LibreBluetoothManager.bt_log, type: .default, String(describing: peripheral.name) ,String(describing: peripheral.identifier.uuidString))
                    self.peripheral = peripheral
                    
                    self.connect(force: true)
                    
                } else {
                    os_log("Did not connect to %{public}@ with identifier %{public}@, because another device with identifier %{public}@ was selected", log: LibreBluetoothManager.bt_log, type: .default, String(describing: peripheral.name), String(describing: peripheral.identifier.uuidString), preselected.identifier)
                    
                }
                
                return
            } else {
                NotificationHelper.sendNoBridgeSelectedNotification()
            }
            
        }
        
        
        
        
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
            
        os_log("Did connect peripheral while state %{public}@ with name: %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: state.rawValue), String(describing: peripheral.name))
        if central.isScanning {
            central.stopScan()
        }
        state = .Connected
        //self.lastConnectedIdentifier = peripheral.identifier.uuidString
        // Discover all Services. This might be helpful if writing is needed some time
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        os_log("Did fail to connect peripheral while state: %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: state.rawValue))
        if let error = error {
            os_log("Did fail to connect peripheral error: %{public}@", log: LibreBluetoothManager.bt_log, type: .error ,  "\(error.localizedDescription)")
        }
        state = .Disconnected
        
        self.delayedReconnect()
        
    }
    
    private func delayedReconnect(_ seconds: Double = 5) {
        state = .DelayedReconnect
        os_log("Will reconnect peripheral in  %{public}@ seconds", log: LibreBluetoothManager.bt_log, type: .default, String(describing: seconds))
        resetBuffer()
        // attempt to avoid IOS killing app because of cpu usage.
        // postpone connecting for x seconds
        DispatchQueue.global(qos: .utility).async { [weak self] in
            Thread.sleep(forTimeInterval: seconds)
            self?.managerQueue.sync {
                self?.connect()
            }
            
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        os_log("Did disconnect peripheral while state: %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: state.rawValue))
        if let error = error {
            os_log("Did disconnect peripheral error: %{public}@", log: LibreBluetoothManager.bt_log, type: .error ,  "\(error.localizedDescription)")
        }
        
        
        switch state {
        case .DisconnectingDueToButtonPress:
            state = .Disconnected
            self.wantsToTerminate = true
        
        default:
            state = .Disconnected
            self.delayedReconnect()
            //    scanForMiaoMiao()
        }
        // Keep this code in case you want it some later time: it is used for reconnection only in background mode
        //        state = .Disconnected
        //        // Start scanning, if disconnection occurred in background mode
        //        if UIApplication.sharedApplication().applicationState == .Background ||
        //            UIApplication.sharedApplication().applicationState == .Inactive {
        //            scanForMiaoMiao()
        //        }
    }
    
    
    // MARK: - CBPeripheralDelegate
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Did discover services", log: LibreBluetoothManager.bt_log, type: .default)
        if let error = error {
            os_log("Did discover services error: %{public}@", log: LibreBluetoothManager.bt_log, type: .error ,  "\(error.localizedDescription)")
        }
        
        
        if let services = peripheral.services {
            
            for service in services {
                peripheral.discoverCharacteristics([writeCharachteristicUUID, notifyCharacteristicUUID], for: service)
                
                os_log("Did discover service: %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: service.debugDescription))
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        os_log("Did discover characteristics for service %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: peripheral.name))
        
        if let error = error {
            os_log("Did discover characteristics for service error: %{public}@", log: LibreBluetoothManager.bt_log, type: .error ,  "\(error.localizedDescription)")
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                os_log("Did discover characteristic: %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: characteristic.debugDescription))
                //                print("Characteristic: ")
                //                debugPrint(characteristic.debugDescription)
                //                print("... with properties: ")
                //                debugPrint(characteristic.properties)
                //                print("Broadcast:                           ", [characteristic.properties.contains(.broadcast)])
                //                print("Read:                                ", [characteristic.properties.contains(.read)])
                //                print("WriteWithoutResponse:                ", [characteristic.properties.contains(.writeWithoutResponse)])
                //                print("Write:                               ", [characteristic.properties.contains(.write)])
                //                print("Notify:                              ", [characteristic.properties.contains(.notify)])
                //                print("Indicate:                            ", [characteristic.properties.contains(.indicate)])
                //                print("AuthenticatedSignedWrites:           ", [characteristic.properties.contains(.authenticatedSignedWrites )])
                //                print("ExtendedProperties:                  ", [characteristic.properties.contains(.extendedProperties)])
                //                print("NotifyEncryptionRequired:            ", [characteristic.properties.contains(.notifyEncryptionRequired)])
                //                print("BroaIndicateEncryptionRequireddcast: ", [characteristic.properties.contains(.indicateEncryptionRequired)])
                //                print("Serivce for Characteristic:          ", [characteristic.service.debugDescription])
                //
                //                if characteristic.service.uuid == CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E") {
                //                    print("\n B I N G O \n")
                //                }
                
                // Choose the notifiying characteristic and Register to be notified whenever the MiaoMiao transmits
                if (characteristic.properties.intersection(.notify)) == .notify && characteristic.uuid == notifyCharacteristicUUID {
                    peripheral.setNotifyValue(true, for: characteristic)
                    os_log("Set notify value for this characteristic", log: LibreBluetoothManager.bt_log, type: .default)
                }
                if (characteristic.uuid == writeCharachteristicUUID) {
                    writeCharacteristic = characteristic
                }
            }
        } else {
            os_log("Discovered characteristics, but no characteristics listed. There must be some error.", log: LibreBluetoothManager.bt_log, type: .default)
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Did update notification state for characteristic: %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: characteristic.debugDescription))
        
        if let error = error {
            os_log("Peripheral did update notification state for characteristic: %{public}@ with error", log: LibreBluetoothManager.bt_log, type: .error ,  "\(error.localizedDescription)")
        } else {
            resetBuffer()
            requestData()
        }
        state = .Notifying
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Did update value for characteristic: %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: characteristic.debugDescription))
        
        if let error = error {
            os_log("Characteristic update error: %{public}@", log: LibreBluetoothManager.bt_log, type: .error ,  "\(error.localizedDescription)")
        } else {
            if characteristic.uuid == CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"), let value = characteristic.value {
                
                guard let bridge = peripheral.asCompatibleBluetoothDevice()?.bridgeType else {
                    return
                }
                
                switch bridge {
                case .Bubble:
                    bubbleDidUpdateValueForNotifyCharacteristics(value, peripheral: peripheral)
                case .MiaoMiao:
                    miaomiaoDidUpdateValueForNotifyCharacteristics(value, peripheral: peripheral)
                }

                
                
            }
                
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Did Write value %{public}@ for characteristic %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(characteristic.value.debugDescription), String(characteristic.debugDescription))
    }
    
    // Miaomiao specific commands
    
    
    
    func requestData() {
        
        guard let peripheral = peripheral, let bridge = peripheral.asCompatibleBluetoothDevice()?.bridgeType else {
            return
        }
        
        if let writeCharacteristic = writeCharacteristic {
            switch bridge {
            case .Bubble:
                bubbleRequestData(writeCharacteristics: writeCharacteristic, peripheral: peripheral)
            case .MiaoMiao:
                miaomiaoRequestData(writeCharacteristics: writeCharacteristic, peripheral: peripheral)
            }

        }
    }
    
    
    func resetBuffer() {
        rxBuffer = Data()
    }
    
    func handleCompleteMessage() {

        guard let bridge = peripheral?.asCompatibleBluetoothDevice()?.bridgeType else {
            return
        }
        
        switch bridge {
        case .Bubble:
            bubbleHandleCompleteMessage()
        case .MiaoMiao:
            miaomiaoHandleCompleteMessage()
        }

    }
    
    deinit {
        self.delegate = nil
        os_log("dabear:: miaomiaomanager deinit called")
        
        
    }
    
}

extension LibreBluetoothManager {
    public var manufacturer : String {
        guard let bridgeType = self.peripheralAsCompatibleDevice()?.bridgeType else {
            return "n/a"
        }
        switch bridgeType {
        case .Bubble:
            return "Bubbledevteam"
        case .MiaoMiao:
            return "Tomato"
        default:
            return "n/a"
        }
    }
    
    var device: HKDevice? {
        
        return HKDevice(
            name: "MiaomiaoClient",
            manufacturer: manufacturer,
            model: nil, //latestSpikeCollector,
            hardwareVersion: self.metadata?.hardware ,
            firmwareVersion: self.metadata?.firmware,
            softwareVersion: nil,
            localIdentifier: identifier?.uuidString,
            udiDeviceIdentifier: nil
        )
    }
}


//these are extensions to return properties (for inspection on the main ui) that exist on the queue only
extension LibreBluetoothManager {
   
    
    var OnQueue_metadata : BluetoothBridgeMetaData? {
        return syncOnQueue( self.metadata)
    }
    
    var OnQueue_sensorData : SensorData? {
        return syncOnQueue( self.sensorData)
    }
    
    var OnQueue_state : BluetoothmanagerState {
        return syncOnQueue( self.state)
    }
    
    var OnQueue_identifer: UUID? {
        return syncOnQueue(self.identifier)
    }
    
    var OnQueue_manufacturer: String {
        return syncOnQueue(self.manufacturer)
    }
    
    var OnQueue_device: HKDevice? {
        return syncOnQueue(self.device)
    }
    
    
    
    
}
