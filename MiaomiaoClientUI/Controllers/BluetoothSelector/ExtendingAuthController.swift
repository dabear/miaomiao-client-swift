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
        
        
        return 5
        
        
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
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard isExtendedSection(section: indexPath.section) else {
            return source.tableView(tableView, didSelectRowAt: indexPath)
        }
        return
        
    }
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard isExtendedSection(section: indexPath.section) else {
            return source.tableView(source.tableView, cellForRowAt: indexPath)
        }
        
        
        print("dequeueReusableCell called")
        let cell = UITableViewCell() //tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        
        cell.textLabel?.text = "overridden cell with index: \(indexPath.section),\(indexPath.row)"
        
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
    
    
    public weak var source : UITableViewController!
    
    private var searcher : BluetoothSearchManager!
    public init(_ source: UITableViewController) {
        super.init()
        self.source = source
        self.searcher = BluetoothSearchManager(discoverDelegate: self)
        
        
    }
    
    
    
    
    
}
