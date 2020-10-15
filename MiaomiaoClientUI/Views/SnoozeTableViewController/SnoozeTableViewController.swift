//
//  GlucoseNotificationsSettingsTableViewController.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 07/05/2019.
//  Copyright © 2019 Bjørn Inge Berg All rights reserved.
//
import HealthKit
import LoopKit
import LoopKitUI
import MiaomiaoClient
import UIKit

public class SnoozeTableViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
         pickerTimes.count
    }

    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        formatter.string(from: pickerTimes[row]!)!
    }

    lazy var pickerTimes: [TimeInterval?] = pickerTimesArray()

    lazy var formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowsFractionalUnits = false
        formatter.unitsStyle = .full
        return formatter
    }()

    func pickerTimesArray() -> [TimeInterval?] {
        var arr  = [TimeInterval?]()

        let mins10 = 0.166_67
        let mins20 = mins10 * 2
        let mins30 = mins10 * 3
        //let mins40 = mins10 * 4

        for hr in 0..<2 {
            for min in [0.0, mins20, mins20 * 2] {
                arr.append(TimeInterval(hours: Double(hr) + min))
            }
        }
        for hr in 2..<4 {
            for min in [0.0, mins30] {
                arr.append(TimeInterval(hours: Double(hr) + min))
            }
        }

        for hr in 4...8 {
            arr.append(TimeInterval(hours: Double(hr)))
        }

        return arr
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("NotificationsSettingsTableViewController will now disappear")
        disappearDelegate?.onDisappear()
    }

    public weak var disappearDelegate: SubViewControllerWillDisappear?

    public weak var pickerView: UIPickerView!

    private weak var manager: MiaoMiaoClientManager?

    public init(manager: MiaoMiaoClientManager?) {
        self.manager = manager
        super.init(style: .plain)
    }

    private var pickerSelectedRow: Int?

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("pickerSelectedRow: \(row)")
        pickerSelectedRow = row
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(AlarmTimeInputRangeCell.nib(), forCellReuseIdentifier: AlarmTimeInputRangeCell.className)

        tableView.register(GlucoseAlarmInputCell.nib(), forCellReuseIdentifier: GlucoseAlarmInputCell.className)

        tableView.register(TextFieldTableViewCell.nib(), forCellReuseIdentifier: TextFieldTableViewCell.className)
        tableView.register(TextButtonTableViewCell.self, forCellReuseIdentifier: TextButtonTableViewCell.className)
        tableView.register(SegmentViewCell.nib(), forCellReuseIdentifier: SegmentViewCell.className)

        tableView.register(MMSwitchTableViewCell.nib(), forCellReuseIdentifier: MMSwitchTableViewCell.className)

        tableView.register(MMTextFieldViewCell.nib(), forCellReuseIdentifier: MMTextFieldViewCell.className)
        //self.tableView.rowHeight = 44
        //tableView.contentInset = UIEdgeInsets.zero
        //self.automaticallyAdjustsScrollViewInsets = false

        //tableView.tableFooterView = UIView()
        //tableView.tableHeaderView = UIView()
    }

    private enum SnoozeRow: Int, CaseIterable {
        case snoozeButton
        case snoozePicker
        case description

        static let count = SnoozeRow.allCases.count
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        //dynamic number of schedules + sync row
        1
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1//SnoozeRow.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "DefaultCell")


        /*switch SnoozeRow(rawValue: indexPath.row)! {
        case .snoozeButton:
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.text = LocalizedString("Click to Snooze Alerts", comment: "Title of cell to snooze active alarms")
            return cell
        case .snoozePicker:*/
            let height = tableView.rectForRow(at: indexPath).height
            let pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: height ))

            //let pickerView = UIPickerView()
            self.pickerView = pickerView

            cell.addSubview(pickerView)



            //pickerView.fixInView(cell)
            //cell.bringSubviewToFront(pickerView)
            pickerView.dataSource = self
            pickerView.delegate = self

            if let pickerSelectedRow = pickerSelectedRow {
                print("cellforrow: selecting row in picker view: \(pickerSelectedRow)")
                self.pickerView.selectRow(pickerSelectedRow, inComponent: 0, animated: false)
                self.pickerView.reloadAllComponents()
            }

            return cell
        /*case .description:
            cell.textLabel?.textAlignment = .center
            cell.textLabel!.numberOfLines = 0

            var snoozeDescription  = ""
            var celltext = ""

            if let glucoseDouble = manager?.latestBackfill?.glucoseDouble, let activeAlarms = UserDefaults.standard.glucoseSchedules?.getActiveAlarms(glucoseDouble) {
                switch activeAlarms {
                case .high:
                    celltext = "High Glucose Alarm active"
                case .low:
                    celltext = "Low Glucose Alarm active"
                case .none:
                    celltext = "No Glucose Alarm active"
                }
            } else {
                celltext = "No Glucose Alarm active"
            }

            if let until = GlucoseScheduleList.snoozedUntil {
                snoozeDescription = "snoozing until \(until.description(with: .current))"
            } else {
                snoozeDescription = "not snoozing"
            }

            cell.textLabel?.text = [celltext, snoozeDescription].joined(separator: ", ")
        }*/
        return cell
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        nil
    }

    override public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        nil
    }

    override public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        true
    }
    override public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }
    override public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }
    override public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        /*switch SnoozeRow(rawValue: indexPath.row)! {
        case .snoozePicker:

           // let count =  Double(SnoozeRow.count - 1 )// -1 to exclude this row

            let otherHeights = tableView.rectForRow(at: IndexPath(row: SnoozeRow.snoozeButton.rawValue, section: indexPath.section)).height +
            tableView.rectForRow(at: IndexPath(row: SnoozeRow.description.rawValue, section: indexPath.section)).height

            return tableView.frame.size.height - otherHeights - tableView.sectionHeaderHeight - tableView.sectionFooterHeight - tableView.adjustedContentInset.top + 5

        default:
            return tableView.rowHeight
        }*/

        return tableView.frame.size.height + 5


    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.tableView.reloadData()
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        return

        switch SnoozeRow(rawValue: indexPath.row)! {
        case .snoozeButton:
            print("snoozebutton clicked")
            let pickerRow = pickerView.selectedRow(inComponent: 0)
            let interval = pickerTimes[pickerRow]!
            let snoozeFor = formatter.string(from: interval)!
            let untilDate = Date() + interval
            print("will snooze for \(snoozeFor) until \(untilDate.description(with: .current))")

            //reset if date is in the past
            UserDefaults.standard.snoozedUntil = untilDate < Date() ? nil : untilDate
            //refresh only the description, as that is the only cell that will change
            let  descriptionIndex = IndexPath(item: SnoozeRow.description.rawValue, section: indexPath.section)
            self.tableView.reloadRows(at: [descriptionIndex], with: .none)
            //tableView.reloadData()

        case .snoozePicker:
            print("snoozepicker clicked")
        case .description:
            print("snooze description clicked")
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
