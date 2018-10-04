//
//  SpikeClientSettingsViewController.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import UIKit
import HealthKit
import LoopKit
import LoopKitUI
import SpikeClient


public class SpikeClientSettingsViewController: UITableViewController {

    public let cgmManager: SpikeClientManager

    public let glucoseUnit: HKUnit

    public let allowsDeletion: Bool

    public init(cgmManager: SpikeClientManager, glucoseUnit: HKUnit, allowsDeletion: Bool) {
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

        tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.className)
        tableView.register(TextButtonTableViewCell.self, forCellReuseIdentifier: TextButtonTableViewCell.className)
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
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.className, for: indexPath) as! SettingsTableViewCell

            let service = cgmManager.spikeService

            cell.textLabel?.text = LocalizedString("Credentials", comment: "Title of cell to set credentials")
            cell.detailTextLabel?.text = service.username ?? SettingsTableViewCell.TapToSetString
            cell.accessoryType = .disclosureIndicator

            return cell
        case .latestReading:
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.className, for: indexPath) as! SettingsTableViewCell
            let glucose = cgmManager.latestBackfill

            switch LatestReadingRow(rawValue: indexPath.row)! {
            case .glucose:
                cell.textLabel?.text = LocalizedString("Glucose", comment: "Title describing glucose value")

                if let quantity = glucose?.quantity, let formatted = glucoseFormatter.string(from: quantity, for: glucoseUnit) {
                    cell.detailTextLabel?.text = formatted
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            case .date:
                cell.textLabel?.text = LocalizedString("Date", comment: "Title describing glucose date")

                if let date = glucose?.timestamp {
                    cell.detailTextLabel?.text = dateFormatter.string(from: date)
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            case .trend:
                cell.textLabel?.text = LocalizedString("Trend", comment: "Title describing glucose trend")

                cell.detailTextLabel?.text = glucose?.trendType?.localizedDescription ?? SettingsTableViewCell.NoValueString
            }

            return cell
        case .delete:
            let cell = tableView.dequeueReusableCell(withIdentifier: TextButtonTableViewCell.className, for: indexPath) as! TextButtonTableViewCell

            cell.textLabel?.text = LocalizedString("Delete CGM", comment: "Title text for the button to remove a CGM from Loop")
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
            return LocalizedString("Latest Reading", comment: "Section title for latest glucose reading")
        case .delete:
            return nil
        }
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .authentication:
            let vc = AuthenticationViewController(authentication: cgmManager.spikeService)
            vc.authenticationObserver = { [weak self] (service) in
                self?.cgmManager.spikeService = service

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
            message: LocalizedString("Are you sure you want to delete this CGM?", comment: "Confirmation message for deleting a CGM"),
            preferredStyle: .actionSheet
        )

        addAction(UIAlertAction(
            title: LocalizedString("Delete CGM", comment: "Button title to delete CGM"),
            style: .destructive,
            handler: { (_) in
                handler()
            }
        ))

        let cancel = LocalizedString("Cancel", comment: "The title of the cancel action in an action sheet")
        addAction(UIAlertAction(title: cancel, style: .cancel, handler: nil))
    }
}
