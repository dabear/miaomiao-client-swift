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

    lazy var cgmManager : MiaoMiaoClientManager? = MiaoMiaoClientManager()

    init() {
        let authVC = AuthenticationViewController(authentication: MiaoMiaoClientManager.miaomiaoService)

        super.init(rootViewController: authVC)

        authVC.authenticationObserver = {  (service) in
            //self?.cgmManager?.miaomiaoService = service
            return
        }
        /*
        authVC.authenticationObserver = { [weak self] (service) in
            self?.cgmManager.miaomiaoService = service
        }
        */
        authVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        authVC.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    deinit {
        NSLog("dabear MiaomiaoClientSetupViewController() deinit was called")
        cgmManager = nil
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func cancel() {
        setupDelegate?.cgmManagerSetupViewControllerDidCancel(self)
    }

    @objc private func save() {
        if let cgmManager = cgmManager {
            setupDelegate?.cgmManagerSetupViewController(self, didSetUpCGMManager: cgmManager)
        }
        
    }

}
