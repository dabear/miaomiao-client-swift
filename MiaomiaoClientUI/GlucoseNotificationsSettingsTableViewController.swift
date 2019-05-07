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


public class GlucoseNotificationsSettingsTableViewController: UITableViewController  {
   
    
  
    private var glucoseUnit : HKUnit
    

    
    public init(glucoseUnit: HKUnit) {
        self.glucoseUnit = glucoseUnit
        
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
    }
    
   
    private enum NotificationsSettingsRow : Int {
        case always
        case unit
        static let count = 2
    }
    
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        //dynamic number of schedules + sync row
        return 1
        
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return NotificationsSettingsRow.count
        
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        

            switch NotificationsSettingsRow(rawValue: indexPath.row)! {
            case .always:
                let cell = tableView.dequeueReusableCell(withIdentifier: AlarmTimeInputRangeCell.className, for: indexPath) as!  AlarmTimeInputRangeCell
                return cell
            case .unit:
                let cell = tableView.dequeueReusableCell(withIdentifier: AlarmTimeInputRangeCell.className, for: indexPath) as!  AlarmTimeInputRangeCell
                
                return cell
            
        }
    }
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return LocalizedString("Notification settings", comment: "The title text for the Notification settings")
            
       
    }
    
    public override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return nil
        
    }
    
    public override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch NotificationsSettingsRow(rawValue: indexPath.row)! {
        case .always:
            print("selected always row")
            break
        case .unit:
            print("selected unit row")
            break
            
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}



