//
//  DateFormatHelper.swift
//  Train2Gain
//
//  Created by Michael Temper on 26.08.18.
//  Copyright © 2018 Temper. All rights reserved.
//

import Foundation
import UIKit

class DateFormatHelper {
    
    static func returnDateForm(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        let dateFormat = DateFormatter.Style.short
        let timeFormat = DateFormatter.Style.none
        dateFormatter.dateStyle = dateFormat
        dateFormatter.timeStyle = timeFormat
        return dateFormatter.string(from: date)
    }

    static func setDate(_ date: Date, _ datePickerButton : UIButton) -> Date {
        UserDefaults.standard.set(date , forKey: "dateUF")
        datePickerButton.setTitle(DateFormatHelper.returnDateForm(date), for: UIControlState())
        return date
    }
    
}
