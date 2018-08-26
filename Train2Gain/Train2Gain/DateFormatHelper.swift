//
//  DateFormatHelper.swift
//  Train2Gain
//
//  Created by Michael Temper on 26.08.18.
//  Copyright © 2018 Temper. All rights reserved.
//

import Foundation

class DateFormatHelper {
    
    static func returnDateForm(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        let dateFormat = DateFormatter.Style.short
        let timeFormat = DateFormatter.Style.none
        dateFormatter.dateStyle = dateFormat
        dateFormatter.timeStyle = timeFormat
        return dateFormatter.string(from: date)
    }
    
}
