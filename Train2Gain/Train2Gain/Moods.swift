//
//  Moods.swift
//  Train2Gain
//
//  Created by Michael Temper on 26.04.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit

class Moods: NSObject {
    
    var moodSmiley: UIImage
    var moodName: String
    
    init(_moodName: String, _moodSmileyString: String){
        moodName = _moodName
        moodSmiley = UIImage(named: _moodSmileyString)!
    }
   
}
