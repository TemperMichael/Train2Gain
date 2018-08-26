//
//  PickerHelper.swift
//  Train2Gain
//
//  Created by Michael Temper on 26.08.18.
//  Copyright © 2018 Temper. All rights reserved.
//

import Foundation


class DateFormatHelper {
    
    static func returnDateForm(_ date:Date) -> String{
        let dateFormatter = DateFormatter()
        let theDateFormat = DateFormatter.Style.short
        let theTimeFormat = DateFormatter.Style.none
        dateFormatter.dateStyle = theDateFormat
        dateFormatter.timeStyle = theTimeFormat
        return dateFormatter.string(from: date)
    }
    
    
}
