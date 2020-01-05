//
//  UIApplication+metadata.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 30/12/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation

fileprivate let prefix = "no-bjorninge-mm"
enum AppMetaData {

    static var allProperties : String {
        if let dict = Bundle.current.infoDictionary {
            return dict.compactMap {
                guard $0.key.starts(with: prefix) else {
                    return nil
                }
                return "\($0.key): \($0.value)"

            }.joined(separator: "\n")
        }
        return "none"
    }


}

extension Bundle {
    static var current: Bundle {
        class Helper { }
        return Bundle(for: Helper.self)
    }
}
