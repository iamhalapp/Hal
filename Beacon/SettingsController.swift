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
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        var imageView  = UIImageView(frame: CGRect(x: 20, y: 40, width: 20, height: 17))
        imageView.isUserInteractionEnabled = true
        var image = UIImage(named: "Menu")!
        imageView.image = image
        self.view.addSubview(imageView)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleMenu(recognizer:)))
        imageView.addGestureRecognizer(tapRecognizer)
        
        setupBg = Background (parent: self)
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
