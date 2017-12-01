//
//  DetailsViewController.swift
//  Hal
//
//  Created by Thibault Imbert on 8/22/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import UIKit
import OAuthSwift

class LoginViewController: UIViewController
{
    @IBOutlet weak var errorLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var taglineLbl: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    
    public var defaults: UserDefaults!
    public var dxBridge: DexcomBridge!
    private var loggedIn: EventHandler!
    private var setupBg: LoginBackground!
    private var keyChain: KeychainSwift!
    private var logo: UIImage!
    private var bodyFont:UIFont!
    private var titleFont: UIFont!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Hal logo
        let imageView:UIImageView = UIImageView(image: UIImage(named: "Hal-Logo"))
        imageView.frame = CGRect(x: 100/2, y: (100*0.87)/2, width: 100, height: 100*0.87)
        var center: CGPoint = self.view.center
        center.y -= 200
        imageView.center = center
        self.view.addSubview(imageView)
        
        // font for buttons and labels
        bodyFont = UIFont(name: ".SFUIText-Semibold", size :11)
        //titleFont = UIFont(name: "PT-Sans-Narrow", size :26)
      //  taglineLbl.font = titleFont
        errorLbl.font = bodyFont
        
        // tagline
        titleLbl.text = "HAL,\nYour Diabetes Coach"
        taglineLbl.text = "The Dexcom companion app that helps you get the most out of your Dexcom."
        
        // rounded corners
        loginButton.layer.cornerRadius = 5
        
        // load the keychain
        keyChain = KeychainSwift.shared()
        
        // background handling
        setupBg = LoginBackground (parent: self)
        
        // auth login
        dxBridge = DexcomBridge.shared()
        let onTokenReceivedHandler = EventHandler(function: self.onTokenReceived)
        let onTokenRefreshedReceivedHandler = EventHandler(function: self.onTokenRefreshedReceived)
        dxBridge.addEventListener(type: EventType.token, handler: onTokenReceivedHandler)
        dxBridge.addEventListener(type: EventType.refreshToken, handler: onTokenRefreshedReceivedHandler)
        
        // password management
        let refreshToken = keyChain.get("refreshToken")
        
        if refreshToken != nil
        {
            dxBridge.refreshToken()
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    public func onTokenRefreshedReceived(event: Event)
    {
        self.performSegue(withIdentifier: "Main", sender: self)
    }
    
    public func onTokenReceived(event: Event)
    {
        self.performSegue(withIdentifier: "Main", sender: self)
    }
    
    @IBAction func login(_ sender: Any)
    {
        let handle = DexcomBridge.shared().oauthswift.authorize(
            withCallbackURL: URL(string: "hal://oauth-callback/dexcom")!,
            scope: "offline_access", state:"dummy",
            success: { credential, response, parameters in
                // Do your request
        },
            failure: { error in
                print("error " + error.localizedDescription)
        }
        )
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
