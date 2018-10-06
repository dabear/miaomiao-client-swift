//
//  ViewController.swift
//  singleviewtesterapp2
//
//  Created by Bjørn Inge Berg on 04.10.2018.
//  Copyright © 2018 Mark Wilson. All rights reserved.
//

import UIKit
import os
import SpikeClient
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        os_log("dabear: iphone view did load %@", log: .default, type: .default, "yes")
        let client = SpikeClient(username: "test", password: "test2", spikeServer: KnownSpikeServers.)
        
        client.fetchLast(3) { (error, glucose) in
            os_log("dabear: iphonefetchlast", type: .default)
            os_log("dabear: iphone err: %@", log: .default, type: .default, "\(error)")
            
            if let glucose = glucose {
                os_log("dabear: iphone glucose %@", log: .default, type: .default, "\(glucose)")
                
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

