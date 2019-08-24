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
            if !sensorData.hasValidCRCs {
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
        
        peripheral.writeValue(Data.init(bytes: [0xF0]), for: writeCharacteristics, type: .withResponse)
    }
    
    private func tryCreateResponseState(_ rawValue: UInt8?) ->  MiaoMiaoResponseState?{
        guard let rawValue = rawValue else {
            return nil
        }
        return MiaoMiaoResponseState(rawValue: rawValue)
    }
    
    func miaomiaoDidUpdateValueForNotifyCharacteristics(_ value: Data, peripheral: CBPeripheral) {
        
       
        
        os_log("rxBuffer.first is: %{public}@, value.first is: %{public}@, responsestate is: %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: rxBuffer.first), String(describing: value.first), String(describing: tryCreateResponseState(rxBuffer.first ?? value.first)))
        
        // When spreading a message over multiple telegrams, the miaomiao protocol
        // does not repeat that initial byte
        // firstbyte is therefore written to rxbuffer on first received telegram
        // this becomes sort of a state to track which message is actually received.
        // Therefore it also becomes important that once a message is fully received, the buffer is invalidated
        //
        guard let firstByte = (rxBuffer.first ?? value.first), let miaoMiaoResponseState = MiaoMiaoResponseState(rawValue: firstByte) else {
            print("miaomiaoDidUpdateValueForNotifyCharacteristics did not undestand what to do (internal error")
            return
        }
        
        switch miaoMiaoResponseState {
        case .dataPacketReceived: // 0x28: // data received, append to buffer and inform delegate if end reached
            
            rxBuffer.append(value)
            os_log("Appended value with length %{public}@, buffer length is: %{public}@", log: LibreBluetoothManager.bt_log, type: .default, String(describing: value.count), String(describing: rxBuffer.count))
            
            if rxBuffer.count >= 363, let last = rxBuffer.last, last == 0x29 {
                os_log("Buffer complete, inform delegate.", log: LibreBluetoothManager.bt_log, type: .default)
                delegate?.libreBluetoothManagerReceivedMessage(0x0000, txFlags: 0x28, payloadData: rxBuffer)
                handleCompleteMessage()
                resetBuffer()
            }
            
        case .newSensor: // 0x32: // A new sensor has been detected -> acknowledge to use sensor and reset buffer
            delegate?.libreBluetoothManagerReceivedMessage(0x0000, txFlags: 0x32, payloadData: rxBuffer)
            miaomiaoConfirmSensor()
            resetBuffer()
        case .noSensor: // 0x34: // No sensor has been detected -> reset buffer (and wait for new data to arrive)
            delegate?.libreBluetoothManagerReceivedMessage(0x0000, txFlags: 0x34, payloadData: rxBuffer)
            resetBuffer()
        case .frequencyChangedResponse: // 0xD1: // Success of fail for setting time intervall
            delegate?.libreBluetoothManagerReceivedMessage(0x0000, txFlags: 0xD1, payloadData: rxBuffer)
            if value.count >= 2 {
                if value[2] == 0x01 {
                    os_log("Success setting time interval.", log: LibreBluetoothManager.bt_log, type: .default)
                } else if value[2] == 0x00 {
                    os_log("Failure setting time interval.", log: LibreBluetoothManager.bt_log, type: .default)
                } else {
                    os_log("Unkown response for setting time interval.", log: LibreBluetoothManager.bt_log, type: .default)
                }
            }
            resetBuffer()
        }
        
        
    
    }
    
    // Confirm (to replace) the sensor. Iif a new sensor is detected and shall be used, send this command (0xD301)
    func miaomiaoConfirmSensor() {
        if let writeCharacteristic = writeCharacteristic {
            peripheral?.writeValue(Data.init(bytes: [0xD3, 0x00]), for: writeCharacteristic, type: .withResponse)
        }
    }

}
