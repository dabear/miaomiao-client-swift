//
//  MiaomiaoClientSettingsViewController.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import UIKit
import HealthKit
import LoopKit
import LoopKitUI
import MiaomiaoClient


public class MiaomiaoClientSettingsViewController: UITableViewController {

    public let cgmManager: MiaomiaoClientManager

    public let glucoseUnit: HKUnit

    public let allowsDeletion: Bool

    public init(cgmManager: MiaomiaoClientManager, glucoseUnit: HKUnit, allowsDeletion: Bool) {
        self.cgmManager = cgmManager
        self.glucoseUnit = glucoseUnit
        self.allowsDeletion = allowsDeletion

        super.init(style: .grouped)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        title = cgmManager.localizedTitle

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44

        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 55

        tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: "SettingsTableViewCell")
        tableView.register(TextButtonTableViewCell.self, forCellReuseIdentifier: "TextButtonTableViewCell")
    }

    // MARK: - UITableViewDataSource

    private enum Section: Int {
        case authentication
        case latestReading
        case delete

        static let count = 3
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return allowsDeletion ? Section.count : Section.count - 1
    }

    private enum LatestReadingRow: Int {
        case glucose
        case date
        case trend

        static let count = 3
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .authentication:
            return 1
        case .latestReading:
            return LatestReadingRow.count
        case .delete:
            return 1
        }
    }

    private lazy var glucoseFormatter: QuantityFormatter = {
        let formatter = QuantityFormatter()
        formatter.setPreferredNumberFormatter(for: glucoseUnit)
        return formatter
    }()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .authentication:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsTableViewCell", for: indexPath) as! SettingsTableViewCell

            let service = cgmManager.miaomiaoService

            cell.textLabel?.text = ""
            cell.detailTextLabel?.text = "no username needed"
            cell.accessoryType = .disclosureIndicator

            return cell
        case .latestReading:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsTableViewCell", for: indexPath) as! SettingsTableViewCell
            
            cell.textLabel?.text = "some cell"
            return cell
        case .delete:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextButtonTableViewCell", for: indexPath) as! TextButtonTableViewCell

            cell.textLabel?.text = "delete this?"
            cell.textLabel?.textAlignment = .center
            cell.tintColor = .delete
            cell.isEnabled = true
            return cell
        }
    }

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .authentication:
            return nil
        case .latestReading:
            return "Latest reading"
        case .delete:
            return nil
        }
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .authentication:
            let vc = AuthenticationViewController(authentication: cgmManager.miaomiaoService)
            vc.authenticationObserver = { [weak self] (service) in
                self?.cgmManager.miaomiaoService = service

                self?.tableView.reloadRows(at: [indexPath], with: .none)
            }

            show(vc, sender: nil)
        case .latestReading:
            tableView.deselectRow(at: indexPath, animated: true)
        case .delete:
            let confirmVC = UIAlertController(cgmDeletionHandler: {
                self.cgmManager.cgmManagerDelegate?.cgmManagerWantsDeletion(self.cgmManager)
                self.navigationController?.popViewController(animated: true)
            })

            present(confirmVC, animated: true) {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
}


private extension UIAlertController {
    convenience init(cgmDeletionHandler handler: @escaping () -> Void) {
        self.init(
            title: nil,
            message: "are you sure you want to delete this test",
            preferredStyle: .actionSheet
        )

        addAction(UIAlertAction(
            title: "delete",
            style: .destructive,
            handler: { (_) in
                handler()
            }
        ))

        let cancel = "cancel"
        addAction(UIAlertAction(title: cancel, style: .cancel, handler: nil))
    }
}
