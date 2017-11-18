//
//  Settings.swift
//  Hal
//
//  Created by Thibault Imbert on 9/8/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import UIKit

class SettingsController: UIViewController
{
    private var toggle: DarwinBoolean = false
    private var setupBg: Background!
    private var a1cSummary: StatSummary!
    private var bpmSummary: StatSummary!
    private var sdSummary: StatSummary!
    private var avgSummary: StatSummary!
    private var accelSummary: StatSummary!
    private var percentageNormalSummary: StatSummary!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        var imageView  = UIImageView(frame: CGRect(x: 20, y: 40, width: 20, height: 17))
        imageView.isUserInteractionEnabled = true
        var image = UIImage(named: "Menu")!
        imageView.image = image
        self.view.addSubview(imageView)
        
        setupBg = Background (parent: self)
        
        let header = UIFont(name: ".SFUIText-Semibold", size :18)
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = header
        label.text = "Today compared to yesterday"
        label.frame = CGRect(x: 20, y: 0, width: 290, height: 20)
        label.center = CGPoint(x: 170,y: 100)
        self.view.addSubview(label)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleMenu(recognizer:)))
        imageView.addGestureRecognizer(tapRecognizer)
        
        let red: UIColor = colorWithHexString(hexString: "#ff5a5f")
        let green: UIColor = colorWithHexString(hexString: "#57e5d7")
        
        // init summary stats
        a1cSummary = StatSummary()
        a1cSummary.center = CGPoint(x: 25,y: 140)
        a1cSummary.setStyle(size: 28, color: green)
        self.view.addSubview(a1cSummary)
        bpmSummary = StatSummary()
        bpmSummary.setStyle(size: 28, color: red)
        bpmSummary.center = CGPoint(x: 25,y: 210)
        self.view.addSubview(bpmSummary)
        sdSummary = StatSummary()
        sdSummary.setStyle(size: 28, color: red)
        sdSummary.center = CGPoint(x: 25,y: 280)
        self.view.addSubview(sdSummary)
        avgSummary = StatSummary()
        avgSummary.setStyle(size: 28, color: red)
        avgSummary.center = CGPoint(x: 25,y: 350)
        self.view.addSubview(avgSummary)
        accelSummary = StatSummary()
        accelSummary.setStyle(size: 28, color: green)
        accelSummary.center = CGPoint(x: 25,y: 420)
        self.view.addSubview(accelSummary)
        percentageNormalSummary = StatSummary()
        percentageNormalSummary.setStyle(size: 28, color: red)
        percentageNormalSummary.center = CGPoint(x: 25,y: 490)
        self.view.addSubview(percentageNormalSummary)
        
        // update high level summary stats
        a1cSummary.update(icon: "Droplet", text: "7.9 (+15%)", txtOffsetX: 47, txtOffsetY:5, offsetX: 0, offsetY: 0, width: 38, height: 38)
        bpmSummary.update(icon: "Heart", text: "89 bpm (-5%)", txtOffsetX: 47, txtOffsetY:5, offsetX: 0, offsetY: 0, width: 38, height: 38)
        sdSummary.update(icon: "Deviation", text: "21 (-85%)", txtOffsetX: 47, txtOffsetY: 5, offsetX: 0, offsetY: 0, width: 38, height: 38)
        avgSummary.update(icon: "Chart", text: "160 (+27%)", txtOffsetX: 47, txtOffsetY:5, offsetX: 0, offsetY: 0, width: 38, height: 38)
        accelSummary.update(icon: "Rising", text: "1.11 (-41%)", txtOffsetX: 47, txtOffsetY:5, offsetX: 0, offsetY: 0, width: 38, height: 38)
        percentageNormalSummary.update(icon: "Percentage", text: "78% (-11%)", txtOffsetX: 47, txtOffsetY:5, offsetX:0, offsetY: 0, width: 38, height: 38)
    }
    
    func colorWithHexString(hexString: String, alpha:CGFloat? = 1.0) -> UIColor {
        
        // Convert hex string to an integer
        let hexint = Int(self.intFromHexString(hexStr: hexString))
        let red = CGFloat((hexint & 0xff0000) >> 16) / 255.0
        let green = CGFloat((hexint & 0xff00) >> 8) / 255.0
        let blue = CGFloat((hexint & 0xff) >> 0) / 255.0
        let alpha = alpha!
        
        // Create color object, specifying alpha as well
        let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        return color
    }
    
    func intFromHexString(hexStr: String) -> UInt32 {
        var hexInt: UInt32 = 0
        // Create scanner
        let scanner: Scanner = Scanner(string: hexStr)
        // Tell scanner to skip the # character
        scanner.charactersToBeSkipped = NSCharacterSet(charactersIn: "#") as CharacterSet
        // Scan hex value
        scanner.scanHexInt32(&hexInt)
        return hexInt
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    func toggleMenu(recognizer: UITapGestureRecognizer) {
        DispatchQueue.main.async(execute:
            {
                self.performSegue(withIdentifier: "unwindToMain", sender: self)
        })
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}
