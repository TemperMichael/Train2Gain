//
//  PickerViewHelper.swift
//  Train2Gain
//
//  Created by Michael Temper on 26.08.18.
//  Copyright © 2018 Temper. All rights reserved.
//

import Foundation
import UIKit

class PickerViewHelper {
    
    weak var helperDelegate: UIViewController?
    
    static func setupPickerViewBackground(_ blurView: UIView, _ datePickerBackground: UIView) {
        blurView.frame = datePickerBackground.bounds
        blurView.translatesAutoresizingMaskIntoConstraints = false
        if !datePickerBackground.subviews.contains(blurView) {
            datePickerBackground.addSubview(blurView)
            datePickerBackground.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: datePickerBackground, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0.0))
            datePickerBackground.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: datePickerBackground, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0.0))
            datePickerBackground.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: datePickerBackground, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0.0))
            datePickerBackground.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: datePickerBackground, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0.0))
        }
        datePickerBackground.alpha = 0
        datePickerBackground.isHidden = false
    }
    
    static func bringPickerToFront(_ datePickerBackground: UIView, _ datePicker: UIView, _ finishButton: UIButton, _ pickerTitleLabel: UILabel) {
        datePickerBackground.bringSubview(toFront: datePicker)
        datePickerBackground.bringSubview(toFront: finishButton)
        datePickerBackground.bringSubview(toFront: pickerTitleLabel)
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
                datePickerBackground.alpha = 1
            }, completion: { finished in
        })
    }
    
    static func hidePickerView(_ datePickerBackgroundView: UIView) {
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
            datePickerBackgroundView.alpha = 0
        }, completion: { finished in
            datePickerBackgroundView.isHidden = true
        })
    }
    
    
}
