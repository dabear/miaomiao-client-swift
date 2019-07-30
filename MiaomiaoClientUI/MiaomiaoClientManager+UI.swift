//
//  MiaomiaoClientManager+UI.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import LoopKitUI
import HealthKit
import MiaomiaoClient

extension MiaoMiaoClientManager: CGMManagerUI {
    public static func setupViewController() -> (UIViewController & CGMManagerSetupViewController & CompletionNotifying)? {
        return MiaomiaoClientSetupViewController()
    }
    
   

    public func settingsViewController(for glucoseUnit: HKUnit) -> (UIViewController & CompletionNotifying & CompletionNotifying) {
        let settings =  MiaomiaoClientSettingsViewController(cgmManager: self, glucoseUnit: glucoseUnit, allowsDeletion: true)
        let nav = SettingsNavigationViewController(rootViewController: settings)
        return nav
    }

    public var smallImage: UIImage? {
       
        return self.getSmallImage()
    }
}
