//
//  ShareClient.h
//  ShareClient
//
//  Created by Mark Wilson on 5/7/16.
//  Copyright © 2016 Mark Wilson. All rights reserved.
//

import Foundation

public struct ShareGlucose {
    public let glucose: UInt16
    public let trend: UInt8
    public let timestamp: NSDate
}

public enum ShareError: ErrorType {
    case HTTPError(ErrorType)
    // some possible values of errorCode:
    // SSO_AuthenticateAccountNotFound
    // SSO_AuthenticatePasswordInvalid
    // SSO_AuthenticateMaxAttemptsExceeed
    case LoginError(errorCode: String)
    case FetchError
    case DataError
    case DateError
}

// From the Dexcom Share iOS app, via @bewest and @shanselman:
// https://github.com/bewest/share2nightscout-bridge
private let dexcomUserAgent = "Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0"
private let dexcomApplicationId = "d89443d2-327c-4a6f-89e5-496bbb0317db"
private let dexcomLoginPath = "/ShareWebServices/Services/General/LoginPublisherAccountByName"
private let dexcomLatestGlucosePath = "/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues"
private let dexcomServerUS = "https://share1.dexcom.com"
private let dexcomServerNonUS = "https://shareous1.dexcom.com"

// TODO use an HTTP library which supports JSON and futures instead of callbacks.
// using cocoapods in a playground appears complicated
// ¯\_(ツ)_/¯
private func dexcomPOST(url: String, data: NSData?, callback: (ErrorType?, String) -> Void) {
    let request = NSMutableURLRequest(URL: NSURL(string: url)!)
    request.HTTPMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.addValue(dexcomUserAgent, forHTTPHeaderField: "User-Agent")
    request.HTTPBody = data

    NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
        if (error != nil) {
            callback(error, "")
        } else {
            callback(nil, NSString(data: data!, encoding: NSUTF8StringEncoding)! as String)
        }
        }.resume()
}

public class ShareClient {
    public let username: String
    public let password: String

    private var token: String?

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    public func fetchLast(n: Int, callback: (ShareError?, [ShareGlucose]?) -> Void) {
        ensureToken() { (error, token) in
            guard error == nil, let token = token else {
                return callback(error, nil)
            }

            guard let components = NSURLComponents(string: dexcomServerUS + dexcomLatestGlucosePath) else {
                return callback(ShareError.FetchError, nil)
            }

            components.queryItems = [
                NSURLQueryItem(name: "sessionId", value: token),
                NSURLQueryItem(name: "minutes", value: String(1440)),
                NSURLQueryItem(name: "maxCount", value: String(n))
            ]

            guard let URLString = components.URL?.absoluteString else {
                return callback(ShareError.FetchError, nil)
            }

            dexcomPOST(URLString, data: "".dataUsingEncoding(NSUTF8StringEncoding)) { (error, response) in
                if let error = error {
                    return callback(ShareError.HTTPError(error), nil)
                }

                do {
                    let decoded = try? NSJSONSerialization.JSONObjectWithData(response.dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions())
                    guard let sgvs = decoded as? Array<AnyObject> else {
                        throw ShareError.DataError
                    }

                    var transformed: Array<ShareGlucose> = []
                    for sgv in sgvs {
                        if let glucose = sgv["Value"] as? Int, let trend = sgv["Trend"] as? Int, wt = sgv["WT"] as? String {
                            transformed.append(ShareGlucose(
                                glucose: UInt16(glucose),
                                trend: UInt8(trend),
                                timestamp: try self.parseDate(wt)
                                ))
                        } else {
                            throw ShareError.DataError
                        }
                    }
                    callback(nil, transformed)
                } catch let error as ShareError {
                    callback(error, nil)
                } catch {
                    callback(ShareError.FetchError, nil)
                }
            }
        }
    }

    private func ensureToken(callback: (ShareError?, String?) -> Void) {
        if token != nil {
            callback(nil, token)
        } else {
            fetchToken() { (error, token) in
                if error != nil {
                    callback(error, nil)
                } else {
                    self.token = token
                    callback(nil, token)
                }
            }
        }
    }

    private func fetchToken(callback: (ShareError?, String?) -> Void) {
        let data: [String: String] = [
            "accountName": self.username,
            "password": self.password,
            "applicationId": dexcomApplicationId
        ]

        guard let encoded = try? NSJSONSerialization.dataWithJSONObject(data, options:NSJSONWritingOptions(rawValue: 0)) else {
            return callback(ShareError.DataError, nil)
        }

        dexcomPOST(dexcomServerUS + dexcomLoginPath, data: encoded) { (error, response) in
            if let error = error {
                return callback(ShareError.HTTPError(error), nil)
            }

            guard let   data = response.dataUsingEncoding(NSUTF8StringEncoding),
                decoded = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                else {
                    return callback(ShareError.LoginError(errorCode: "unknown"), nil)
            }

            if let token = decoded as? String {
                // success is a JSON-encoded string containing the token
                callback(nil, token)
            } else {
                // failure is a JSON object containing the error reason
                let errorCode = (decoded as? [String: String])?["Code"] ?? "unknown"
                callback(ShareError.LoginError(errorCode: errorCode), nil)
            }
        }
    }

    private func parseDate(wt: String) throws -> NSDate {
        // wt looks like "/Date(1462404576000)/"
        let re = try NSRegularExpression(pattern: "\\((.*)\\)", options: NSRegularExpressionOptions())
        if let match = re.firstMatchInString(wt, options: NSMatchingOptions(), range: NSMakeRange(0, wt.characters.count)) {
            let epoch = Double((wt as NSString).substringWithRange(match.rangeAtIndex(1)))! / 1000
            return NSDate(timeIntervalSince1970: epoch)
        } else {
            throw ShareError.DateError
        }
    }
}
