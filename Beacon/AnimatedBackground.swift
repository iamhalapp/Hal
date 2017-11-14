//
//  Background.swift
//  Hal
//
//  Created by Thibault Imbert on 8/30/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class AnimatedBackground
{
    
    private var gradientLayer = CAGradientLayer()
    var avPlayer: AVPlayer?
    var avPlayerLayer: AVPlayerLayer!
    var paused: Bool = false
    
    init( parent: UIViewController )
    {
        
        gradientLayer.frame = parent.view.bounds
        
        let color1 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor as CGColor
        let color2 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor as CGColor
        let color3 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor as CGColor
        let color4 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor as CGColor
        let color5 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor as CGColor
        gradientLayer.colors = [color1, color2, color3, color4, color5]
        
        gradientLayer.locations = [0.0, 0.12, 0.25, 0.5, 1.0]
        
        let filePath = Bundle.main.url(forResource: "sea", withExtension: "mp4")
        
        do
        {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        } catch let error as NSError {
            print(error)
        }
        
        do
        {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print(error)
        }
        
        avPlayer = AVPlayer(url: filePath!)
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        avPlayer?.volume = 0
        avPlayer?.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        
        avPlayerLayer.frame = parent.view.layer.bounds
        parent.view.backgroundColor = UIColor.clear
        parent.view.layer.insertSublayer(avPlayerLayer, at: 0)
        parent.view.layer.insertSublayer(gradientLayer, at: 1)
        avPlayer?.play()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: avPlayer?.currentItem)
    }
    
    @objc func playerItemDidReachEnd(notification: NSNotification)
    {
        let p: AVPlayerItem = notification.object as! AVPlayerItem
        p.seek(to: kCMTimeZero)
    }
    
    public func stop()
    {
        avPlayer = nil
    }
}
