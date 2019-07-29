//
//  MiaoMiaoBluetoothManager+Bubblesupport.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 29/07/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import os.log

//bubble support
extension MiaoMiaoBluetoothManager {
    
    func bubbleHandleCompleteMessage() {
        print("dabear:: bubbleHandleCompleteMessage")
        
        guard rxBuffer.count >= 352 else {
            return
        }
        
        
        let data = rxBuffer.subdata(in: 8..<352)
        print("dabear:: bubbleHandleCompleteMessage raw data: \([UInt8](rxBuffer))")
        sensorData = SensorData(uuid: rxBuffer.subdata(in: 0..<8), bytes: [UInt8](data), date: Date(), derivedAlgorithmParameterSet: nil)
        
        guard let miaoMiao = miaoMiao else {
            return
        }
        
        if let sensorData = sensorData {
            if !(sensorData.hasValidHeaderCRC && sensorData.hasValidBodyCRC && sensorData.hasValidFooterCRC) {
                Timer.scheduledTimer(withTimeInterval: 30, repeats: false, block: {_ in
                    self.requestData()
                })
            }
            // Inform delegate that new data is available
            
            delegate?.miaoMiaoBluetoothManagerDidUpdateSensorAndMiaoMiao(sensorData: sensorData, miaoMiao: miaoMiao)
        }
        
    }
    
    func bubbleRequestData(writeCharacteristics: CBCharacteristic, peripheral: CBPeripheral) {
        print("dabear:: bubbleRequestData")
        resetBuffer()
        timer?.invalidate()
        print("-----set: ", writeCharacteristic)
        peripheral.writeValue(Data([0x00, 0x00, 0x05]), for: writeCharacteristics, type: .withResponse)
        
    }
    
    
    func bubbleDidUpdateValueForNotifyCharacteristics(_ value: Data, peripheral: CBPeripheral) {
        print("dabear:: bubbleDidUpdateValueForNotifyCharacteristics")
        if let firstByte = value.first {
            if firstByte == 128 {
                let hardware = value[2].description + ".0"
                let firmware = value[1].description + ".0"
                let battery = Int(value[4])
                miaoMiao = MiaoMiao(hardware: hardware,
                                    firmware: firmware,
                                    battery: battery)
                print("dabear:: Got bubbledevice: \(miaoMiao)")
                if let writeCharacteristic = writeCharacteristic {
                    print("-----set: ", writeCharacteristic)
                    peripheral.writeValue(Data([0x02, 0x00, 0x00, 0x00, 0x00, 0x2B]), for: writeCharacteristic, type: .withResponse)
                }
            }
            if firstByte == 191 {
                delegate?.miaoMiaoBluetoothManagerReceivedMessage(0x0000, txFlags: 0x34, payloadData: rxBuffer)
                resetBuffer()
            }
            
            if firstByte == 192 {
                rxBuffer.append(value.subdata(in: 2..<10))
            }
            
            if firstByte == 130 {
                rxBuffer.append(value.suffix(from: 4))
            }
            if rxBuffer.count >= 352 {
                handleCompleteMessage()
                print("++++++++++first: ", rxBuffer.count)
                resetBuffer()
            }
        }
        return
    }
}
