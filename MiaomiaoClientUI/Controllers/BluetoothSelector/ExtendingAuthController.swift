//
//  ExtendingAuthController.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 26/07/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import UIKit


fileprivate var foo : ExtendingAuthController!

// This will only work if original controller keeps a somewhat static amount of sections
public class ExtendingAuthController: NSObject, UITableViewDataSource, UITableViewDelegate, BluetoothSearchDelegate{
    func didDiscoverCompatibleDevice(_ device: CompatibleBluetoothDevice, allCompatibleDevices: [CompatibleBluetoothDevice]) {
        print("ExtendingAuthController was notified of new devices. alldevices:\(allCompatibleDevices.count)")
        
        if discoveredDevices != allCompatibleDevices {
            discoveredDevices = allCompatibleDevices
        }
        
    }
    
    private var discoveredDevices = [CompatibleBluetoothDevice]() {
        didSet{
            var section = getExtendedSection()
            print("will reload section \(section)")
            //new devices detected, so reload the section, thereby repopulating list of devices
            source.tableView.reloadSections(IndexSet(integer: section), with: .automatic)
            
            //
            if let preselected = UserDefaults.standard.selectedBluetoothDeviceIdentifer {
                if discoveredDevices.count == 0  {
                    print("dabear:: discoveredDevices count is 0, selecting first row")
                    selectRow(row: 0)
                } else if let index = discoveredDevices.firstIndex(where: { $0.identifer == preselected}) {
                    let row = index + 1
                    print("dabear:: found preselected device in index \(index), selecting row \(row)")
                    selectRow(row: row)
                    
                } else {
                    print("dabear:: preselected device was not discovered, selecting first row")
                    selectRow(row: 0)
                }
            } else {
                print("dabear:: no preselection, selecting first row")
                selectRow(row: 0)
            }
            
        }
            
        
    }
    
    
    private func isExtendedSection(section: Int) -> Bool{
        // section is zero-index, compensate
        return section > (source.numberOfSections(in: source!.tableView)-1)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        print("ExtendingAuthController numberOfRowsInSection: \(section)")
        
        guard isExtendedSection(section: section) else {
            return source.tableView(tableView, numberOfRowsInSection: section)
        }
        
        //first row is always present, connect to first available device
        return 1 + discoveredDevices.count
        
        
    }
    
    public func getExtendedSection() -> Int {
        // -1 + 1 (cancels out)
        return source.numberOfSections(in: source.tableView)
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        
        print("original numberOfSections was retrieved, multiplying")
        let res = source.numberOfSections(in: tableView) + 1
        
        print("numberOfSections result is: \(res)")
        return res
        
        
    }
    
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard isExtendedSection(section: indexPath.section) else {
            return source.tableView(tableView, shouldHighlightRowAt: indexPath)
            
        }
        
        return true
        
        
        
    }
    
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard isExtendedSection(section: section) else {
            return nil // source.tableView(tableView, titleForHeaderInSection: section)
        }
        
        return "Libre Bluetooth Devices\nSelect if you want to connect to the first available or a specific device"
    }
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard isExtendedSection(section: section) else {
            return nil // source.tableView(tableView, titleForFooterInSection: section)
        }
        
        return "Devices detected: \(discoveredDevices.count)"
    }
    
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard isExtendedSection(section: indexPath.section) else {
            return source.tableView(tableView, didSelectRowAt: indexPath)
        }
        
     
        
        
        if let cell = tableView.cellForRow(at: indexPath) {
            if cell.tag == 1000 {
                //static text
                UserDefaults.standard.selectedBluetoothDeviceIdentifer = nil
            } else {
                if let cell = (cell as? AnnotatedSubtitleCell<CompatibleBluetoothDevice>), let device = cell.annotation {
                    print("Selected device: \(device)")
                    UserDefaults.standard.selectedBluetoothDeviceIdentifer = device.identifer
                } else {
                    print("Could not downcastcell, selected device was not retrieved")
                }
            }
        }
        
        print("Selected bluetooth device is now: \(String(describing: UserDefaults.standard.selectedBluetoothDeviceIdentifer))")
        
        
        
        return
        
    }
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        /*guard isExtendedSection(section: section) else {
            return source.tableView(tableView, heightForHeaderInSection: section)
        }*/
        
        return UITableViewAutomaticDimension
    }
    
   
    
    public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard isExtendedSection(section: section) else {
            return
        }
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.numberOfLines = 0
            
            header.textLabel?.lineBreakMode = .byWordWrapping
            
        }
    }
    

    
    private func selectIfannotatedCellMatchesPreSelection(_ cell: UITableViewCell){
        //don't override users choice
        print("dabear:: selectIfannotatedCellMatchesPreSelection")
        if let preselected = UserDefaults.standard.selectedBluetoothDeviceIdentifer,
            let cell = (cell as? AnnotatedSubtitleCell<CompatibleBluetoothDevice>) {
            if cell.annotation?.identifer == preselected {
                print("dabear:: selecting preselected peripheral cell with id \(preselected)")
                cell.isSelected = true
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard isExtendedSection(section: indexPath.section) else {
            return source.tableView(source.tableView, cellForRowAt: indexPath)
        }
        
        var cell : UITableViewCell
        //tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        
        if indexPath.row == 0 {
            cell = UITableViewCell()
            cell.tag = 1000
            cell.textLabel?.text = "Connect to First available device"
            if discoveredDevices.count == 0 {
                print("dabear:: discovered devices is 0, selecting first cell")
                cell.isSelected = true
            }
        } else {
            //cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell = AnnotatedSubtitleCell<CompatibleBluetoothDevice>()
            //cell.textLabel?.text = "Overridden cell with index: \(indexPath.section),\(indexPath.row)"
            //-1 to compensate for the first row which is always static
            if let device = discoveredDevices[safe: indexPath.row - 1] {
                cell.textLabel?.text = "\(device.name) "
                cell.detailTextLabel?.text = "\(device.identifer)"
                cell.textLabel?.numberOfLines = 0;
                cell.textLabel?.lineBreakMode = .byWordWrapping
                cell.tag = 1
                (cell as! AnnotatedSubtitleCell<CompatibleBluetoothDevice>).annotation = device
                selectIfannotatedCellMatchesPreSelection(cell)
                if let image = device.smallImage {
                    cell.imageView!.image = image
                }
            } else {
                cell.textLabel?.text = "unknown device"
            }
            
        }
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.orange
        cell.selectedBackgroundView = backgroundView
        
        return cell
        
        
        
        
    }
    
    
    public static func addExtendedSection(source: UITableViewController){
        print("adding bluetooth selector")
        foo = ExtendingAuthController(source)
        
        source.tableView.dataSource = foo
        source.tableView.delegate = foo
        
        source.tableView.reloadData()
        
        
    }
    public static func destroyExtension(){
        foo.destroyExtension()
    }
    public func destroyExtension() {
        
        print("stopping search")
        searcher.disconnectManually()
        
        source = nil
        foo = nil
        searcher = nil
    }
    
    public func selectRow(row: Int) {
        let section = getExtendedSection()
        let path = IndexPath(row: row, section: section)
        source.tableView.selectRow(at: path, animated: false, scrollPosition: .none)
        
        if let cell = source.tableView.cellForRow(at: path) as? AnnotatedSubtitleCell<CompatibleBluetoothDevice>{
            UserDefaults.standard.selectedBluetoothDeviceIdentifer = cell.annotation?.identifer
        } else {
            UserDefaults.standard.selectedBluetoothDeviceIdentifer  = nil
        }
    }
    
    public weak var source : UITableViewController!
    
    private var searcher : BluetoothSearchManager!
    public init(_ source: UITableViewController) {
        super.init()
        self.source = source
        self.searcher = BluetoothSearchManager(discoverDelegate: self)
        
       
        
        
    }
    
    
    
    
    
}
