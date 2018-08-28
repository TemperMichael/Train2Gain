//
//  MoodCell.swift
//  Train2Gain
//
//  Created by Michael Temper on 26.04.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit

class MoodCell: UICollectionViewCell {
    
    @IBOutlet weak var moodImageView: UIImageView!
    @IBOutlet weak var moodNameLabel: UILabel!
    
    override var isSelected : Bool {
        
        //Show the user that one cell is selected
        didSet{
            //Mark selected cell with a border and a bigger font
            moodNameLabel.font = isSelected ? UIFont(name: "HelveticaNeue-Medium", size: 18) : UIFont(name: "HelveticaNeue-Light", size: 18)
            layer.borderWidth =  isSelected ? 1 : 0
            layer.cornerRadius = 5
            layer.borderColor = UIColor(red: 37 / 255, green: 190 / 255, blue: 254 / 255, alpha: 1).cgColor
        }
    }
    
}
