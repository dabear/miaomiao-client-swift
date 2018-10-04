//
//  SpikeClientSetupViewController.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import UIKit
import LoopKit
import LoopKitUI
import SpikeClient


class SpikeClientSetupViewController: UINavigationController, CGMManagerSetupViewController {
    var setupDelegate: CGMManagerSetupViewControllerDelegate?

    let cgmManager = SpikeClientManager()

    init() {
        let authVC = AuthenticationViewController(authentication: cgmManager.spikeService)

        super.init(rootViewController: authVC)

        authVC.authenticationObserver = { [weak self] (service) in
            self?.cgmManager.spikeService = service
        }
        authVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        authVC.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func cancel() {
        setupDelegate?.cgmManagerSetupViewControllerDidCancel(self)
    }

    @objc private func save() {
        setupDelegate?.cgmManagerSetupViewController(self, didSetUpCGMManager: cgmManager)
    }

}
