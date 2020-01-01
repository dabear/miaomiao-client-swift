//
//  CBPeripheral+CompatibleDevice.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 30/12/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth



public enum SupportedDevices: Int, CaseIterable {
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

    public static func isSupported(_ peripheral: CBPeripheral ) -> Bool {
        if let name = peripheral.name?.lowercased() {
            return allNames.contains {
                //$0.starts(with: name) // miaomiao.startswith("miaomiao2_xxx")
                name.starts(with: $0) // miaomiao2_xxx.startswith("miaomia")
            }
        }
        return false
    }

    public static var allNames: [String] {
        SupportedDevices.allCases.map { $0.name }
    }
}




