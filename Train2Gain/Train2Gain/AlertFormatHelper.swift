//
//  AlertFormatHelper.swift
//  Train2Gain
//
//  Created by Michael Temper on 27.08.18.
//  Copyright © 2018 Temper. All rights reserved.
//

import Foundation
import UIKit

class AlertFormatHelper {
    
    static func showInfoAlert(_ viewController: UIViewController, _ infoText: String) {
        let informUser = UIAlertController(title: NSLocalizedString("Saved", comment: "Saved"), message: NSLocalizedString(infoText, comment: infoText), preferredStyle: UIAlertControllerStyle.alert)
        informUser.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.default, handler: { (action) -> Void in
            viewController.navigationController?.popViewController(animated: true)
        }))
        viewController.present(informUser, animated: true, completion: nil)
    }
    
}
