//
//  BGSample.swift
//  Hal
//
//  Created by Thibault Imbert on 7/18/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation

class GlucoseSample: EventDispatcher
{
    public var value: Int = 0
    public let time: String
    public let date: String
    public var trend: String
    public var trends: [String: String] = ["doubleUp": "\u{2191}\u{2191}", "singleUp": "\u{2191}", "fortyFiveUp": "\u{2197}", "flat": "\u{2192}",
                                           "fortyFiveDown": "\u{2198}", "singleDown": "\u{2193}", "doubleDown": "\u{2193}\u{2193}"]
    
    init (pValue: Int, pDate: String, pTime: String, pTrend: String)
    {
        value = pValue
        date = pDate
        time = pTime
        trend = trends[pTrend]!
    }
}

class HeartRateSample: GlucoseSample {}
