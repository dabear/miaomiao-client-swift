//
//  Calibration.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 05/03/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import LoopKit

private let LibreCalibrationLabel =  "https://LibreCalibrationLabel.doesnot.exist.com"
private let LibreCalibrationUrl = URL(string: LibreCalibrationLabel)!
private let LibreUsername = "LibreUsername"


extension KeychainManager {
    func setLibreCalibrationData(_ calibrationData: DerivedAlgorithmParameters) throws {
        let credentials: InternetCredentials?
        credentials = InternetCredentials(username: LibreUsername, password: serializeAlgorithmParameters(calibrationData), url: LibreCalibrationUrl)
        NSLog("dabear: Setting calibrationdata to \(String(describing: calibrationData))")
        try replaceInternetCredentials(credentials, forLabel: LibreCalibrationLabel)
    }
    
    func getLibreCalibrationData() -> DerivedAlgorithmParameters? {
        do { // Silence all errors and return nil
            let credentials = try getInternetCredentials(label: LibreCalibrationLabel)
            NSLog("dabear:: credentials.password was retrieved: \(credentials.password)")
            return deserializeAlgorithmParameters(text: credentials.password)
        } catch {
            NSLog("dabear:: unable to retrieve calibrationdata:")
            return nil
        }
    }
}

func calibrateSensor(accessToken: String, site:String, sensordata: SensorData,  callback: @escaping (DerivedAlgorithmParameters?) -> Void) {
    
    let libreOOPClient = LibreOOPClient(accessToken: accessToken, site: site)
    libreOOPClient.uploadCalibration(reading: sensordata.bytes, {calibrationResult, success, errormessage in
        guard success, let calibrationResult = calibrationResult else {
            
            NSLog("remote: upload calibration failed! \(errormessage)")
            callback(nil)
            return
        }
        NSLog("uuid received: " + calibrationResult.uuid)
        libreOOPClient.getCalibrationStatusIntervalled(uuid: calibrationResult.uuid, {success, errormessage, parameters in
            NSLog("GetStatusIntervalled returned with success?: \(success), error: \(errormessage), response: \(parameters?.description)")
            // check for data integrity
            guard success else {
                callback(nil)
                return
            }
            if let parameters = parameters,
                sensordata.footerCrc == UInt16(parameters.isValidForFooterWithReverseCRCs).byteSwapped {
                callback(parameters)
                return
            }
            NSLog("sensor parameters or crc incorrect, returning nil")
            callback(nil)
            return

        })
    })
}



private func serializeAlgorithmParameters(_ params: DerivedAlgorithmParameters) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    
    var aString = ""
    do {
        let jsonData = try encoder.encode(params)
        
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            aString = jsonString
        }
    } catch {
        print("Could not serialize parameters: \(error.localizedDescription)")
    }
    return aString
}

private func deserializeAlgorithmParameters(text: String) -> DerivedAlgorithmParameters? {
    
    if let jsonData = text.data(using: .utf8) {
        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode(DerivedAlgorithmParameters.self, from: jsonData)
            
        } catch {
            print("Could not create instance: \(error.localizedDescription)")
        }
    } else {
        print("Did not create instance")
    }
    return nil
}
