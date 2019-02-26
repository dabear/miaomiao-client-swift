//
//  MiaomiaoClientSetupViewController.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import UIKit
import LoopKit
import LoopKitUI
import MiaomiaoClient


class MiaomiaoClientSetupViewController: UINavigationController, CGMManagerSetupViewController {
    var setupDelegate: CGMManagerSetupViewControllerDelegate?

    let cgmManager = MiaomiaoClientManager()

    init() {
        let authVC = AuthenticationViewController(authentication: cgmManager.miaomiaoService)

        super.init(rootViewController: authVC)

        authVC.authenticationObserver = { [weak self] (service) in
            self?.cgmManager.miaomiaoService = service
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
