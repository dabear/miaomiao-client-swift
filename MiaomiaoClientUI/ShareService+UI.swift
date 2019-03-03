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
                title: "foo",
                isSecret: false,
                options: [
                    (title: "bar",
                     value: "Default raw operational mode")
                    
                ]
            )
        ]
    }
}
