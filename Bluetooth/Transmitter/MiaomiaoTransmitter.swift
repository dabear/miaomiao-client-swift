//
//  MiaomiaoTransmitter.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 08/01/2020.
//  Copyright © 2020 Mark Wilson. All rights reserved.
//

import Foundation
import CoreBluetooth

class MiaoMiaoTransmitter: LibreTransmitter{
    static var writeCharachteristic: UUIDContainer? = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"

    static var notifyCharachteristic: UUIDContainer? = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
    static var serviceUUID: [UUIDContainer] = ["6E400001-B5A3-F393-E0A9-E50E24DCCA9E"]

    weak var delegate: LibreTransmitterDelegate?




    class func canSupportPeripheral(_ peripheral:CBPeripheral)-> Bool{
        peripheral.name?.lowercased().starts(with: "miaomiao") ?? false

    }
    required init(delegate: LibreTransmitterDelegate) {

    }

    func requestData(writeCharacteristics: CBCharacteristic, peripheral: CBPeripheral) {

    }
    func updateValueForNotifyCharacteristics(_ value: Data, peripheral: CBPeripheral) {

    }

}
