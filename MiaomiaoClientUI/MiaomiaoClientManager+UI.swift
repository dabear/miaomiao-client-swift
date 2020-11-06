//
//  MiaomiaoClientManager+UI.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import HealthKit
import MiaomiaoClient

extension MiaoMiaoClientManager: CGMManagerUI {
    public static func setupViewController(glucoseTintColor: Color, guidanceColors: GuidanceColors) -> (UIViewController & CGMManagerSetupViewController & CompletionNotifying)? {
        MiaomiaoClientSetupViewController()
    }

    // TODO Placeholder. This functionality will come with LOOP-1311
    public var cgmStatusHighlight: DeviceStatusHighlight? {
        nil
    }

    // TODO Placeholder. This functionality will come with LOOP-1311
    public var cgmLifecycleProgress: DeviceLifecycleProgress? {
        nil
    }


    public func settingsViewController(for glucoseUnit: HKUnit, glucoseTintColor: Color, guidanceColors: GuidanceColors) -> (UIViewController & CompletionNotifying ) {
        let settings = MiaomiaoClientSettingsViewController(cgmManager: self, glucoseUnit: glucoseUnit, allowsDeletion: true)
        let nav = SettingsNavigationViewController(rootViewController: settings)
        return nav
    }

    public var smallImage: UIImage? {
        self.getSmallImage()
    }
}
