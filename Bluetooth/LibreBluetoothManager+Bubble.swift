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

public enum BubbleResponseType: UInt8 {
    case dataPacket = 130
    case bubbleInfo = 128 // = wakeUp + device info
    case noSensor = 191
    case serialNumber = 192
}

//bubble support
extension LibreBluetoothManager {

    func bubbleHandleCompleteMessage() {
        print("dabear:: bubbleHandleCompleteMessage")

        guard rxBuffer.count >= 352 else {
            return
        }

        let data = rxBuffer.subdata(in: 8..<352)
        print("dabear:: bubbleHandleCompleteMessage raw data: \([UInt8](rxBuffer))")
        sensorData = SensorData(uuid: rxBuffer.subdata(in: 0..<8), bytes: [UInt8](data), date: Date())

        guard let metadata = metadata else {
            return
        }

        if let sensorData = sensorData {
            if !sensorData.hasValidCRCs {
                NotificationHelper.sendInvalidChecksumIfDeveloper(sensorData)
                //scheduling timer does not seem to work well in background mode any way
                /*Timer.scheduledTimer(withTimeInterval: 30, repeats: false, block: {[weak self]_ in
                    self?.requestData()
                })*/
            }

            dispatchToDelegate { (manager) in
                manager.delegate?.libreBluetoothManagerDidUpdate(sensorData: sensorData, and: metadata)
            }



        }

    }

    func bubbleRequestData(writeCharacteristics: CBCharacteristic, peripheral: CBPeripheral) {
        print("dabear:: bubbleRequestData")
        rxBuffer.resetAllBytes()
        //timer?.invalidate()
        print("-----set: ", writeCharacteristics)
        peripheral.writeValue(Data([0x00, 0x00, 0x05]), for: writeCharacteristics, type: .withResponse)

    }

    func bubbleDidUpdateValueForNotifyCharacteristics(_ value: Data, peripheral: CBPeripheral) {
        print("dabear:: bubbleDidUpdateValueForNotifyCharacteristics")
        if let firstByte = value.first, let bubbleResponseState = BubbleResponseType(rawValue: firstByte) {
            switch bubbleResponseState {
            case .bubbleInfo:
                let hardware = value[2].description + ".0"
                let firmware = value[1].description + ".0"
                let battery = Int(value[4])
                metadata = BluetoothBridgeMetaData(hardware: hardware,
                                    firmware: firmware,
                                    battery: battery)
                print("dabear:: Got bubbledevice: \(metadata)")
                if let writeCharacteristic = writeCharacteristic {
                    print("-----set: ", writeCharacteristic)
                    peripheral.writeValue(Data([0x02, 0x00, 0x00, 0x00, 0x00, 0x2B]), for: writeCharacteristic, type: .withResponse)
                }
            case .dataPacket:
                rxBuffer.append(value.suffix(from: 4))
                if rxBuffer.count >= 352 {
                    handleCompleteMessage()
                    rxBuffer.resetAllBytes()
                }
            case .noSensor:
                dispatchToDelegate { (manager) in
                    manager.delegate?.libreBluetoothManagerReceivedMessage(0x0000, txFlags: 0x34, payloadData: manager.rxBuffer)
                }

                rxBuffer.resetAllBytes()
            case .serialNumber:
                rxBuffer.append(value.subdata(in: 2..<10))
            }

        }
    }
}
