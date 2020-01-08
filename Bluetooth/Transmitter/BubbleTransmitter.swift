//
//  BubbleTransmitter.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 08/01/2020.
//  Copyright © 2020 Mark Wilson. All rights reserved.
//

import Foundation
import CoreBluetooth

// The Bubble uses the same serviceUUID,
// writeCharachteristic and notifyCharachteristic
// as the MiaoMiao, but different byte sequences
class BubbleTransmitter: MiaoMiaoTransmitter{
    override static func canSupportPeripheral(_ peripheral:CBPeripheral)->Bool{
        peripheral.name?.lowercased().starts(with: "bubble") ?? false
    }

    override func requestData(writeCharacteristics: CBCharacteristic, peripheral: CBPeripheral) {}
    override func updateValueForNotifyCharacteristics(_ value: Data, peripheral: CBPeripheral) {}

}
