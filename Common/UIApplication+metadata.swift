//
//  UIApplication+metadata.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 30/12/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
enum AppMetadata{
    private static func getMeta<T>(key: String, default defaultValue: @autoclosure () -> T ) ->  T{
        if let anObj = Bundle.current.object(forInfoDictionaryKey: key) as? T {
            return anObj
        }
        return defaultValue()
    }

    private static func getMeta(key: String) ->  String{
        getMeta(key: key, default: "unknown")
    }

    static var gitRevision: String {
        getMeta(key: "no-bjorninge-mm-git-revision", default: "unknown")
    }

    static var gitBranch: String {
        getMeta(key: "no-bjorninge-mm-git-branch", default: "unknown")
    }

    static var gitRemote: String {
        getMeta(key: "no-bjorninge-mm-git-remote", default: "unknown")
    }

    static var srcRoot: String {
        getMeta(key: "no-bjorninge-mm-srcroot", default: "unknown")
    }
    static var buildDate: String {
        getMeta(key: "no-bjorninge-mm-build-date", default: "unknown")
    }
    static var xcodeVersion: String {
        getMeta(key: "no-bjorninge-mm-xcode-version", default: "unknown")
    }

}

extension Bundle {
    static var current: Bundle {
        class Helper { }
        return Bundle(for: Helper.self)
    }
}


