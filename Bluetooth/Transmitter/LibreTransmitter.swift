//
//  LibreTransmitter.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 08/01/2020.
//  Copyright © 2020 Mark Wilson. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit
public protocol LibreTransmitter {
    static var shortTransmitterName: String {get}
    static var smallImage: UIImage? {get}
    static var manufacturerer: String {get}
    static func canSupportPeripheral(_ peripheral:CBPeripheral)->Bool

    static var writeCharachteristic: UUIDContainer? {get set}
    static var notifyCharachteristic: UUIDContainer? {get set}
    static var serviceUUID: [UUIDContainer] {get set}


    var delegate: LibreTransmitterDelegate? {get set}
    init(delegate: LibreTransmitterDelegate )
    func requestData(writeCharacteristics: CBCharacteristic, peripheral: CBPeripheral)
    func updateValueForNotifyCharacteristics(_ value: Data, peripheral: CBPeripheral,  writeCharacteristic: CBCharacteristic?)

    func reset()

}


public enum LibreTransmitters {
    public static var all : [LibreTransmitter.Type] {
        return [MiaoMiaoTransmitter.self, BubbleTransmitter.self]
    }
    public static func isSupported(_ peripheral:CBPeripheral) -> Bool{
        return  Self.all.getSupportedPlugins(peripheral)?.isEmpty == false
    }
}

public extension Array where Element == LibreTransmitter.Type {

    func getSupportedPlugins(_ peripheral:CBPeripheral) -> [LibreTransmitter.Type]? {
        self.enumerated().compactMap {
            $0.element.canSupportPeripheral(peripheral) ? $0.element : nil
        }

    }



}


