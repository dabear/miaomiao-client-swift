//
//  AnnotatedUILabel.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 15/04/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import UIKit

class DateComponentUITableView: UITableView {
    public var components : DateComponents? = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
    }
}

class DateComponentUITableViewCell: UITableViewCell {
    
    
    public var wantsAMPM = false
    
    
    
    func componentsToTimeString(_ components: DateComponents, wantsAMPM: Bool=true) -> String {

        var date = Calendar.current.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: Date())!
        
        
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.long
        formatter.timeStyle = DateFormatter.Style.medium
        
        formatter.dateFormat = wantsAMPM ? "hh:mm a" : "HH:mm"
        return formatter.string(from: date)
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NSLog("DateComponentUITableViewCell init called")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    public var components: DateComponents? = nil{
        didSet {
            if let components = components {
                self.textLabel!.text = componentsToTimeString(components, wantsAMPM: wantsAMPM)
               
                //print("set cell text to \(self.textLabel!.text)")
            } else {
                self.textLabel!.text = ""
            }
            
        }
    }
    
    
}

