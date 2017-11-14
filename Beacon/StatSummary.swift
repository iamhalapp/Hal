//
//  StatSummary.swift
//  Hal
//
//  Created by Thibault Imbert on 10/7/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import UIKit

class StatSummary: UIView {
    
    var label: UILabel!
    var imageView: UIImageView!
    var image: UIImage!
    
    override init(frame: CGRect){
        super.init(frame: frame)
        imageView  = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 28))
        self.addSubview(imageView)
        let detailsFont = UIFont(name: ".SFUIText-Semibold", size :14)
        label = UILabel()
        label.textColor = UIColor.white
        label.font = detailsFont
        self.addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update (icon: String, text: String, txtOffsetX: Int, txtOffsetY:Int, offsetX: Int, offsetY: Int, width: Int, height: Int){
        image = UIImage(named: icon)!
        imageView.frame = CGRect(x: offsetX, y: offsetY, width: width, height: height)
        label.frame = CGRect(x: txtOffsetX, y: txtOffsetY, width: 200, height: 21)
        imageView.image = image
        label.text = text
    }
}
