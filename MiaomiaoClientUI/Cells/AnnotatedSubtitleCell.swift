//
//  AnnotatedSubtitleCell.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 27/07/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import UIKit

class AnnotatedSubtitleCell<T>: UITableViewCell {
    
    public var annotation: T? = nil
    
    
    override init(style: UITableViewCellStyle = .subtitle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
    }
}
