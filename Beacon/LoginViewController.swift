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
    @IBOutlet weak var taglineLbl: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    
    public var defaults: UserDefaults!
    public var dxBridge: DexcomBridge!
    private var loggedIn: EventHandler!
    private var setupBg: AnimatedBackground!
    private var keychain:KeychainSwift!
    private var logo: UIImage!
    private var bodyFont:UIFont!
    private var titleFont: UIFont!
    
    private let oauthswift = OAuth2Swift(
        consumerKey:    "PufsQSdRKnVgCc8phv3CtKrg7gArPHJT",
        consumerSecret: "sAWUZwCSmdoeWlyW",
        authorizeUrl:   "https://sandbox-api.dexcom.com/v1/oauth2/login",
        accessTokenUrl: "offline_access",
        responseType:   "code"
    )
    
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
        titleFont = UIFont(name: ".SFUIText-Semibold", size :26)
        taglineLbl.font = titleFont
        errorLbl.font = bodyFont
        
        // tagline
        taglineLbl.text = "HAL, your diabetic\ncoach in your pocket."
        
        // rounded corners
        loginButton.layer.cornerRadius = 5
        
        // load the keychain
        keychain = KeychainSwift.shared()
        
        // background handling
        setupBg = AnimatedBackground (parent: self)
        
        // auth login
        dxBridge = DexcomBridge.shared()
        let onTokenReceivedHandler = EventHandler(function: self.onTokenReceived)
        dxBridge.addEventListener(type: EventType.token, handler: onTokenReceivedHandler)
        
        // password management
        let code = keychain.get("code")
        
        if code != nil
        {
            dxBridge.getToken(code: code!)
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    public func onTokenReceived(event: Event)
    {
        self.performSegue(withIdentifier: "Main", sender: self)
    }
    
    @IBAction func login(_ sender: Any)
    {
        let handle = oauthswift.authorize(
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
