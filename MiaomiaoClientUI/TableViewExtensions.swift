//
//  TableViewExtensions.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 19/10/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import UIKit
//let cell = tableView.dequeueReusableCell(withIdentifier: TextButtonTableViewCell.className, for: indexPath) as! TextButtonTableViewCell

typealias IdentifiableUITableViewCell = UITableViewCell & IdentifiableClass

extension UITableView {
    func dequeueIdentifiableCell<T: IdentifiableUITableViewCell>(cell: T.Type, for indexPath: IndexPath) -> T  {
        let cell: T = self.dequeueReusableCell(withIdentifier: T.className, for: indexPath) as! T

        return cell

    }
}
