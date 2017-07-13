//
//  MoodCell.swift
//  Train2Gain
//
//  Created by Michael Temper on 26.04.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit

class MoodCell: UICollectionViewCell {
    
    @IBOutlet weak var m_IV_moodSmiley: UIImageView!
    
    @IBOutlet weak var m_L_moodName: UILabel!
    
    override var isSelected : Bool {
        
        //Show the user that one cell is selected
        didSet{
            //Mark selected cell with a border and a bigger font
            m_L_moodName.font = isSelected ? UIFont(name: "HelveticaNeue-Medium", size: 18) : UIFont(name: "HelveticaNeue-Light", size: 18)
            layer.borderWidth =  isSelected ? 1 : 0
            layer.cornerRadius = 5
            layer.borderColor = UIColor(red: 20 / 255, green: 204 / 255, blue:1.00, alpha:1.0).cgColor
        }
    }
}
