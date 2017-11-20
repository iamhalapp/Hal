//
//  DexcomBridge.swift
//  Hal
//
//  Created by Thibault Imbert on 9/22/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import Alamofire
import SwiftyJSON
import OAuthSwift

class DexcomBridge: EventDispatcher
{
    public static var TOKEN: String!
    public static var REFRESHED_TOKEN: String!
    
    private static let CONSUMER_KEY: String = "sFW420cYM1CukL3ogpmHyB61m06c5Qb5"
    private static let CONSUMER_SECRET: String = "CL0QpJq42XhNAsok"
    
    private static var TOKEN_URL: String = "https://sandbox-api.dexcom.com/v1/oauth2/token"
    private static var GLUCOSE_URL: String = "https://sandbox-api.dexcom.com/v1/users/self/egvs"
    private static let AUTHORIZE_URL:String = "https://sandbox-api.dexcom.com/v1/oauth2/login"
    private static let REDIRECT_URI: String = "com.beacon-app.scout"
    private static let ACCESS_TOKEN_URL:String = "offline_access"
    private static let RESPONSE_TYPE: String = "code"
    private static let AUTHORIZATION_CODE: String = "authorization_code"
    private static let REFRESH_TOKEN: String = "refresh_token"
    
    enum RemoteError: Error {
        case description (details: String)
    }
    
    public var bloodSamples: [GlucoseSample] = []
    private var dataTask: URLSessionDataTask?
    
    private let headers: HTTPHeaders = [
        "content-type": "application/x-www-form-urlencoded",
        "cache-control": "no-cache"
    ]
    
    public let oauthswift = OAuth2Swift(
        consumerKey:    DexcomBridge.CONSUMER_KEY,
        consumerSecret: DexcomBridge.CONSUMER_SECRET,
        authorizeUrl:   DexcomBridge.AUTHORIZE_URL,
        accessTokenUrl: DexcomBridge.ACCESS_TOKEN_URL,
        responseType:   DexcomBridge.RESPONSE_TYPE
    )
    
    private static var sharedDexcomBridge: DexcomBridge =
    {
        let bridge = DexcomBridge()
        return bridge
    }()
    
    class func shared() -> DexcomBridge
    {
        return sharedDexcomBridge
    }
    
    // authenticates the user to the dexcom REST APIs
    public func getToken(code: String)
    {
        let parameters: Parameters = [
            "client_secret": DexcomBridge.CONSUMER_SECRET,
            "client_id": DexcomBridge.CONSUMER_KEY,
            "code": code,
            "grant_type": DexcomBridge.AUTHORIZATION_CODE,
            "redirect_uri": DexcomBridge.REDIRECT_URI
        ]
        
        Alamofire.request(DexcomBridge.TOKEN_URL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: headers).responseJSON { response in
            
            if (response.result.isSuccess)
            {
                do
                {
                    let result: JSON = try JSON(data: response.data!)
                    if ( result["fault"] != JSON.null )
                    {
                        throw RemoteError.description ( details: result["fault"]["detail"]["errorcode"].stringValue )
                    } else
                    {
                        let token: String = result["access_token"].stringValue
                        let refreshToken: String = result["refresh_token"].stringValue
                        DexcomBridge.TOKEN = token
                        DexcomBridge.REFRESHED_TOKEN = refreshToken
                        DispatchQueue.main.async(execute:
                        {
                                self.dispatchEvent(event: Event(type: EventType.token, target: self))
                        })
                    }
                } catch RemoteError.description(let details)
                {
                    print ( "Error: " + details )
                } catch
                {
                    print ( "Uncaught error" )
                }
            } else
            {
                DispatchQueue.main.async(execute: {
                    self.dispatchEvent(event: Event(type: EventType.glucoseIOError, target: self))
                })
            }
        }
    }
    
    // authenticates the user to the dexcom REST APIs
    public func refreshToken(refreshedToken: String = DexcomBridge.REFRESHED_TOKEN)
    {
        let parameters: Parameters = [
            "client_secret": DexcomBridge.CONSUMER_SECRET,
            "client_id": DexcomBridge.CONSUMER_KEY,
            "refresh_token": refreshedToken,
            "grant_type": DexcomBridge.REFRESH_TOKEN,
            "redirect_uri": DexcomBridge.REDIRECT_URI
        ]
        
        Alamofire.request(DexcomBridge.TOKEN_URL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: headers).responseJSON { response in
            
            if (response.result.isSuccess)
            {
                do {
                    let result: JSON = try JSON(data: response.data!)
                    if ( result["fault"] != JSON.null )
                    {
                        throw RemoteError.description ( details: result["fault"]["detail"]["errorcode"].stringValue )
                    } else
                    {
                        let token: String = result["access_token"].stringValue
                        let refreshToken: String = result["refresh_token"].stringValue
                        DexcomBridge.TOKEN = token
                        DexcomBridge.REFRESHED_TOKEN = refreshToken
                        DispatchQueue.main.async(execute:
                            {
                                self.dispatchEvent(event: Event(type: EventType.refreshToken, target: self))
                        })
                    }
                } catch RemoteError.description(let details)
                {
                    print ( "Error: " + details )
                } catch
                {
                    print ( "Uncaught error" )
                }
            } else
            {
                DispatchQueue.main.async(execute: {
                    self.dispatchEvent(event: Event(type: EventType.glucoseIOError, target: self))
                })
            }
        }
    }
    
    // retrieves the user last 24 hours glucose levels
    public func getGlucoseValues (token: String = DexcomBridge.TOKEN, startDate: String, endDate: String, completionHandler: ((UIBackgroundFetchResult) -> Void)! = nil)
    {
        let headers: HTTPHeaders = [
            "authorization": "Bearer " + DexcomBridge.TOKEN
        ]

        Alamofire.request(DexcomBridge.GLUCOSE_URL+"?startDate="+startDate+"&endDate="+endDate, method: .get, headers: headers).responseJSON { response in
            
            if (response.result.isSuccess)
            {
                do {
                    if let result: JSON = try JSON(data: response.data!)
                    {
                        if ( result["fault"] != JSON.null )
                        {
                            throw RemoteError.description ( details: result["fault"]["detail"]["errorcode"].stringValue )
                        } else
                        {
                            self.bloodSamples.removeAll()
                            if let egvs = result["egvs"].array
                            {
                                for item:JSON in egvs
                                {
                                    if item["value"] != JSON.null && item["systemTime"] != JSON.null && item["trend"] != JSON.null
                                    {
                                        let value = item["value"].int!
                                        let dateTime = item["systemTime"].stringValue
                                        let trend = item["trend"].stringValue
                                        let date = dateTime.components(separatedBy: "T")[0]
                                        let time = dateTime.components(separatedBy: "T")[1]
                                        self.bloodSamples.append(GlucoseSample(pValue: value, pDate: date, pTime: time, pTrend: trend))
                                    }
                                }
                        
                                DispatchQueue.main.async(execute:
                                    {
                                        self.dispatchEvent(event: Event(type: EventType.glucoseValues, target: self))
                                })
                                
                                if (completionHandler) != nil
                                {
                                    completionHandler(.newData)
                                }
                            }
                        }
                    }
                } catch RemoteError.description(let details)
                {
                    print ( "Error: " + details )
                } catch
                {
                    print ( "Uncaught error" )
                }
            } else
            {
                DispatchQueue.main.async(execute: {
                    self.dispatchEvent(event: Event(type: EventType.glucoseIOError, target: self))
                })
            }
        }
    }
}

