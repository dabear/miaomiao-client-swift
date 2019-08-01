//
//  ExtendingAuthController.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 26/07/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import UIKit
import MiaomiaoClient

fileprivate var foo : ExtendingAuthController!

// This will only work if original controller keeps a somewhat static amount of sections
public class ExtendingAuthController: NSObject, UITableViewDataSource, UITableViewDelegate, BluetoothSearchDelegate{
    func didDiscoverCompatibleDevice(_ device: CompatibleLibreBluetoothDevice, allCompatibleDevices: [CompatibleLibreBluetoothDevice]) {
        print("ExtendingAuthController was notified of new devices. alldevices:\(allCompatibleDevices.count)")
        
        if discoveredDevices != allCompatibleDevices {
            discoveredDevices = allCompatibleDevices
        }
        
    }
    
    private var discoveredDevices = [CompatibleLibreBluetoothDevice]() {
        didSet{
            let section = getExtendedSection()
            print("will reload section \(section)")
            //new devices detected, so reload the section, thereby repopulating list of devices
            source.tableView.reloadSections(IndexSet(integer: section), with: .automatic)
            
            //
            if let preselected = UserDefaults.standard.preSelectedDevice {
                if discoveredDevices.count == 0  {
                    print("dabear:: discoveredDevices count is 0,")
                    
                } else if let index = discoveredDevices.firstIndex(where: { $0.identifier == preselected.identifier}) {
                    
                    print("dabear:: found preselected device in index \(index), selecting row \(index)")
                    selectRow(row: index)
                    
                } else {
                    
                }
            } else {
                print("dabear:: no preselection")
               
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
        
        
        return discoveredDevices.count
        
        
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
        
        return "Libre Bluetooth Devices\nSelec which LIbre Bridge device you want to connect to"
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
                UserDefaults.standard.preSelectedDevice = nil
            } else {
                if let cell = (cell as? AnnotatedSubtitleCell<CompatibleLibreBluetoothDevice>), let device = cell.annotation {
                    print("Selected device: \(device)")
                    UserDefaults.standard.preSelectedDevice = device
                } else {
                    print("Could not downcastcell, selected device was not retrieved")
                }
            }
        }
        
        print("Selected bluetooth device is now: \(String(describing: UserDefaults.standard.preSelectedDevice))")
        
        
        
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
        if let preselected = UserDefaults.standard.preSelectedDevice,
            let cell = (cell as? AnnotatedSubtitleCell<CompatibleLibreBluetoothDevice>) {
            if cell.annotation == preselected {
                print("dabear:: selecting preselected peripheral cell with id \(preselected)")
                cell.isSelected = true
            }
        }
    }
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard isExtendedSection(section: indexPath.section) else {
            return source.tableView(source.tableView, cellForRowAt: indexPath)
        }
        
        var cell = AnnotatedSubtitleCell<CompatibleLibreBluetoothDevice>(style: .subtitle, reuseIdentifier: nil)
        //tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        
        
        
        if let device = discoveredDevices[safe: indexPath.row] {
            cell.textLabel?.text = "\(device.name) "
            cell.detailTextLabel?.text = "\(device.identifier)"
            cell.textLabel?.numberOfLines = 0;
            cell.textLabel?.lineBreakMode = .byWordWrapping
            cell.tag = 1
            cell.annotation = device
            selectIfannotatedCellMatchesPreSelection(cell)
            print("rendering device image in gui \(device.smallImage) for device \(device.name)")
            if let image = device.smallImage {
                cell.imageView!.image = image
            }
        } else {
            //won't happen
            cell.textLabel?.text = "Unknown device"
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
        
        if let cell = source.tableView.cellForRow(at: path) as? AnnotatedSubtitleCell<CompatibleLibreBluetoothDevice>{
            UserDefaults.standard.preSelectedDevice = cell.annotation
        } else {
            UserDefaults.standard.preSelectedDevice  = nil
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
