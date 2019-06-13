//
//  GlucoseNotificationsSettingsTableViewController.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 07/05/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//
import UIKit
import LoopKitUI
import LoopKit

import HealthKit


public class CalibrationEditTableViewController: UITableViewController , mmTextFieldViewCellCellDelegate {
    
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("NotificationsSettingsTableViewController will now disappear")
        disappearDelegate?.onDisappear()
    }
    
    public weak var disappearDelegate : SubViewControllerWillDisappear? = nil
   
    
  
    
    

    
    public init() {
        
        super.init(style: .grouped)
        
        
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(AlarmTimeInputRangeCell.nib(), forCellReuseIdentifier: AlarmTimeInputRangeCell.className)
        
        tableView.register(GlucoseAlarmInputCell.nib(), forCellReuseIdentifier: GlucoseAlarmInputCell.className)
        
        tableView.register(TextFieldTableViewCell.nib(), forCellReuseIdentifier: TextFieldTableViewCell.className)
        tableView.register(TextButtonTableViewCell.self, forCellReuseIdentifier: TextButtonTableViewCell.className)
        tableView.register(SegmentViewCell.nib(), forCellReuseIdentifier: SegmentViewCell.className)
        
        tableView.register(mmSwitchTableViewCell.nib(), forCellReuseIdentifier: mmSwitchTableViewCell.className)
        
        tableView.register(mmTextFieldViewCell.nib(), forCellReuseIdentifier: mmTextFieldViewCell.className)
        self.tableView.rowHeight = 44;
    }
    
    private enum CalibrationDataInfoRow: Int {
        case slopeslope
        case slopeoffset
        case offsetslope
        case offsetoffset
        case isValidForFooterWithCRCs
        
        
        
        static let count = 5
    }
    
    private enum Section: Int {
        case CalibrationDataInfoRow
        case sync
    }
    
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        //dynamic number of schedules + sync row
        return 2
        
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .CalibrationDataInfoRow:
            return CalibrationDataInfoRow.count
        case .sync:
            return 1
        }
    }
    private weak var notificationEveryXTimesCell: mmTextFieldViewCell?
    @objc private func notificationAlwaysChanged(_ sender: UISwitch) {
        print("notificationalways changed to \(sender.isOn)")
        UserDefaults.standard.mmAlwaysDisplayGlucose = sender.isOn
        notificationEveryXTimesCell?.isEnabled = !sender.isOn
    }
    
    @objc private func notificationLowBatteryChanged(_ sender: UISwitch) {
        print("notificationLowBatteryChanged changed to \(sender.isOn)")
        UserDefaults.standard.mmAlertLowBatteryWarning = sender.isOn
    }
    @objc private func alarmsSchedulesActivatedChanged(_ sender: UISwitch) {
        print("alarmsSchedulesActivatedChanged changed to \(sender.isOn)")
        //UserDefaults.standard. = sender.isOn
    }
    
    @objc private func sensorChangeEventChanged(_ sender: UISwitch) {
        print("sensorChangeEventChanged changed to \(sender.isOn)")
        UserDefaults.standard.mmAlertNewSensorDetected = sender.isOn
    }
    
    @objc private func notificationlertWillSoonExpireChanged(_ sender: UISwitch) {
        print("mmAlertWillSoonExpire changed to \(sender.isOn)")
        UserDefaults.standard.mmAlertWillSoonExpire = sender.isOn
    }
    
    
    @objc private func noSensorDetectedEventChanged(_ sender: UISwitch) {
        print("noSensorDetectedEventChanged changed to \(sender.isOn)")
        UserDefaults.standard.mmAlertNoSensorDetected = sender.isOn
    }
    
    @objc private func unitSegmentValueChanged(_ sender: UISegmentedControl) {
      

        
    }
    
    @objc private func notificationGlucoseAlarmsVibrate(_ sender: UISwitch) {
        print("mmGlucoseAlarmsVibrate changed to \(sender.isOn)")
        UserDefaults.standard.mmGlucoseAlarmsVibrate = sender.isOn
    }
    
    
    
    func mmTextFieldViewCellDidUpdateValue(_ cell: mmTextFieldViewCell, value: String?) {
        
        if let value = value, let intVal = Int(value) {
            print("textfield was updated: \(intVal)")
            UserDefaults.standard.mmNotifyEveryXTimes = intVal
        }
    }
    
    
    
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        if indexPath.section == Section.sync.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: TextButtonTableViewCell.className, for: indexPath) as! TextButtonTableViewCell
            
            cell.textLabel?.text = LocalizedString("Save calibrations", comment: "The title for Save calibration")
            return cell
        }
        
        
        switch CalibrationDataInfoRow(rawValue: indexPath.row)! {
        case .offsetoffset:
            let cell = (tableView.dequeueReusableCell(withIdentifier: mmTextFieldViewCell.className, for: indexPath) as! mmTextFieldViewCell)
            
            cell.textInput?.text = "-1"
            cell.titleLabel.text = NSLocalizedString("offsetoffset", comment: "The title text for offsetoffset calibration setting")
            cell.delegate = self
            
            return cell
            
        case .offsetslope:
            let cell = (tableView.dequeueReusableCell(withIdentifier: mmTextFieldViewCell.className, for: indexPath) as! mmTextFieldViewCell)
            cell.textInput?.text = "-1"
            cell.titleLabel.text = NSLocalizedString("offsetslope", comment: "The title text for offsetslope calibration setting")
            cell.delegate = self
            return cell
        case .slopeoffset:
            let cell = (tableView.dequeueReusableCell(withIdentifier: mmTextFieldViewCell.className, for: indexPath) as! mmTextFieldViewCell)
            cell.textInput?.text = "-1"
            cell.titleLabel.text = NSLocalizedString("slopeoffset", comment: "The title text for slopeoffset calibration setting")
            cell.delegate = self
            return cell
        case .slopeslope:
            let cell = (tableView.dequeueReusableCell(withIdentifier: mmTextFieldViewCell.className, for: indexPath) as! mmTextFieldViewCell)
            
            
            cell.textInput?.allowedChars = ""
            cell.textInput?.maxLength = 99
        
            
            cell.textInput?.text = "-1"
            cell.titleLabel.text = NSLocalizedString("slopeslope", comment: "The title text for slopeslope calibration setting")
            cell.delegate = self
            return cell
            
        case .isValidForFooterWithCRCs:
            let cell = (tableView.dequeueReusableCell(withIdentifier: mmTextFieldViewCell.className, for: indexPath) as! mmTextFieldViewCell)
            
           
            
            cell.textInput?.allowedChars = ""
            cell.textInput?.maxLength = 99
            cell.textInput?.text = "11111"
            
            cell.titleLabel.text = NSLocalizedString("IsValidForFooter", comment: "The title for the footer crc checksum linking these calibration values to this particular sensor")
            cell.delegate = self
            cell.isEnabled = false
            return cell
        }
    }
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Section.sync.rawValue {
            return nil
        }
        return LocalizedString("Calibrations edit mode", comment: "The title text for the Notification settings")
            
       
    }
    
    public override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return nil
        
    }
    
    public override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch  Section(rawValue: indexPath.section)!{
        case .CalibrationDataInfoRow:
            switch CalibrationDataInfoRow(rawValue: indexPath.row)! {
                
            case .slopeslope:
                print("slopeslope clicked")
            case .slopeoffset:
                print("slopeoffset clicked")
                
            case .offsetslope:
                print("offsetslope clicked")
            case .offsetoffset:
                print("offsetoffset clicked")
            case .isValidForFooterWithCRCs:
                print("isValidForFooterWithCRCs clicked")
            }
        case .sync:
            print("calibration save clicked")
            let controller = ErrorAlertController("Nope, not implemented!", title: "nope")
            self.present(controller, animated: false)
           
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}



