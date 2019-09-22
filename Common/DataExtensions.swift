//
//  DataExtensions.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 22/09/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation

extension Data {
    mutating func resetAllBytes() {

        self = Data()
    }
}
