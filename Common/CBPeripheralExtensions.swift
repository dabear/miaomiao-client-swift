//
//  CBPeripheralExtensions.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 19/10/2020.
//  Copyright © 2020 Bjørn Inge Vikhammermo Berg. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol PeripheralProtocol {
    var name : String? {get}
    var name2: String {get}

    var asStringIdentifier : String { get }
}

extension CBPeripheral : PeripheralProtocol, Identifiable {

    public var name2 : String {
        self.name ?? ""
    }


    public var asStringIdentifier : String {
        return self.identifier.uuidString
    }
}

public struct MockedPeripheral : PeripheralProtocol, Equatable, Hashable, Identifiable{

    public var id: Int
    public var asStringIdentifier : String {
        return String(self.id)
    }

    public static func == (lhs: MockedPeripheral, rhs: MockedPeripheral) -> Bool {
        lhs.id == rhs.id
    }



    public var name: String?
    public var name2: String

    public init(identifier: Int) {
        name = "aName"
        name2 = "aName2"
        self.id = identifier
    }
}


