//
//  AlertControllers.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 03/06/2019.
//  
//

import UIKit



func OKAlertController(_ message: String, title: String )-> UIAlertController {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    // Create OK button
    let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
        
        // Code in this block will trigger when OK button tapped.
        
        
    }
    alertController.addAction(OKAction)
    return alertController
}
func ErrorAlertController(_ message: String, title: String )-> UIAlertController {
    let alertController = UIAlertController(title: title + "❗️", message: message, preferredStyle: .alert)
    
    // Create OK button
    let OKAction = UIAlertAction(title: "ok", style: .cancel) { (action:UIAlertAction!) in
        
        // Code in this block will trigger when OK button tapped.
        
        
    }
    alertController.addAction(OKAction)
    return alertController
}
