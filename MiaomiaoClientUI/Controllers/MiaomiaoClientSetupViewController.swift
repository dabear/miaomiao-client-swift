//
//  MiaomiaoClientSetupViewController.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import LoopKit
import LoopKitUI
import MiaomiaoClient
import UIKit
import SwiftUI

class MiaomiaoClientSetupViewController: UINavigationController, CGMManagerSetupViewController, CompletionNotifying {
    weak var completionDelegate: CompletionDelegate?

    // this must follow the protocol from loopkit, so it cannot be weak
    // swiftlint:disable:next weak_delegate
    var setupDelegate: CGMManagerSetupViewControllerDelegate?

    lazy var cgmManager: MiaoMiaoClientManager? =  MiaoMiaoClientManager()

    weak var deviceSelect : UIHostingController<BluetoothSelection>!

    init() {
        
        //let service = MiaomiaoService(keychainManager: KeychainManager())
        //let authVC = AuthenticationViewController(authentication: service)
        //ExtendingAuthController.addExtendedSection(source: authVC)

        deviceSelect = BluetoothSelection.asHostedViewController()

        super.init(rootViewController: deviceSelect)

        /*
        authVC.authenticationObserver = {  service in
            //self?.cgmManager?.miaomiaoService = service
            NSLog("miaomiaoservice was setup")
            let keychain = KeychainManager()
            do {
                NSLog("dabear:: miaomiaoservice setAutoCalibrateWebAccessToken called")
                try keychain.setAutoCalibrateWebAccessToken(accessToken: service.accessToken, url: service.url)
            } catch {
                NSLog("dabear:: miaomiaoservice could not permanently save setAutoCalibrateWebAccessToken")
            }

            return
        }*/
        /*
        authVC.authenticationObserver = { [weak self] (service) in
            self?.cgmManager.miaomiaoService = service
        }
        */
        deviceSelect.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        deviceSelect.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    deinit {
        NSLog("dabear MiaomiaoClientSetupViewController() deinit was called")
        //cgmManager = nil
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func cancel() {
        //setupDelegate?.cgmManagerSetupViewControllerDidCancel(self)
        completionDelegate?.completionNotifyingDidComplete(self)
        //ExtendingAuthController.destroyExtension()
    }

    @objc
    private func save() {
        if let cgmManager = cgmManager {
            setupDelegate?.cgmManagerSetupViewController(self, didSetUpCGMManager: cgmManager)
            /*var newDevice = deviceSelect.rootView.getNewDeviceId()
            if let newDevice = newDevice {
                print("dabear: Setupcontroller will set new device to \(newDevice)")
                UserDefaults.standard.preSelectedDevice = newDevice
            }*/

        }
        completionDelegate?.completionNotifyingDidComplete(self)
        //ExtendingAuthController.destroyExtension()
    }
}
