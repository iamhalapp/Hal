//
//  Math.swift
//  HAL
//
//  Created by Thibault Imbert on 7/13/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import HealthKit
import Charts

class Math {
    
    static func computeAverage (samples: [GlucoseSample]) -> Double {
        if (samples.count == 0) { return 0.0 }
        var sum: Double = 0
        let total: Double = Double (samples.count)
        for sample in samples {
            sum += Double(sample.value)
        }
        return ( sum / total )
    }
    
    static func computeSD(samples: [GlucoseSample]) -> Double {
        let mean: Double = Math.computeAverage(samples: samples)
        var difference: Double
        var absoluteDifference: Double
        var squaredDifference: Double
        var sum: Double = 0.0
        let total: Double = Double (samples.count)
        for sample in samples {
            difference = mean - Double (sample.value)
            absoluteDifference = abs(difference)
            squaredDifference = pow(absoluteDifference, 2)
            sum += squaredDifference
        }
        return (sum / total).squareRoot()
    }

    static func A1C(samples: [GlucoseSample]) -> Double {
        return ( (46.7 + Math.computeAverage(samples: samples)) / 28.7 )
    }
    
    static func computeHighBG (samples: [GlucoseSample]) -> [GlucoseSample] {
        let highBG: Double = 150.0
        return samples.filter { Double($0.value) > highBG }
    }
    
    static func computeLowBG (samples: [GlucoseSample]) -> [GlucoseSample] {
        let lowBG: Double = 80
        return samples.filter { Double($0.value) < lowBG }
    }
    
    static func computeNormalRangeBG (samples: [GlucoseSample]) -> [GlucoseSample] {
        let lowBG: Double = 80
        let highBG: Double = 150.0
        return samples.filter { Double($0.value) > lowBG && Double($0.value) < highBG }
    }
    
    static func sqrt (samples: [Double]) -> [Double] {
        return samples.map({(value: Double) -> Double in return value.squareRoot()})
    }
    
    static func multiply (a: [Double], b: [Double]) -> [Double] {
        return zip(a, b).map { $0 * $1 }
    }
    
    static func add (a: [Double], b: [Double]) -> [Double] {
        return zip(a, b).map { $0 + $1 }
    }
    
    static func subtract (a: [Double], b: [Double]) -> [Double] {
        return zip(a, b).map { $0 + $1 }
    }
    
    static func divide (a: [Double], b: [Double]) -> [Double] {
        return zip(a, b).map { $0 / $1 }
    }
    
    static func transpose (samples: [Double]) -> [[Double]] {
        var buffer: [[Double]] = []
        for i in samples {
            var temp: [Double] = []
            temp.append(i)
            temp.append(i)
            buffer.append(temp)
        }
        return buffer;
    }

    static func gradient(samples: [Double]) -> [Double] {
        var buffer: [Double] = []
        let end = samples.count-1
        buffer.append((samples[1] - samples[0])/1)
        for i in 1...end-1 {
            buffer.append ((samples[i+1] - samples[i-1])/2)
        }
        buffer.append((samples[samples.count-1] - samples[samples.count-2])/1)
        return buffer
    }
    
    // Calculates the acceleration of the curve
    static func curvature(x: [Double], y: [Double]) -> Double{
        var dx_dt = Math.gradient(samples: x)
        var dy_dt = Math.gradient(samples: y)
        
        let multipliedDx: [Double] = Math.multiply(a: dx_dt, b: dx_dt)
        let multipliedDy: [Double] = Math.multiply(a: dy_dt, b: dy_dt)
        let ds_dt = Math.sqrt ( samples: Math.add ( a: multipliedDx, b: multipliedDy ) )
        
        let normalized: [Double] = ds_dt.map ({(value: Double) -> Double in return 1 / value})
        var t: [[Double]] = Math.transpose(samples: normalized)
        var tangent: [[Double]] = []
        var velocity: [[Double]] = []
        
        for i in 0..<dx_dt.count {
            var temp: [Double] = []
            temp.append (dx_dt[i])
            temp.append (dy_dt[i])
            velocity.append(temp)
        }
        
        for i in 0..<t.count {
            var temp: [Double] = []
            temp.append (t[i][0]*velocity[i][0])
            temp.append (t[i][1]*velocity[i][1])
            tangent.append(temp)
        }
        
        let tangent_x: [Double] = tangent.map ({(value: [Double]) -> Double in return value[0]})
        let tangent_y: [Double] = tangent.map ({(value: [Double]) -> Double in return value[1]})
        
        var deriv_tangent_x: [Double] = Math.gradient(samples: tangent_x)
        var deriv_tangent_y: [Double] = Math.gradient(samples: tangent_y)
        
        var dT_dt: [[Double]] = []
        
        for i in 0..<deriv_tangent_x.count {
            var temp: [Double] = []
            temp.append (deriv_tangent_x[i])
            temp.append (deriv_tangent_y[i])
            dT_dt.append(temp)
        }
        
        let multipliedtx: [Double] = Math.multiply(a: deriv_tangent_x, b: deriv_tangent_x)
        let multipliedty: [Double] = Math.multiply(a: deriv_tangent_y, b: deriv_tangent_y)
        let length_dT_dt = Math.sqrt ( samples: Math.add ( a: multipliedtx, b: multipliedty ) )
        
        let normalized2: [Double] = length_dT_dt.map ({(value: Double) -> Double in return 1 / value})
        var n: [[Double]] = Math.transpose(samples: normalized2)
        
        var normal: [[Double]] = []
        
        for i in 0..<n.count {
            var temp: [Double] = []
            temp.append (n[i][0]*dT_dt[i][0])
            temp.append (n[i][1]*dT_dt[i][1])
            normal.append(temp)
        }
        
        let d2s_dt2 = Math.gradient(samples: ds_dt)
        let d2x_dt2 = Math.gradient(samples: dx_dt)
        let d2y_dt2 = Math.gradient(samples: dy_dt)
        
        let a = Math.multiply(a: d2x_dt2, b: dy_dt)
        let b = Math.multiply(a: dx_dt, b: d2y_dt2)
        
        let aminusb = Math.subtract(a: a, b: b)
        
        let c = Math.multiply(a: dx_dt, b: dx_dt)
        let d = Math.multiply(a: dy_dt, b: dy_dt)
        
        let cplusd = Math.add(a: c, b: d).map ({(value: Double) -> Double in return pow(value, 1.5)})
        
        let curvature = Math.divide (a: aminusb, b: cplusd).map ({(value: Double) -> Double in return abs(value)})
        
        var tcomponent: [[Double]] = []
        
        for i in 0..<d2s_dt2.count {
            var temp: [Double] = []
            temp.append (d2s_dt2[i])
            temp.append (d2s_dt2[i])
            tcomponent.append(temp)
        }
        
        let c_ds_dt = Math.multiply(a: Math.multiply(a: curvature, b: ds_dt), b: ds_dt)
        
        var ncomponent: [[Double]] = []
        
        for i in 0..<c_ds_dt.count {
            var temp: [Double] = []
            temp.append (c_ds_dt[i])
            temp.append (c_ds_dt[i])
            ncomponent.append(temp)
        }
        
        var t_comp_tangent: [[Double]] = []
        var n_comp_normal: [[Double]] = []
        var acceleration: [[Double]] = []
        
        for i in 0..<tcomponent.count {
            var temp: [Double] = []
            temp.append (tcomponent[i][0]*tangent[i][0])
            temp.append (tcomponent[i][1]*tangent[i][1])
            t_comp_tangent.append(temp)
        }
        
        for i in 0..<ncomponent.count {
            var temp: [Double] = []
            temp.append (ncomponent[i][0]*normal[i][0])
            temp.append (ncomponent[i][1]*normal[i][1])
            n_comp_normal.append(temp)
        }
        
        for i in 0..<ncomponent.count {
            var temp: [Double] = []
            temp.append (t_comp_tangent[i][0]+n_comp_normal[i][0])
            temp.append (t_comp_tangent[i][1]+n_comp_normal[i][1])
            acceleration.append(temp)
        }
        
        var sum: Double = 0
        
        for i in 0..<acceleration.count-1 {
            let current = acceleration[i][1]
            let next = acceleration[i+1][1]
            if ( current.isNaN || next.isNaN ) {
                continue
            }
            sum += abs(next + current)
        }
        return ((sum/Double(x.count)))
    }
}

extension Double {
    // Rounds the double to decimal places value
    func roundTo(places:Int) -> Double {
        if self == 0 { return 0.0 }
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
