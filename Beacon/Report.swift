//
//  Report.swift
//  Hal
//
//  Created by Thibault Imbert on 8/30/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation

class Report: EventDispatcher {
    
    public var a1c: Int
    public var bpm: Float
    public var average: Float
    public var acceleration: Float
    public var avgHigh: Int
    public var avgNormal: Int
    public var avgLow: Int
    public var highs: Int
    public var normals: Int
    public var lows: Int
    public var sd: Float
    
    init (a1c: Int, bpm: Int, sd: Float, average: Float, acceleration: Float, avgHigh: Int, avgNormal: Int, avgLow: Int, highs: Int, normals: Int, lows: Int) {
        self.a1c = a1c
        self.bpm = Float(bpm)
        self.sd = sd
        self.average = average
        self.acceleration = acceleration
        self.avgHigh = avgHigh
        self.avgNormal = avgNormal
        self.avgLow = avgLow
        self.highs = highs
        self.normals = normals
        self.lows = lows
    }
    
}
