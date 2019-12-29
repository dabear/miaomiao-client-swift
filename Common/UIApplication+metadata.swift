//
//  UIApplication+metadata.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 30/12/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
enum AppMetadata{
    private static func get<T>(key: String, default defaultValue: @autoclosure () -> T ) ->  T{
        if let anObj = Bundle.main.object(forInfoDictionaryKey: key) as? T {
            return anObj
        }
        return defaultValue()
    }

    private static func get(key: String) ->  String{
        return get(key: key, default: "unknown")
    }

    static var gitRevision: String {
        return get(key: "no-bjorninge-mm-git-revision", default: "unknown")
    }

    static var gitBranch: String {
        return get(key: "no-bjorninge-mm-git-branch", default: "unknown")
    }

    static var gitRemote: String {
        return get(key: "no-bjorninge-mm-git-remote", default: "unknown")
    }

    static var srcRoot: String {
        return get(key: "no-bjorninge-mm-srcroot", default: "unknown")
    }
    static var buildDate: String {
        return get(key: "no-bjorninge-mm-build-date", default: "unknown")
    }
    static var xcodeVersion: String {
        return get(key: "no-bjorninge-mm-xcode-version", default: "unknown")
    }

}

