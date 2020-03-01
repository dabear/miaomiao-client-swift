//
//  LogNilAccess.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 27/02/2020.
//  Copyright © 2020 Mark Wilson. All rights reserved.
//

import Foundation
import os.log
fileprivate protocol AnyOptional{
    var isNil: Bool { get }
}
extension Optional: AnyOptional{
    var isNil: Bool { self == nil }
}

@propertyWrapper struct LogNilAccess<V> {
    var value: V
    weak var logger: OSLog!
    var logmsg : StaticString?

    init(wrappedValue initialValue: V, logger: OSLog, logmsg: StaticString?) {
        self.value = initialValue
        self.logger = logger
        self.logmsg  = logmsg

    }
    init(wrappedValue initialValue: V, logger: OSLog) {
        self.init(wrappedValue: initialValue, logger: logger, logmsg: nil)
    }

    var wrappedValue: V {
        get {
            if (value as? AnyOptional)?.isNil == true {
                os_log(.debug, log: self.logger, self.logmsg ?? "value was nil")
            }
            return value
        }
        set { value = newValue }
    }
}
