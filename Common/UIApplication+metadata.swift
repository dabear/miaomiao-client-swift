//
//  UIApplication+metadata.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 30/12/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation

fileprivate let prefix = "no-bjorninge-mm-git"
enum AppMetadata{
    private static func getMeta<T>(key: String, default defaultValue: @autoclosure () -> T ) ->  T{
        if let anObj = Bundle.current.object(forInfoDictionaryKey: key) as? T {
            return anObj
        }
        return defaultValue()
    }

    private static func getMeta(key: String, defaultString: String = "unknown") ->  String{
        getMeta(key: key, default: "unknown")
    }

    static var gitRevision: String {
        getMeta(key: "\(prefix)-revision")
    }

    static var gitBranch: String {
        getMeta(key: "\(prefix)-git-branch")
    }

    static var gitRemote: String {
        getMeta(key: "\(prefix)-git-remote")
    }

    static var srcRoot: String {
        getMeta(key: "\(prefix)-srcroot")
    }
    static var buildDate: String {
        getMeta(key: "\(prefix)-build-date")
    }
    static var xcodeVersion: String {
        getMeta(key: "\(prefix)-xcode-version")
    }

    static var allProperties : String {
        if let dict = Bundle.current.infoDictionary {
            return dict.map {
                return "\($0.key) + \($0.value)"

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


