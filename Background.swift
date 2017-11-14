//
//  Background.swift
//  Hal
//
//  Created by Thibault Imbert on 8/7/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import UIKit

class Background {
    
    private var gradientLayer:CAGradientLayer = CAGradientLayer()
    private var imageLayer:CALayer = CALayer()
    
    init(parent: UIViewController)
    {
        gradientLayer.frame = parent.view.bounds
        
        let color1 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor as CGColor
        let color2 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor as CGColor
        let color3 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor as CGColor
        let color4 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor as CGColor
        let color5 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor as CGColor
        gradientLayer.colors = [color1, color2, color3, color4, color5]
        
        gradientLayer.locations = [0.0, 0.12, 0.25, 0.5, 1.0]
        
        let filePath = Bundle.main.path(forResource: getBackgroundOfTimeOfTheDay(), ofType: "jpg")
        
        let image:UIImage = UIImage(contentsOfFile: filePath!)!
        imageLayer.contents = image.cgImage
        imageLayer.frame = CGRect(x: -700, y: -400, width: 2001, height: 1334)
        imageLayer.transform = CATransform3DMakeScale(0.6, 0.6, 1);
        parent.view.layer.insertSublayer(imageLayer, at: 0)
        parent.view.layer.insertSublayer(gradientLayer, at: 1)
    }
    
    private func getBackgroundOfTimeOfTheDay() -> String
    {
        let timeOfDay: TimeOfDay = Utils.getTimeofDay()
        var fileName: String!
        
        if (timeOfDay == TimeOfDay.morning) {
            fileName = "morning"
        } else if (timeOfDay == TimeOfDay.noon) {
            fileName = "noon"
        } else if (timeOfDay == TimeOfDay.evening) {
            fileName = "evening"
        } else if (timeOfDay == TimeOfDay.night) {
            fileName = "night"
        }
        return fileName
    }
    
    public func updateBackground ()
    {
        let filePath = Bundle.main.path(forResource: getBackgroundOfTimeOfTheDay(), ofType: "jpg")
        let image:UIImage = UIImage(contentsOfFile: filePath!)!
        imageLayer.contents = image.cgImage
    }
}
