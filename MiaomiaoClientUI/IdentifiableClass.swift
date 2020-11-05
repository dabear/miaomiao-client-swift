//
//  IdentifiableClass.swift
//  Naterade
//
//  Created by Nathan Racklyeft on 5/22/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation
import UIKit

protocol IdentifiableClass: class {
    static var className: String { get }
}

extension IdentifiableClass {
    static var className: String {
        //NSStringFromClass(self).components(separatedBy: ".").last!
        String(describing: Self.self)
    }
}
extension UITableViewCell: IdentifiableClass { }
