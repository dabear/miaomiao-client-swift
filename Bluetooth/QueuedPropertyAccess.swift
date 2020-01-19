//
//  QueuedPropertyAccess.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 19/01/2020.
//  Copyright © 2020 Mark Wilson. All rights reserved.
//

import Foundation

@dynamicMemberLookup
class QueuedPropertyAccess<U:AnyObject>{
    weak var anObj : U?
    weak var dispatchQueue: DispatchQueue!
    init(_ anObj:U, dispatchQueue:DispatchQueue) {
        self.anObj = anObj
        self.dispatchQueue = dispatchQueue
    }

    subscript<T>(dynamicMember keyPath: KeyPath<U, T>) -> T {
        //We need to store an Optional<Optional<T>> (nested optional) here
        //unwrapping this is ok as long as the dispatchqueue assigns a result to the variable
        var result: T? = nil

        dispatchQueue.sync {
            result = self.anObj?[keyPath: keyPath]
        }

        //result = self.anObj?[keyPath: keyPath]

        if (result as? Self) === self {
            fatalError("self reference not allowed")
        }

        return result!
    }


}
