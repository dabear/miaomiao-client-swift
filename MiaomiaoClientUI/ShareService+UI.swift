//
//  ShareService+UI.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import LoopKitUI
import MiaomiaoClient


extension MiaomiaoService: ServiceAuthenticationUI {
    public var credentialFormFields: [ServiceCredential] {
        return [
           
            ServiceCredential(
                title: LocalizedString("Libre Sensor operational mode", comment: "The title of the Sensor operational mode"),
                isSecret: false,
                options: [
                    (title: LocalizedString("Spike", comment: "Spike server option title"),
                     value: "Default raw operational mode")
                    
                ]
            )
        ]
    }
}
