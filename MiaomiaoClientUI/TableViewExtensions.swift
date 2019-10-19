//
//  TableViewExtensions.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 19/10/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import UIKit

extension UITableView {
    func dequeueIdentifiableCell<T: UITableViewCell>(cell: T.Type, for indexPath: IndexPath) -> T {
        return self.dequeueReusableCell(withIdentifier: T.className, for: indexPath) as! T

    }
}
