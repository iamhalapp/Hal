//
//  CollectionViewCell.swift
//  Hal
//
//  Created by Thibault Imbert on 10/5/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import UIKit

class CollectionViewCell: UICollectionViewCell
{
    @IBOutlet weak var label: UILabel!
    
    func displayContent (title: String)
    {
        label.text = title
    }
}
