//
//  MiaomiaoClient.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 25/02/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import os.log

public final class MiaoMiaoProxy: MiaoMiaoManagerDelegate {
    public private(set) var lastConnected : Date?
    
    
    
    private var proxy : MiaoMiaoManager?
    public init(){
        lastConnected = nil
        os_log("dabear: miaomiaomanager will be created now")
        proxy = MiaoMiaoManager()
        proxy?.delegate = self
        //proxy?.connect()
    }
    
    public var connectionState : String {
        return proxy?.state.rawValue ?? "n/a"
        
    }
    
    public var sensorState : String {
        return proxy?.sensorData?.state.description ?? "n/a"
    }
    
    public var firmwareVersion : String {
        return proxy?.miaoMiao?.firmware ?? "n/a"
    }
    
    public var hardwareVersion : String {
        return proxy?.miaoMiao?.hardware ?? "n/a"
    }
    
    public var battery : String {
        if let bat = proxy?.miaoMiao?.battery {
            return "\(bat)%"
        }
        return "n/a"
    }
    
    public func disconnect(){
       
        proxy?.disconnectManually()
        proxy?.delegate = nil
        proxy = nil
    }
    
    func autoconnect(){
        guard let proxy = proxy else {
            os_log("dabear: could not do autoconnect, proxy was nil")
            return
        }
        
        // force trying to reconnect every time a we detect
        // a disconnected state while fetching
        switch (proxy.state) {
        case .Unassigned:
            break
            //proxy.scanForMiaoMiao()
        case .Scanning:
            break
        case .Connected, .Connecting, .Notifying:
            break
        case .Disconnected, .DisconnectingDueToButtonPress:
            proxy.connect()
        }
    }
    
    public func miaoMiaoManagerPeripheralStateChanged(_ state: MiaoMiaoManagerState) {
        switch state {
        case .Connected:
            lastConnected = Date()
        default:
            break
        }
        return
    }
    
    public func miaoMiaoManagerReceivedMessage(_ messageIdentifier: UInt16, txFlags: UInt8, payloadData: Data) {
        guard let packet = MiaoMiaoResponseState.init(rawValue: txFlags) else {
            // Incomplete package?
            // this would only happen if delegate is called manually with an unknown txFlags value
            // this was the case for readouts that were not yet complete
            // but that was commented out in MiaoMiaoManager.swift, see comment there:
            // "dabear-edit: don't notify on incomplete readouts"
            os_log("incomplete package or unknown response state")
            return
        }
        
        switch packet {
        case .newSensor:
            //invalidate any saved calibration parameters
            break
        case .noSensor:
            break
        //consider notifying user here that sensor is not found
        default:
            //we don't care about the rest!
            break
        }
        
        return
        
    }
    
    public func miaoMiaoManagerDidUpdateSensorAndMiaoMiao(sensorData: SensorData, miaoMiao: MiaoMiao) {
        if sensorData.hasValidCRCs {
            os_log("got sensordata with valid crcs")
            
        } else {
            os_log("dit not get sensordata with valid crcs")
        }
        return
    }
    
    deinit {
        
        os_log("dabear:: miaomiaoproxy deinit called2")
        
        
        //cleanup any references to events to this class
        disconnect()
        
        
    }
    
    
}
