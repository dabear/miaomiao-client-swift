//
//  MiaomiaoClientManager+UI.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import LoopKitUI
import HealthKit
import MiaomiaoClient


extension MiaomiaoClientManager: CGMManagerUI {
    public static func setupViewController() -> (UIViewController & CGMManagerSetupViewController)? {
        return MiaomiaoClientSetupViewController()
    }

    public func settingsViewController(for glucoseUnit: HKUnit) -> UIViewController {
        return MiaomiaoClientSettingsViewController(cgmManager: self, glucoseUnit: glucoseUnit, allowsDeletion: true)
    }

    public var smallImage: UIImage? {
        return nil
    }
}
