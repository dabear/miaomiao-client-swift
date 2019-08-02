//
//  LibreBluetoothManager+Miaomiao.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 01/08/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import os.log

public enum MiaoMiaoResponseState: UInt8 {
    case dataPacketReceived = 0x28
    case newSensor = 0x32
    case noSensor = 0x34
    case frequencyChangedResponse = 0xD1
}
extension MiaoMiaoResponseState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .dataPacketReceived:
            return "Data packet received"
        case .newSensor:
            return "New sensor detected"
        case .noSensor:
            return "No sensor found"
        case .frequencyChangedResponse:
            return "Reading intervall changed"
        }
    }
}

//miaomiao support
extension LibreBluetoothManager {
    func miaomiaoHandleCompleteMessage() {
        
        guard rxBuffer.count >= 363 else {
            return
        }
        
        metadata = BluetoothBridgeMetaData(hardware: String(describing: rxBuffer[16...17].hexEncodedString()),
                                           firmware: String(describing: rxBuffer[14...15].hexEncodedString()),
                                           battery: Int(rxBuffer[13]))
        
        
        sensorData = SensorData(uuid: Data(rxBuffer.subdata(in: 5..<13)), bytes: [UInt8](rxBuffer.subdata(in: 18..<362)), date: Date(), derivedAlgorithmParameterSet: nil)
        
        guard let metadata = metadata else {
            return
        }
        
        
        
        // Check if sensor data is valid and, if this is not the case, request data again after thirty second
        if let sensorData = sensorData {
            if !(sensorData.hasValidHeaderCRC && sensorData.hasValidBodyCRC && sensorData.hasValidFooterCRC) {
                Timer.scheduledTimer(withTimeInterval: 30, repeats: false, block: {_ in
                    self.requestData()
                })
            }
            
            // Inform delegate that new data is available
            delegate?.libreBluetoothManagerDidUpdate(sensorData: sensorData, and: metadata)
        }
    }
    
    func miaomiaoRequestData(writeCharacteristics: CBCharacteristic, peripheral: CBPeripheral) {
        miaomiaoConfirmSensor()
        resetBuffer()
        timer?.invalidate()
        peripheral.writeValue(Data.init(bytes: [0xF0]), for: writeCharacteristics, type: .withResponse)
    }
    
    func miaomiaoDidUpdateValueForNotifyCharacteristics(_ value: Data, peripheral: CBPeripheral) {
        
        rxBuffer.append(value)
        os_log("Appended value with length %{public}@, buffer length is: %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: value.count), String(describing: rxBuffer.count))
        
        if let firstByte = rxBuffer.first {
            
            if let miaoMiaoResponseState = MiaoMiaoResponseState(rawValue: firstByte) {
                switch miaoMiaoResponseState {
                case .dataPacketReceived: // 0x28: // data received, append to buffer and inform delegate if end reached
                    
                    // Set timer to check if data is still uncomplete after a certain time frame
                    // Any old buffer is invalidated and a new buffer created with every reception of data
                    timer?.invalidate()
                    timer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { _ in
                        os_log("********** MiaoMiaoManagertimer fired **********", log: LibreBluetoothManager.bt_log, type: .default)
                        if self.rxBuffer.count >= 364 {
                            // buffer large enough and can be used
                            os_log("Buffer incomplete but large enough, inform delegate.", log: LibreBluetoothManager.bt_log, type: .default)
                            self.delegate?.libreBluetoothManagerReceivedMessage(0x0000, txFlags: 0x29, payloadData: self.rxBuffer)
                            self.handleCompleteMessage()
                            
                            self.rxBuffer = Data()  // reset buffer, once completed and delegate is informed
                        } else {
                            // buffer not large enough and has to be reset
                            os_log("Buffer incomplete and not large enough, reset buffer and request new data, again", log: LibreBluetoothManager.bt_log, type: .default)
                            self.requestData()
                        }
                    }
                    
                    if rxBuffer.count >= 363 && rxBuffer.last! == 0x29 {
                        os_log("Buffer complete, inform delegate.", log: LibreBluetoothManager.bt_log, type: .default)
                        delegate?.libreBluetoothManagerReceivedMessage(0x0000, txFlags: 0x28, payloadData: rxBuffer)
                        handleCompleteMessage()
                        rxBuffer = Data()  // reset buffer, once completed and delegate is informed
                        timer?.invalidate()
                    } else {
                        // buffer not yet complete, inform delegate with txFlags 0x27 to display intermediate data
                        //dabear-edit: don't notify on incomplete readouts
                        //delegate?.miaoMiaoManagerReceivedMessage(0x0000, txFlags: 0x27, payloadData: rxBuffer)
                    }
                    
                    // if data is not complete after 10 seconds: use anyways, if long enough, do not use if not long enough and reset buffer in both cases.
                    
                case .newSensor: // 0x32: // A new sensor has been detected -> acknowledge to use sensor and reset buffer
                    delegate?.libreBluetoothManagerReceivedMessage(0x0000, txFlags: 0x32, payloadData: rxBuffer)
                    if let writeCharacteristic = writeCharacteristic {
                        peripheral.writeValue(Data.init(bytes: [0xD3, 0x01]), for: writeCharacteristic, type: .withResponse)
                    }
                    rxBuffer = Data()
                case .noSensor: // 0x34: // No sensor has been detected -> reset buffer (and wait for new data to arrive)
                    delegate?.libreBluetoothManagerReceivedMessage(0x0000, txFlags: 0x34, payloadData: rxBuffer)
                    rxBuffer = Data()
                case .frequencyChangedResponse: // 0xD1: // Success of fail for setting time intervall
                    delegate?.libreBluetoothManagerReceivedMessage(0x0000, txFlags: 0xD1, payloadData: rxBuffer)
                    if rxBuffer.count >= 2 {
                        if rxBuffer[2] == 0x01 {
                            os_log("Success setting time interval.", log: LibreBluetoothManager.bt_log, type: .default)
                        } else if rxBuffer[2] == 0x00 {
                            os_log("Failure setting time interval.", log: LibreBluetoothManager.bt_log, type: .default)
                        } else {
                            os_log("Unkown response for setting time interval.", log: LibreBluetoothManager.bt_log, type: .default)
                        }
                    }
                    rxBuffer = Data()
                    //                    default: // any other data (e.g. partial response ...)
                    //                        delegate?.miaoMiaoManagerReceivedMessage(0x0000, txFlags: 0x99, payloadData: rxBuffer)
                    //                        rxBuffer = Data() // reset buffer, since no valid response
                }
            }
        } else {
            // any other data (e.g. partial response ...)
            delegate?.libreBluetoothManagerReceivedMessage(0x0000, txFlags: 0x99, payloadData: rxBuffer)
            rxBuffer = Data() // reset buffer, since no valid response
        }
    
    }
    
    // Confirm (to replace) the sensor. Iif a new sensor is detected and shall be used, send this command (0xD301)
    func miaomiaoConfirmSensor() {
        if let writeCharacteristic = writeCharacteristic {
            peripheral?.writeValue(Data.init(bytes: [0xD3, 0x00]), for: writeCharacteristic, type: .withResponse)
        }
    }

}
