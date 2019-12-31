//
//  CBPeripheral.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 31/12/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit
import MiaomiaoClient
extension CBPeripheral{


    public var bridgeType: SupportedDevices? {
        guard let name = self.name?.lowercased() else {
            return nil
        }
        switch name {
        case let x where x.starts(with: "miaomiao"):
            return SupportedDevices.MiaoMiao
        case let x where x.starts(with: "bubble"):
            return SupportedDevices.Bubble
        default:
            return nil
        }
    }

    public var smallImage: UIImage? {
       let bundle = Bundle.current
       print("dabear:: bridgetype is \(bridgeType)")

       guard let bridgeType = bridgeType else {
           return nil
       }
       switch bridgeType {
       case .Bubble:
           return UIImage(named: "bubble", in: bundle, compatibleWith: nil)
       case .MiaoMiao:
           return UIImage(named: "miaomiao-small", in: bundle, compatibleWith: nil)
       }
   }
}
