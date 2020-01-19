//
//  BubbleTransmitter.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 08/01/2020.
//  Copyright © 2020 Mark Wilson. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

public enum BubbleResponseType: UInt8 {
    case dataPacket = 130
    case bubbleInfo = 128 // = wakeUp + device info
    case noSensor = 191
    case serialNumber = 192
}

// The Bubble uses the same serviceUUID,
// writeCharachteristic and notifyCharachteristic
// as the MiaoMiao, but different byte sequences
class BubbleTransmitter: MiaoMiaoTransmitter{
    override class var shortTransmitterName: String {
        "bubble"
    }
    override class var manufacturerer: String {
        "bubbledevteam"
    }

    override class var smallImage: UIImage? {

        return UIImage(named: "bubble", in: Bundle.current, compatibleWith: nil)
    }

    override static func canSupportPeripheral(_ peripheral:CBPeripheral)->Bool{
        peripheral.name?.lowercased().starts(with: "bubble") ?? false
    }

    override func reset() {
        rxBuffer.resetAllBytes()
    }

    private var hardware : String? = ""
    private var firmware : String? = ""
    private var mac : String? = ""

    func deviceFromAdvertisementData(advertisementData: [String: Any]? ) {

        print("dabear: deviceFromAdvertisementData is ")
        debugPrint(advertisementData)

        guard let data = advertisementData?["kCBAdvDataManufacturerData"] as? Data else {
            return
        }
        var mac = ""
        for i in 0 ..< 6 {
            mac += data.subdata(in: (7 - i)..<(8 - i)).hexEncodedString().uppercased()
            if i != 5 {
                mac += ":"
            }
        }

        self.mac = mac

        guard  data.count >= 12 else {
            return
        }

        let fSub1 = Data.init(repeating: data[8], count: 1)
        let fSub2 = Data.init(repeating: data[9], count: 1)
        self.firmware = Float("\(fSub1.hexEncodedString()).\(fSub2.hexEncodedString())")?.description

        let hSub1 = Data.init(repeating: data[10], count: 1)
        let hSub2 = Data.init(repeating: data[11], count: 1)

        self.hardware = Float("\(hSub1.hexEncodedString()).\(hSub2.hexEncodedString())")?.description

        print("got bubbledevice \(mac) with firmware \(firmware), and hardware \(hardware)")


    }

    required init(delegate: LibreTransmitterDelegate, advertisementData: [String : Any]?) {
        //advertisementData is unknown for the miaomiao

        super.init(delegate: delegate, advertisementData: advertisementData)
        //self.delegate = delegate
        deviceFromAdvertisementData(advertisementData: advertisementData)
    }

    override func requestData(writeCharacteristics: CBCharacteristic, peripheral: CBPeripheral) {
        print("dabear:: bubbleRequestData")
        reset()
        //timer?.invalidate()
        print("-----set: ", writeCharacteristics)
        peripheral.writeValue(Data([0x00, 0x00, 0x05]), for: writeCharacteristics, type: .withResponse)


    }
    override func updateValueForNotifyCharacteristics(_ value: Data, peripheral: CBPeripheral, writeCharacteristic: CBCharacteristic?) {
        print("dabear:: bubbleDidUpdateValueForNotifyCharacteristics")
        guard let firstByte = value.first, let bubbleResponseState = BubbleResponseType(rawValue: firstByte) else {
           return
        }
        switch bubbleResponseState {
        case .bubbleInfo:
           //let hardware = value[2].description + ".0"
           //let firmware = value[1].description + ".0"
           let battery = Int(value[4])
           metadata = .init(hardware: hardware ?? "unknown", firmware: firmware ?? "unknown", battery: battery, name: Self.shortTransmitterName, macAddress: self.mac)

           print("dabear:: Got bubbledevice: \(metadata)")
           if let writeCharacteristic = writeCharacteristic {
               print("-----set: ", writeCharacteristic)
               peripheral.writeValue(Data([0x02, 0x00, 0x00, 0x00, 0x00, 0x2B]), for: writeCharacteristic, type: .withResponse)
           }
        case .dataPacket:
           rxBuffer.append(value.suffix(from: 4))
           if rxBuffer.count >= 352 {
               handleCompleteMessage()
               reset()
           }
        case .noSensor:
            delegate?.libreTransmitterReceivedMessage(0x0000, txFlags: 0x34, payloadData: rxBuffer)

           reset()
        case .serialNumber:
           rxBuffer.append(value.subdata(in: 2..<10))
        }
    }


    private var rxBuffer = Data()
    private var sensorData : SensorData?
    private var metadata: LibreTransmitterMetadata?

    override func handleCompleteMessage() {
        print("dabear:: bubbleHandleCompleteMessage")

        guard rxBuffer.count >= 352 else {
            return
        }

        let data = rxBuffer.subdata(in: 8..<352)
        print("dabear:: bubbleHandleCompleteMessage raw data: \([UInt8](rxBuffer))")
        sensorData = SensorData(uuid: rxBuffer.subdata(in: 0..<8), bytes: [UInt8](data), date: Date())

        print("dabear:: bubble got sensordata \(sensorData) and metadata \(metadata), delegate is \(delegate)")
        if let sensorData = sensorData, let metadata = metadata {

            delegate?.libreTransmitterDidUpdate(with: sensorData, and: metadata)
        }


    }

}
