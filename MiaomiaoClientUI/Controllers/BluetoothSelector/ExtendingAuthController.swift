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
        
        print("stopping search")
        searcher.disconnectManually()
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
    
    public func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard isExtendedSection(section: section) else {
            return
        }
        //this is exploited as a substitute as we do not have access to viewwillappear
        //static text is selected as standard
        selectListItem(item: 0)
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
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard isExtendedSection(section: indexPath.section) else {
            return source.tableView(source.tableView, cellForRowAt: indexPath)
        }
        
        
        print("dequeueReusableCell called")
        var cell : UITableViewCell
        //tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        
        if indexPath.row == 0 {
            cell = UITableViewCell()
            cell.tag = 1000
            cell.textLabel?.text = "Connect to First available device"
            
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            //cell.textLabel?.text = "Overridden cell with index: \(indexPath.section),\(indexPath.row)"
            //-1 to compensate for the first row which is always static
            if let device = discoveredDevices[safe: indexPath.row - 1] {
                cell.textLabel?.text = "\(device.name) "
                cell.detailTextLabel?.text = "\(device.identifer)"
                cell.textLabel?.numberOfLines = 0;
                cell.textLabel?.lineBreakMode = .byWordWrapping
                cell.tag = 1
                
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
        source = nil
        foo = nil
    }
    
    public func selectListItem(item: Int) {
        source.tableView.selectRow(at: IndexPath(item: item, section: getExtendedSection()), animated: false, scrollPosition: .none)
    }
    
    public weak var source : UITableViewController!
    
    private var searcher : BluetoothSearchManager!
    public init(_ source: UITableViewController) {
        super.init()
        self.source = source
        self.searcher = BluetoothSearchManager(discoverDelegate: self)
        
       
        
        
    }
    
    
    
    
    
}
