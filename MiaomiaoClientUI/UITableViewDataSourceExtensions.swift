//
//  UITableViewDataSourceExtensions.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 01/06/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import UIKit

extension UITableView {
    /**
     * EXAMPLE: tableView.cells//list of cells in a tableview
     */
    var cells:[UITableViewCell] {
        return (0..<self.numberOfSections).indices.map { (sectionIndex:Int) -> [UITableViewCell] in
            return (0..<self.numberOfRows(inSection: sectionIndex)).indices.compactMap{ (rowIndex:Int) -> UITableViewCell? in
                return self.cellForRow(at: IndexPath(row: rowIndex, section: sectionIndex))
            }
            }.flatMap{$0}
    }
}
