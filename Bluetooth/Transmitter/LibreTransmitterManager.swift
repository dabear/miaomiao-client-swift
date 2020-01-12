//
//  MiaoMiaoManager.swift
//  LibreMonitor
//
//  Created by Uwe Petersen on 10.03.18, heravily modified by Bjørn Berg.
//  Copyright © 2018 Uwe Petersen. All rights reserved.
//

import CoreBluetooth
import Foundation
import HealthKit
import os.log
import UIKit

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




public protocol LibreTransmitterDelegate: class {
    // Can happen on any queue
    func libreTransmitterStateChanged(_ state: BluetoothmanagerState)
    func libreTransmitterReceivedMessage(_ messageIdentifier: UInt16, txFlags: UInt8, payloadData: Data)
    // Will always happen on managerQueue
    func libreTransmitterDidUpdate(with sensorData: SensorData, and Device: LibreTransmitterMetadata)
}


final class LibreTransmitterManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, LibreTransmitterDelegate {
    func libreTransmitterStateChanged(_ state: BluetoothmanagerState) {

        dispatchToDelegate { manager in
            manager.libreTransmitterStateChanged(state)
        }
    }

    func libreTransmitterReceivedMessage(_ messageIdentifier: UInt16, txFlags: UInt8, payloadData: Data) {

        dispatchToDelegate { manager in
            manager.libreTransmitterReceivedMessage(messageIdentifier, txFlags: txFlags, payloadData: payloadData)
        }
    }

    func libreTransmitterDidUpdate(with sensorData: SensorData, and Device: LibreTransmitterMetadata) {
        self.metadata = Device
        self.sensorData = sensorData

        dispatchToDelegate { manager in
            manager.libreTransmitterDidUpdate(with: sensorData, and: Device)
        }
    }

    // MARK: - Properties
    private var wantsToTerminate = false
    //private var lastConnectedIdentifier : String?


    var activePlugin: LibreTransmitter? {
        didSet {
            print("dabear:: activePlugin changed from \(oldValue) to \(activePlugin)")
        }
    }

    var activePluginType: LibreTransmitter.Type? {
        if let activePlugin =  activePlugin {
            return type(of: activePlugin)
        }
        return nil
    }

    var shortTransmitterName: String? {
        activePluginType?.shortTransmitterName
    }

    static let bt_log = OSLog(subsystem: "com.LibreMonitor", category: "MiaoMiaoManager")
    var metadata: LibreTransmitterMetadata?

    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral?
    //    var slipBuffer = SLIPBuffer()
    var writeCharacteristic: CBCharacteristic?

    var sensorData: SensorData?

    public var identifier: UUID? {
        return peripheral?.identifier
    }

   



    private let managerQueue = DispatchQueue(label: "no.bjorninge.bluetoothManagerQueue", qos: .utility)
    private let delegateQueue = DispatchQueue(label: "no.bjorninge.delegateQueue", qos: .utility)

    /*
    fileprivate let serviceUUIDs: [CBUUID]? = [CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")]
    fileprivate let writeCharachteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    fileprivate let notifyCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")*/

    fileprivate var serviceUUIDs: [CBUUID]? {
        activePluginType?.serviceUUID.map { $0.value }
    }
    fileprivate var writeCharachteristicUUID : CBUUID? {
        activePluginType?.writeCharachteristic?.value
    }
    fileprivate var notifyCharacteristicUUID : CBUUID? {
        activePluginType?.notifyCharachteristic?.value
    }

    var BLEScanDuration = 3.0
    weak var timer: Timer?

    var delegate: LibreTransmitterDelegate? {
        didSet {
           dispatchToDelegate { manager in

                // Help delegate initialize by sending current state directly after delegate assignment
                self.delegate?.libreTransmitterStateChanged(self.state)
            }
        }
    }

    private var state: BluetoothmanagerState = .Unassigned {
        didSet {
            dispatchToDelegate { manager in
                // Help delegate initialize by sending current state directly after delegate assignment
                manager.libreTransmitterStateChanged(self.state)
            }


        }
    }

    public func dispatchToDelegate( _ closure :@escaping  (_ aself: LibreTransmitterManager) -> Void ) {
        delegateQueue.async { [weak self] in
            if let self = self {
                closure(self)
            }
        }
    }

    private func syncOnManagerQueue<T>( _ closure :@escaping  (_ aself: LibreTransmitterManager?) -> T?) -> T? {
        var ret: T?

        managerQueue.sync { [weak self, closure] in
            ret = closure(self)
        }

        return ret
    }

    public var connectionStateString: String? {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))

        return syncOnManagerQueue({ manager  in
            return manager?.state.rawValue
        })

        //self.state.rawValue )

    }

    // MARK: - Methods

    override init() {
        super.init()

        //        slipBuffer.delegate = self
        os_log("miaomiaomanager init called ", log: Self.bt_log)
        managerQueue.sync {
            centralManager = CBCentralManager(delegate: self, queue: managerQueue, options: nil)
        }
    }

    func scanForDevices() {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        os_log("Scan for MiaoMiao while internal state %{public}@, bluetooth state %{public}@", log: Self.bt_log, type: .default, String(describing: state), String(describing: centralManager.state ))

        guard centralManager.state == .poweredOn else {
            return
        }
        os_log("Before scan for MiaoMiao while central manager state %{public}@", log: Self.bt_log, type: .default, String(describing: centralManager.state.rawValue))

        centralManager.scanForPeripherals(withServices: nil, options: nil)
        state = .Scanning

    }

    private func connect(force forceConnect: Bool = false, advertisementData: [String: Any]?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Connect while state %{public}@", log: Self.bt_log, type: .default, String(describing: state.rawValue))
        if centralManager.isScanning {
            centralManager.stopScan()
        }
        if state == .DisconnectingDueToButtonPress && !forceConnect {
            os_log("Connect aborted, user has actively disconnected and a reconnect was not forced ", log: Self.bt_log, type: .default)
            return
        }

        if let peripheral = peripheral {
            peripheral.delegate = self

            var needsNewPluginInstance = false

            if let activePlugin = self.activePlugin {
                if activePlugin.canSupportPeripheral(peripheral) {
                    //when reaching this part,
                    //we are sure the peripheral is reconnecting and therefore needs reset
                    activePlugin.reset()
                } else {
                    needsNewPluginInstance.toggle()
                }
            } else {
                needsNewPluginInstance.toggle()
            }
            if needsNewPluginInstance,
                let plugin = LibreTransmitters.getSupportedPlugins(peripheral)?.first {
                self.activePlugin = plugin.init(delegate: self,advertisementData: advertisementData)
                
            }
            centralManager.connect(peripheral, options: nil)
            state = .Connecting
        }
    }

    func disconnectManually() {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        os_log("Disconnect manually while state %{public}@", log: Self.bt_log, type: .default, String(describing: state.rawValue))

        managerQueue.sync {
            switch state {
            case .Connected, .Connecting, .Notifying, .Scanning:
                self.state = .DisconnectingDueToButtonPress  // to avoid reconnect in didDisconnetPeripheral

                self.wantsToTerminate = true
            default:
                break
            }

            if centralManager.isScanning {
                os_log("stopping scan", log: Self.bt_log, type: .default)
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
        os_log("Central Manager did update state to %{public}@", log: Self.bt_log, type: .default, String(describing: central.state.rawValue))

        switch central.state {
        case .poweredOff:
            state = .powerOff
        case .resetting, .unauthorized, .unknown, .unsupported:
            os_log("Central Manager was either .poweredOff, .resetting, .unauthorized, .unknown, .unsupported: %{public}@", log: Self.bt_log, type: .default, String(describing: central.state))
            state = .Unassigned
            if central.isScanning {
                central.stopScan()
            }
        case .poweredOn:
            if state == .DisconnectingDueToButtonPress {
                os_log("Central Manager was powered on but sensorstate was DisconnectingDueToButtonPress:  %{public}@", log: Self.bt_log, type: .default, String(describing: central.state))
            } else {
                os_log("Central Manager was powered on, scanningformiaomiao: state: %{public}@", log: Self.bt_log, type: .default, String(describing: state))
                scanForDevices() // power was switched on, while app is running -> reconnect.
            }
        @unknown default:
            fatalError("libre bluetooth state unhandled")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        os_log("Did discover peripheral while state %{public}@ with name: %{public}@, wantstoterminate?:  %d", log: Self.bt_log, type: .default, String(describing: state.rawValue), String(describing: peripheral.name), self.wantsToTerminate)

        /*
         if peripheral.name == deviceName {
         
         self.peripheral = peripheral
         connect()
         return
         }*/
        guard peripheral.name?.lowercased() != nil else {
            os_log("discovered peripheral had no name, returning: %{public}@", log: Self.bt_log, type: .default, String(describing: peripheral.identifier.uuidString))
            return
        }

        if let preselected = UserDefaults.standard.preSelectedDevice {
            if peripheral.identifier.uuidString == preselected {
                os_log("Did connect to preselected %{public}@ with identifier %{public}@,", log: Self.bt_log, type: .default, String(describing: peripheral.name), String(describing: peripheral.identifier.uuidString))
                self.peripheral = peripheral

                self.connect(force: true, advertisementData: nil)
            } else {
                os_log("Did not connect to %{public}@ with identifier %{public}@, because another device with identifier %{public}@ was selected", log: Self.bt_log, type: .default, String(describing: peripheral.name), String(describing: peripheral.identifier.uuidString), preselected)
            }

            return
        } else {
            NotificationHelper.sendNoBridgeSelectedNotification()
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        os_log("Did connect peripheral while state %{public}@ with name: %{public}@", log: Self.bt_log, type: .default, String(describing: state.rawValue), String(describing: peripheral.name))
        if central.isScanning {
            central.stopScan()
        }
        state = .Connected
        //self.lastConnectedIdentifier = peripheral.identifier.uuidString
        // Discover all Services. This might be helpful if writing is needed some time
        peripheral.discoverServices(serviceUUIDs)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        os_log("Did fail to connect peripheral while state: %{public}@", log: Self.bt_log, type: .default, String(describing: state.rawValue))
        if let error = error {
            os_log("Did fail to connect peripheral error: %{public}@", log: Self.bt_log, type: .error, "\(error.localizedDescription)")
        }
        state = .Disconnected

        self.delayedReconnect()
    }

    private func delayedReconnect(_ seconds: Double = 7) {
        state = .DelayedReconnect

        os_log("Will reconnect peripheral in  %{public}@ seconds", log: Self.bt_log, type: .default, String(describing: seconds))
        activePlugin?.reset()
        // attempt to avoid IOS killing app because of cpu usage.
        // postpone connecting for x seconds
        DispatchQueue.global(qos: .utility).async { [weak self] in
            Thread.sleep(forTimeInterval: seconds)
            self?.managerQueue.sync {
                self?.connect(advertisementData: nil)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        os_log("Did disconnect peripheral while state: %{public}@", log: Self.bt_log, type: .default, String(describing: state.rawValue))
        if let error = error {
            os_log("Did disconnect peripheral error: %{public}@", log: Self.bt_log, type: .error, "\(error.localizedDescription)")
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
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Did discover services", log: Self.bt_log, type: .default)
        if let error = error {
            os_log("Did discover services error: %{public}@", log: Self.bt_log, type: .error, "\(error.localizedDescription)")
        }

        if let services = peripheral.services {
            for service in services {

                let toDiscover = [writeCharachteristicUUID, notifyCharacteristicUUID].compactMap{ $0 }

                os_log("Will discover : %{public}@ Characteristics for service", log: Self.bt_log, type: .default, String(describing:toDiscover.count), String(describing: service.debugDescription))

                if !toDiscover.isEmpty {
                    peripheral.discoverCharacteristics(toDiscover, for: service)

                    os_log("Did discover service: %{public}@", log: Self.bt_log, type: .default, String(describing: service.debugDescription))
                }

            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        os_log("Did discover characteristics for service %{public}@", log: Self.bt_log, type: .default, String(describing: peripheral.name))

        if let error = error {
            os_log("Did discover characteristics for service error: %{public}@", log: Self.bt_log, type: .error, "\(error.localizedDescription)")
        }

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                os_log("Did discover characteristic: %{public}@", log: Self.bt_log, type: .default, String(describing: characteristic.debugDescription))
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
                if characteristic.properties.intersection(.notify) == .notify && characteristic.uuid == notifyCharacteristicUUID {
                    peripheral.setNotifyValue(true, for: characteristic)
                    os_log("Set notify value for this characteristic", log: Self.bt_log, type: .default)
                }
                if characteristic.uuid == writeCharachteristicUUID {
                    writeCharacteristic = characteristic
                }
            }
        } else {
            os_log("Discovered characteristics, but no characteristics listed. There must be some error.", log: Self.bt_log, type: .default)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Did update notification state for characteristic: %{public}@", log: Self.bt_log, type: .default, String(describing: characteristic.debugDescription))

        if let error = error {
            os_log("Peripheral did update notification state for characteristic: %{public}@ with error", log: Self.bt_log, type: .error, "\(error.localizedDescription)")
        } else {
            activePlugin?.reset()
            requestData()
        }
        state = .Notifying
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Did update value for characteristic: %{public}@", log: Self.bt_log, type: .default, String(describing: characteristic.debugDescription))

        if let error = error {
            os_log("Characteristic update error: %{public}@", log: Self.bt_log, type: .error, "\(error.localizedDescription)")
        } else {
            if characteristic.uuid == notifyCharacteristicUUID, let value = characteristic.value {

                self.activePlugin?.updateValueForNotifyCharacteristics(value, peripheral: peripheral, writeCharacteristic: writeCharacteristic)


            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Did Write value %{public}@ for characteristic %{public}@", log: Self.bt_log, type: .default, String(characteristic.value.debugDescription), String(characteristic.debugDescription))
    }

    // Miaomiao specific commands

    func requestData() {

        if let peripheral = peripheral,
            let writeCharacteristic = writeCharacteristic {
            self.activePlugin?.requestData(writeCharacteristics: writeCharacteristic, peripheral: peripheral)

        }
    }


    deinit {
        self.activePlugin = nil
        self.delegate = nil
        os_log("dabear:: miaomiaomanager deinit called")
    }


}




extension LibreTransmitterManager {
    public var manufacturer: String {
        activePluginType?.manufacturerer ?? "n/a"
    }

    var device: HKDevice? {
        HKDevice(
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
extension LibreTransmitterManager {
    var OnQueue_peripheral: CBPeripheral? {
        syncOnManagerQueue { manager  in
            manager?.peripheral

        }

    }

    var OnQueue_shortTransmitterName: String? {
        syncOnManagerQueue { manager  in
            manager?.shortTransmitterName
        }

    }

    var OnQueue_metadata: LibreTransmitterMetadata? {
        syncOnManagerQueue { manager  in
            manager?.metadata
        }
    }

    var OnQueue_sensorData: SensorData? {
        syncOnManagerQueue { manager  in
             manager?.sensorData
        }
    }

    var OnQueue_state: BluetoothmanagerState? {
        syncOnManagerQueue { manager  in
             manager?.state
        }
    }

    var OnQueue_identifer: UUID? {
        syncOnManagerQueue { manager  in
            manager?.identifier
        }
    }

    var OnQueue_manufacturer: String? {
        syncOnManagerQueue { manager  in
            manager?.manufacturer
        }
    }

    var OnQueue_device: HKDevice? {
        syncOnManagerQueue { manager  in
            manager?.device
        }
    }
}
