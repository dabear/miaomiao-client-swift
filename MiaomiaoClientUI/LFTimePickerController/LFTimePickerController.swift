//
//  LFTimePickerController.swift
//  LFTimePicker
//
//  Created by Lucas Farah on 6/1/16.
//  Copyright © 2016 Lucas Farah. All rights reserved.
//
//  Heavily modified by dabear 2019

import UIKit

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}


//MARK: - LFTimePickerDelegate

/**
 Used to return information after user taps the "Save" button
 - requires: func didPickTime(start: String, end: String)
 */

public protocol LFTimePickerDelegate: class {
    
    /**
     Called after pressing save. Used so the user can call their server to check user's information.
     - returns: start and end times in hh:mm aa
     */
    func didPickTime(_ start: String, end: String, startComponents: DateComponents?, endComponents: DateComponents?)
}

/**
 ViewController that handles the Time Picking
 - customizations: timeType, startTimes, endTimes
 */
open class LFTimePickerController: UIViewController {
    
    // MARK: - Variables
    open weak var delegate: LFTimePickerDelegate?
    lazy var startTimes: [DateComponents?] = defaultTimeArray()
    lazy var endTimes: [DateComponents?] = defaultTimeArray()
    
    var leftTimeTable = DateComponentUITableView()
    var rightTimeTable = DateComponentUITableView()
    var lblLeftTimeSelected  = UILabel()
    var lblRightTimeSelected = UILabel()
    var detailBackgroundView = UIView()
    var lblAMPM = UILabel()
    var lblAMPM2 = UILabel()
    var firstRowIndex = 0
    var lastSelectedLeft = "00:00"
    var lastSelectedRight = "00:00"
    
    
    var lastSelectedComponentLeft : DateComponents? = nil
    var lastSelectedComponentRight : DateComponents? = nil
    
    /// Hour Format: 12h (default) or 24h format
    //open var timeType = TimeType.hour12
    
    open class var wants12hourClock: Bool {
        
        
        let wantsAMPM = DateFormatter.dateFormat(fromTemplate: "j", options:0, locale:NSLocale.current)!.contains("a")
        return wantsAMPM
    }
    
    open var backgroundColor = UIColor(red: 255 / 255, green: 128 / 255, blue: 0, alpha: 1)
    //open var backgroundColor = UIColor.white
    open var titleText: String = "Schedule"
    open var saveText: String = "Save"
    open var cancelText: String = "Cancel"
    
    // MARK: - Methods
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .all
        }
    }
    
    /// Used to load all the setup methods
    override open func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        
    }
    
    
    
    
    var alreadyLayout = false
    open override func viewWillLayoutSubviews() {
        
        if !alreadyLayout {
            self.title = titleText
            self.view.backgroundColor = backgroundColor
            
            setupTables()
            setupDetailView()
            setupNavigationBar()
            
            
            alreadyLayout = true
        }
    }
    
    // MARK: Setup
    fileprivate func setupNavigationBar() {
        
        let saveButton = UIBarButtonItem(title: saveText, style: .plain, target: self, action: #selector(butSave))
        saveButton.tintColor = .red
        
        let cancelButton = UIBarButtonItem(title: cancelText, style: .plain, target: self, action: #selector(butCancel))
        cancelButton.tintColor = .red
        
        self.navigationItem.rightBarButtonItem = saveButton
        self.navigationItem.leftBarButtonItem = cancelButton
    }
    
    fileprivate func setupTables() {
        
        let frame1 = CGRect(x: 30, y: 0, width: 160, height: self.view.bounds.height)
        leftTimeTable = DateComponentUITableView(frame: frame1, style: .plain)
        
        let frame2 = CGRect(x: self.view.frame.width - 160, y: 0, width: 160, height: self.view.bounds.height)
        
        rightTimeTable = DateComponentUITableView(frame: frame2, style: .plain)
        
        leftTimeTable.separatorStyle = .none
        rightTimeTable.separatorStyle = .none
        
        leftTimeTable.dataSource = self
        leftTimeTable.delegate = self
        rightTimeTable.dataSource = self
        rightTimeTable.delegate = self
        
        leftTimeTable.register(DateComponentUITableViewCell.self, forCellReuseIdentifier: "cell")
        rightTimeTable.register(DateComponentUITableViewCell.self, forCellReuseIdentifier: "cell")
        
        leftTimeTable.backgroundColor = .clear
        rightTimeTable.backgroundColor = .clear
        
        leftTimeTable.showsVerticalScrollIndicator = false
        rightTimeTable.showsVerticalScrollIndicator = false
        
        leftTimeTable.allowsSelection = false
        rightTimeTable.allowsSelection = false
        
        view.addSubview(leftTimeTable)
        view.addSubview(rightTimeTable)
        
        self.view.sendSubview(toBack: leftTimeTable)
        self.view.sendSubview(toBack: rightTimeTable)
    }
    
    fileprivate func setupDetailView() {
        
        detailBackgroundView = UIView(frame: CGRect(x: 0, y: (self.view.bounds.height / 5) * 2, width: self.view.bounds.width, height: self.view.bounds.height / 6))
        detailBackgroundView.backgroundColor = .white
        
        lblLeftTimeSelected = UILabel(frame: CGRect(x: 20, y: detailBackgroundView.frame.height / 2, width: 300, height: detailBackgroundView.frame.height))
        lblLeftTimeSelected.center = CGPoint(x: 100, y: detailBackgroundView.frame.height / 2)
        
        lblLeftTimeSelected.font = UIFont.systemFont(ofSize: 40)
        lblLeftTimeSelected.text = LFTimePickerController.wants12hourClock ? "12:00 AM" : "00:00"
        if let first = startTimes[safe: 9] {
            lastSelectedComponentLeft = first
        } else {
            lastSelectedComponentLeft = nil
        }
        
        lblLeftTimeSelected.textAlignment = .center
        
        lblRightTimeSelected = UILabel(frame: CGRect(x: detailBackgroundView.frame.width / 7 * 6 + 20, y: detailBackgroundView.frame.height / 2, width: 300, height: detailBackgroundView.frame.height))
        lblRightTimeSelected.center = CGPoint(x: detailBackgroundView.bounds.width - 100, y: detailBackgroundView.frame.height / 2)
        
        lblRightTimeSelected.font = UIFont.systemFont(ofSize: 40)
        lblRightTimeSelected.text = LFTimePickerController.wants12hourClock ? "12:00 AM" : "00:00"
        if let first = endTimes[safe: 9] {
            lastSelectedComponentRight = first
        } else {
            lastSelectedComponentRight = nil
        }
        
        lblRightTimeSelected.textAlignment = .center
        
        detailBackgroundView.addSubview(lblLeftTimeSelected)
        detailBackgroundView.addSubview(lblRightTimeSelected)
        
        let lblTo = UILabel(frame: CGRect(x: (detailBackgroundView.frame.width / 2)-15, y: detailBackgroundView.frame.height / 2, width: 30, height: 20))
        lblTo.text = "TO"
        
        detailBackgroundView.addSubview(lblTo)
        
        self.view.addSubview(detailBackgroundView)
    }
    

    
    func defaultTimeArray() -> [DateComponents?] {
        
        var arr  = [DateComponents?]()
        
        
        for _ in 0...8 {
            arr.append(nil)
        }
        
        for hr in 0...23 {
            for min in 0 ..< 2 {
                
                var components = DateComponents()
                components.hour = hr
                components.minute = min == 1 ? 30 : 0
                arr.append(components)
            }
            
        }
        
        for _ in 0...8 {
            arr.append(nil)
        }
        
        return arr
    }

    
    // MARK: Button Methods
    @objc fileprivate func butSave() {
        
        let time = self.lblLeftTimeSelected.text!
        let time2 = self.lblRightTimeSelected.text!
        
        delegate?.didPickTime(time, end: time2, startComponents: lastSelectedComponentLeft, endComponents: lastSelectedComponentRight)
       
        
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @objc fileprivate func butCancel() {
        
        _ = self.navigationController?.popViewController(animated: true)
    }
    
   
}

//MARK: - UITableViewDataSource
extension LFTimePickerController: UITableViewDataSource {
    
    /// Setup of Time cells
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return startTimes.count
        /*
        if tableView == leftTimeTable {
            
            return startTimes.count
        } else if tableView == rightTimeTable {
            
            return endTimes.count
        }
        return 0*/
    }
    
    // Setup of Time cells
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! DateComponentUITableViewCell!
        
        cell?.wantsAMPM = LFTimePickerController.wants12hourClock
        
        // setup cell without force unwrapping it
        var arr: [DateComponents?] = []
        if tableView == leftTimeTable {
            
            arr = startTimes
        } else if tableView == rightTimeTable {
            
            arr = endTimes
        }
        
       cell?.components = arr[indexPath.row]
       
        
        cell?.textLabel?.textColor = .white
        
        cell?.backgroundColor = .clear
        return cell!
    }
}


//MARK: - UITableViewDelegate
extension LFTimePickerController: UITableViewDelegate {
    
    /// Used to change AM from PM
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if leftTimeTable.visibleCells.count > 8 {
            
           
            
            
            let text = leftTimeTable.visibleCells[8] as! DateComponentUITableViewCell
            if text.textLabel?.text != "" {
                self.lblLeftTimeSelected.text = text.textLabel?.text
                lastSelectedLeft = (text.textLabel?.text!)!
                lastSelectedComponentLeft = text.components
                
            } else {
                self.lblLeftTimeSelected.text = lastSelectedLeft
                
            }
            
        } else {
            self.lblLeftTimeSelected.text = LFTimePickerController.wants12hourClock ? "12:00 AM" : "00:00"
            if let first = startTimes[safe: 9]{
                lastSelectedComponentLeft = first
            } else {
                lastSelectedComponentLeft = nil
            }
            
        }
        
        if rightTimeTable.visibleCells.count > 8 {
            
            let text2 = rightTimeTable.visibleCells[8] as! DateComponentUITableViewCell
            
            if text2.textLabel?.text != "" {
                self.lblRightTimeSelected.text = text2.textLabel?.text
                lastSelectedRight = (text2.textLabel?.text!)!
                lastSelectedComponentRight = text2.components
            } else {
                self.lblRightTimeSelected.text = lastSelectedRight
            }
        } else {
            lblRightTimeSelected.text = LFTimePickerController.wants12hourClock ? "12:00 AM" : "00:00"
            
            if let first = endTimes[safe: 9] {
                lastSelectedComponentRight = first
            } else {
                lastSelectedComponentRight = nil
            }
        }
        
        
        
        
        if let rowIndex = leftTimeTable.indexPathsForVisibleRows?.first?.row {
            firstRowIndex = rowIndex
        }
        
        /*if rightTimeTable.visibleCells.count < leftTimeTable.visibleCells.count {
            let indexPath = IndexPath(row: firstRowIndex+3, section: 0)
            rightTimeTable.scrollToRow(at: indexPath, at: .top, animated: true)
        }*/
        
        if let rowIndex = rightTimeTable.indexPathsForVisibleRows?.first?.row {
            firstRowIndex = rowIndex
        }
        
        
    }
}

