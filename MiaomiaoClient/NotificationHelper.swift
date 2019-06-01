//
//  NotificationHelper.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 30/05/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import UserNotifications
import HealthKit
import LoopKit

class NotificationHelper {
    
    private static var glucoseFormatterMgdl: QuantityFormatter = {
        let formatter = QuantityFormatter()
        formatter.setPreferredNumberFormatter(for: HKUnit.milligramsPerDeciliter)
        return formatter
    }()
    
    private static var glucoseFormatterMmol: QuantityFormatter = {
        let formatter = QuantityFormatter()
        formatter.setPreferredNumberFormatter(for: HKUnit.millimolesPerLiter)
        return formatter
    }()
    
    private static var glucoseNotifyCalledCount = 0
    public static func sendGlucoseNotitifcationIfNeeded(glucose: LibreGlucose, oldValue: LibreGlucose?){
        glucoseNotifyCalledCount &+= 1
        
        
        let alarmIsActive = false
        
        let shouldSendGlucoseAlternatingTimes = glucoseNotifyCalledCount != 0 && UserDefaults.standard.mmNotifyEveryXTimes != 0
        
        let shouldSend = UserDefaults.standard.mmAlwaysDisplayGlucose || (shouldSendGlucoseAlternatingTimes && glucoseNotifyCalledCount % UserDefaults.standard.mmNotifyEveryXTimes == 0)
        
        if shouldSend || alarmIsActive {
            sendGlucoseNotitifcation(glucose: glucose, oldValue: oldValue)
        } else {
            NSLog("dabear:: not sending glucose, shouldSend and alarmIsActive was false")
            return
        }
        
    }
    
    
    static private func sendGlucoseNotitifcation(glucose: LibreGlucose, oldValue: LibreGlucose?){
        
        
        guard let glucoseUnit = UserDefaults.standard.mmGlucoseUnit, glucoseUnit == HKUnit.milligramsPerDeciliter || glucoseUnit == HKUnit.millimolesPerLiter else {
            NSLog("dabear:: glucose unit was not recognized, aborting notification")
            return
        }
        // TODO: handle oldValue if present
        // TODO: handle alarm
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if #available(iOSApplicationExtension 12.0, *) {
                guard (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional) else {
                    NSLog("dabear:: not sending glucose, authorization denied")
                    return
                    
                }
            } else {
                // Fallback on earlier versions
                guard (settings.authorizationStatus == .authorized ) else {
                    NSLog("dabear:: not sending glucose, authorization denied")
                    return
                    
                }
            }
            NSLog("dabear:: sending glucose notification")
            
            
            guard glucoseUnit == HKUnit.milligramsPerDeciliter || glucoseUnit == HKUnit.millimolesPerLiter else {
                NSLog("dabear:: glucose unit was not recognized, aborting notification")
                return
            }
            
            guard let formatted = (glucoseUnit == HKUnit.milligramsPerDeciliter ? glucoseFormatterMgdl : glucoseFormatterMmol).string(from: glucose.quantity, for: glucoseUnit) else {
                NSLog("dabear:: glucose unit formatter unsuccessful, aborting notification")
                return
            }
                
            let content = UNMutableNotificationContent()
            content.title = "New Reading \(formatted)"
            content.body = "Glucose: \(formatted)"
            if let trend = glucose.trendType?.localizedDescription {
                content.body += ", \(trend)"
            }
            if let oldValue = oldValue {
                
                
                //these are just calculations so I can use the convenience of the glucoseformatter
                let diff = glucose.glucoseDouble - oldValue.glucoseDouble
                let asObj = LibreGlucose(unsmoothedGlucose: diff, glucoseDouble: diff, trend: 0, timestamp: Date(), collector: nil)
                
                let formattedDiff = (glucoseUnit == HKUnit.milligramsPerDeciliter ? glucoseFormatterMgdl : glucoseFormatterMmol).string(from: asObj.quantity, for: glucoseUnit)
                
                
            }
            
            //content.sound = UNNotificationSound.
            let request = UNNotificationRequest(identifier: "no.bjorninge.miaomiao.glucose-notification", content: content, trigger: nil)
            
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    NSLog("dabear:: unable to add glucose notification: \(error.localizedDescription)")
                }
            }
            
        }
    }
    
    
    public static func sendSensorNotDetectedNotificationIfNeeded(noSensor: Bool) {
        guard UserDefaults.standard.mmAlertNoSensorDetected  && noSensor else {
            NSLog("not sending noSensorDetected notification")
            return
        }
        
        sendSensorNotDetectedNotification()
        
    }
    
    private static func sendSensorNotDetectedNotification() {
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if #available(iOSApplicationExtension 12.0, *) {
                guard (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional) else {
                    NSLog("dabear:: not sending noSensorDetected authorization denied")
                    return
                    
                }
            } else {
                // Fallback on earlier versions
                guard (settings.authorizationStatus == .authorized ) else {
                    NSLog("dabear:: not sending noSensorDetected, authorization denied")
                    return
                    
                }
            }
            NSLog("dabear:: sending noSensorDetected")
            
            
            
            
            let content = UNMutableNotificationContent()
            content.title = "No Sensor Detected"
            content.body = "This might be an intermittent problem, but please check that your miaomiao is tightly secured over your sensor"
            
            
            
            
            //content.sound = UNNotificationSound.
            let request = UNNotificationRequest(identifier: "no.bjorninge.miaomiao.nosensordetected-notification", content: content, trigger: nil)
            
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    NSLog("dabear:: unable to add no sensordetected-notification: \(error.localizedDescription)")
                }
            }
            
        }
    }
    
    
    
    
    
    public static func sendSensorChangeNotificationIfNeeded(hasChanged: Bool) {
        guard UserDefaults.standard.mmAlertNewSensorDetected && hasChanged else {
            NSLog("not sending sendSensorChange notification ")
            return
        }
        sendSensorChangeNotification()
        
    }
    
    private static func sendSensorChangeNotification() {
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if #available(iOSApplicationExtension 12.0, *) {
                guard (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional) else {
                    NSLog("dabear:: not sending sensorChangeNotification, authorization denied")
                    return
                    
                }
            } else {
                // Fallback on earlier versions
                guard (settings.authorizationStatus == .authorized ) else {
                    NSLog("dabear:: not sending sensorChangeNotification, authorization denied")
                    return
                    
                }
            }
            NSLog("dabear:: sending sensorChangeNotification")
            
            
            
            
            let content = UNMutableNotificationContent()
            content.title = "New Sensor Detected"
            content.body = "Please wait up to 30 minutes before glucose readings are available!"
            
            
            
            
            //content.sound = UNNotificationSound.
            let request = UNNotificationRequest(identifier: "no.bjorninge.miaomiao.sensorchange-notification", content: content, trigger: nil)
            
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    NSLog("dabear:: unable to add sensorChange notification: \(error.localizedDescription)")
                }
            }
            
        }
    }
    
    
    
    
    public static func sendInvalidSensorNotificationIfNeeded(sensorData: SensorData) {
        let isValid = sensorData.isLikelyLibre1 && (sensorData.state == .starting || sensorData.state == .ready)
        
        guard UserDefaults.standard.mmAlertInvalidSensorDetected && !isValid else{
            NSLog("not sending invalidSensorDetected notification")
            return
        }
        
        sendInvalidSensorNotification(sensorData: sensorData)
    }
    
    
    
    
    
    private static func sendInvalidSensorNotification(sensorData: SensorData) {
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if #available(iOSApplicationExtension 12.0, *) {
                guard (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional) else {
                    NSLog("dabear:: not sending InvalidSensorNotification, authorization denied")
                    return
                    
                }
            } else {
                // Fallback on earlier versions
                guard (settings.authorizationStatus == .authorized ) else {
                    NSLog("dabear:: not sending InvalidSensorNotification, authorization denied")
                    return
                    
                }
            }
            NSLog("dabear:: sending InvalidSensorNotification")
            
            
            
            
            let content = UNMutableNotificationContent()
            content.title = "Invalid Sensor Detected"
            
            if !sensorData.isLikelyLibre1 {
                content.body = "Detected sensor seems not to be a libre 1 sensor!"
            } else if !(sensorData.state == .starting || sensorData.state == .ready){
                content.body = "Detected sensor is invalid: \(sensorData.state.description)"
            }
           
            
            content.sound = .default()
            
            //content.sound = UNNotificationSound.
            let request = UNNotificationRequest(identifier: "no.bjorninge.miaomiao.invalidsensor-notification", content: content, trigger: nil)
            
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    NSLog("dabear:: unable to add invalidsensor notification: \(error.localizedDescription)")
                }
            }
            
        }
    }
    
    
    
    private static var lastBatteryWarning : Date?
    public static func sendLowBatteryNotificationIfNeeded(device: MiaoMiao) {
        
        guard UserDefaults.standard.mmAlertLowBatteryWarning else {
            NSLog("mmAlertLowBatteryWarning toggle was not enabled, not sending low notification")
            return
        }
        
        guard device.battery <= 30 else {
            NSLog("device battery is \(device.batteryString), not sending low notification")
            return
        }
        
        let now  = Date()
        //only once per mins minute
        let mins =  60.0 * 120
        if let earlier = lastBatteryWarning {
            let earlierplus = earlier.addingTimeInterval(mins)
            if earlierplus < now {
                sendLowBatteryNotification(batteryPercentage: device.batteryString)
                lastBatteryWarning = now
            } else {
                NSLog("Device battery is running low, but lastBatteryWarning Notification was sent less than 45 minutes ago, aborting. earlierplus: \(earlierplus), now: \(now)")
            }
        } else {
            sendLowBatteryNotification(batteryPercentage: device.batteryString)
            lastBatteryWarning = now
        }
        
        
    }
    
    private static func sendLowBatteryNotification(batteryPercentage: String){
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if #available(iOSApplicationExtension 12.0, *) {
                guard (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional) else {
                    NSLog("dabear:: not sending LowBattery notification, authorization denied")
                    return
                    
                }
            } else {
                // Fallback on earlier versions
                guard (settings.authorizationStatus == .authorized ) else {
                    NSLog("dabear:: not sending LowBattery notification authorization denied")
                    return
                    
                }
            }
            NSLog("dabear:: sending LowBattery notification")
            
            
            
            
            let content = UNMutableNotificationContent()
            content.title = "Low Battery"
            content.body = "Battery is running low (\(batteryPercentage)), consider charging your miaomiao device as soon as possible"
            
            content.sound = .default()
            
            //content.sound = UNNotificationSound.
            let request = UNNotificationRequest(identifier: "no.bjorninge.miaomiao.lowbattery-notification", content: content, trigger: nil)
            
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    NSLog("dabear:: unable to add lowbattery notification: \(error.localizedDescription)")
                }
            }
            
        }
    }
    
    
    private static var lastSensorExpireAlert : Date?
    public static func sendSensorExpireAlertIfNeeded(sensorData: SensorData) {
        
        guard UserDefaults.standard.mmAlertWillSoonExpire else {
            NSLog("mmAlertWillSoonExpire toggle was not enabled, not sending expiresoon alarm")
            return
        }
        
        guard sensorData.minutesSinceStart >= 19440 else {
            NSLog("sensor start was less than 13,5 days in the past, not sending notification: \(sensorData.minutesSinceStart) minutes / \(sensorData.humanReadableSensorAge)")
            return
        }
        
       
        let now  = Date()
        //only once per 6 hours
        let min45 = 60.0  * 60 * 6
        if let earlier = lastSensorExpireAlert {
            if earlier.addingTimeInterval(min45) < now {
                sendSensorExpireAlert(sensorData: sensorData)
                lastSensorExpireAlert = now
            } else {
                NSLog("Sensor is soon expiring, but lastSensorExpireAlert was sent less than 6 hours ago, so aborting")
            }
        } else {
            sendSensorExpireAlert(sensorData: sensorData)
            lastSensorExpireAlert = now
        }
        
        
    }
    
    private static func sendSensorExpireAlert(sensorData: SensorData){
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if #available(iOSApplicationExtension 12.0, *) {
                guard (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional) else {
                    NSLog("dabear:: not sending SensorExpireAlert, authorization denied")
                    return
                    
                }
            } else {
                // Fallback on earlier versions
                guard (settings.authorizationStatus == .authorized ) else {
                    NSLog("dabear:: not sending SensorExpireAlert, authorization denied")
                    return
                    
                }
            }
            NSLog("dabear:: sending SensorExpireAlert notification")
            
            
            
            
            let content = UNMutableNotificationContent()
            content.title = "Sensor Ending Soon"
            content.body = "Current Sensor is Ending soon! Sensor Age: \(sensorData.humanReadableSensorAge)"
            
            //content.sound = .default()
            
            //content.sound = UNNotificationSound.
            let request = UNNotificationRequest(identifier: "no.bjorninge.miaomiao.SensorExpire-notification", content: content, trigger: nil)
            
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    NSLog("dabear:: unable to add SensorExpire notification: \(error.localizedDescription)")
                }
            }
            
        }
    }
    
    
    
    
}
