import Foundation
import XCPlayground

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

struct ShareGlucose {
    let glucose: UInt16
    let trend: UInt8
    let timestamp: NSDate
}

enum ShareError:ErrorType {
    case HTTPError
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
let dexcomUserAgent = "Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0"
let dexcomApplicationId = "d89443d2-327c-4a6f-89e5-496bbb0317db"
let dexcomLoginPath = "/ShareWebServices/Services/General/LoginPublisherAccountByName"
let dexcomLatestGlucosePath = "/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues"
let dexcomServerUS = "https://share1.dexcom.com"
let dexcomServerNonUS = "https://shareous1.dexcom.com"

// TODO use an HTTP library which supports JSON and futures instead of callbacks.
// using cocoapods in a playground appears complicated
// ¯\_(ツ)_/¯
func dexcomPOST(url: String, data: NSData, callback: (ErrorType?, String) -> Void) {
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

class ShareClient {
    let username: String
    let password: String
    var _token: String?

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    func fetchLast(n: Int, callback: (ShareError?, [ShareGlucose]?) -> Void) {
        self._ensureToken() { (error, token) in
            if (error != nil) {
                return callback(error, nil)
            }

            var url = dexcomServerUS + dexcomLatestGlucosePath
            url += "?sessionId=" + token!
            url += "&minutes=" + "1440"
            url += "&maxCount=" + String(n)
            dexcomPOST(url, data: "".dataUsingEncoding(NSUTF8StringEncoding)!) { (error, response) in
                if (error != nil) {
                    return callback(ShareError.HTTPError, nil)
                }
                do {
                    let decoded = try? NSJSONSerialization.JSONObjectWithData(response.dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions())
                    let sgvs = decoded as? Array<AnyObject>
                    if (sgvs == nil) {
                        throw ShareError.DataError
                    }
                    var transformed:Array<ShareGlucose> = [];
                    for sgv in sgvs! {
                        if let glucose = sgv["Value"] as? Int, let trend = sgv["Trend"] as? Int, wt = sgv["WT"] as? String {
                            transformed.append(ShareGlucose(
                                glucose: UInt16(glucose),
                                trend: UInt8(trend),
                                timestamp: try self._parseDate(wt)
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

    func _ensureToken(callback: (ShareError?, String?) -> Void) {
        if (self._token != nil) {
            callback(nil, self._token)
        } else {
            self._fetchToken() { (error, token) in
                if (error != nil) {
                    callback(error, nil)
                } else {
                    self._token = token
                    callback(nil, token)
                }
            }
        }
    }

    func _fetchToken(callback: (ShareError?, String?) -> Void) {
        let data: [String: AnyObject] = [
            "accountName": self.username,
            "password": self.password,
            "applicationId": dexcomApplicationId
        ]
        let encoded = try! NSJSONSerialization.dataWithJSONObject(data, options:NSJSONWritingOptions(rawValue: 0))
        dexcomPOST(dexcomServerUS + dexcomLoginPath, data: encoded) { (error, response) in
            if (error != nil) {
                return callback(ShareError.HTTPError, nil)
            }

            let decoded = try? NSJSONSerialization.JSONObjectWithData(response.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments)
            if let token = decoded as? String {
                // success is a JSON-encoded string containing the token
                callback(nil, token)
            } else {
                // failure is a JSON object containing the error reason
                let errorCode = decoded!["Code"]! as? String ?? "unknown"
                callback(ShareError.LoginError(errorCode: errorCode), nil)
            }
        }
    }

    func _parseDate(wt: String) throws -> NSDate {
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

var client = ShareClient(username: "u", password: "p")
client.fetchLast(6) { (error, glucoses) -> Void in
    if (error != nil) {
        print(error!)
    } else {
        print(glucoses!)
    }
}
