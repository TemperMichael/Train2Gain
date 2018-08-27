//
//  SettingsVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 27.04.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import LocalAuthentication

class SettingsVC: UIViewController {
    
    var password : String =  ""
    
    // MARK: IBOutlets & IBActions
    @IBOutlet weak var privacyModeSwitch: UISwitch!
    @IBOutlet weak var lengthUnitSwitch: UISwitch!
    @IBOutlet weak var weightUnitSwitch: UISwitch!
    
    @IBAction func togglePrivacyMode(_ sender: AnyObject) {
        if privacyModeSwitch.isOn {
            showPasswordAlert("Enter your password", single: false)
        } else {
            let context = LAContext()
            var error: NSError?
            let messageText = "Scan your fingerprint"
            context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error)
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: messageText, reply: {
                (success: Bool , policyError: Error?) -> Void in
                if success {
                    OperationQueue.main.addOperation(){
                        UserDefaults.standard.set("", forKey: "Password")
                    }
                } else {
                    // Handl other possible situations
                    switch policyError!._code {
                    case LAError.Code.systemCancel.rawValue :
                        UIAlertView(title: "Error", message: "Authentication was cancelled by the system", delegate: self, cancelButtonTitle: "OK").show()
                    case LAError.Code.userCancel.rawValue :
                        self.privacyModeSwitch.setOn(true, animated: true)
                    case LAError.Code.userFallback.rawValue :
                        self.showPasswordAlert("Enter your password", single: true)
                    default :
                        self.showPasswordAlert("Enter your password", single: true)
                    }
                }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        weightUnitSwitch.isOn = UserDefaults.standard.object(forKey: "weightUnit") as! String == "kg" ? true : false
        lengthUnitSwitch.isOn = UserDefaults.standard.object(forKey: "lengthUnit") as! String == "cm" ? true : false
        weightUnitSwitch.tintColor = UIColor.white
        lengthUnitSwitch.tintColor = UIColor.white
        privacyModeSwitch.tintColor = UIColor.white
        
        //Get password
        if let pw = UserDefaults.standard.object(forKey: "Password") as? String {
            password = pw
        }
        if password != "" {
            privacyModeSwitch.setOn(true, animated: false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let pw = UserDefaults.standard.object(forKey: "Password") as? String{
            password = pw
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        
        //Save chosen units
        if weightUnitSwitch.isOn {
            UserDefaults.standard.set("kg", forKey: "weightUnit")
        } else {
            UserDefaults.standard.set("lbs", forKey: "weightUnit")
        }
        
        if lengthUnitSwitch.isOn {
            UserDefaults.standard.set("cm", forKey: "lengthUnit")
        } else {
            UserDefaults.standard.set("inch", forKey: "lengthUnit")
        }
    }
    
    // MARK: Own Methods

    // Create password dialog: single = false for setup password
    //                         single = true for entering password
    func showPasswordAlert(_ _Message: String, single: Bool) {
        let passwordPrompt = UIAlertController(title: NSLocalizedString("Enter Password", comment: "Enter Password"), message: _Message, preferredStyle: UIAlertControllerStyle.alert)
        passwordPrompt.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.default, handler: { (action) -> Void in
            if self.privacyModeSwitch.isOn {
                self.privacyModeSwitch.setOn(false, animated: true)
            } else {
                self.privacyModeSwitch.setOn(true, animated: true)
            }
        }))
        passwordPrompt.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.default, handler: { (action) -> Void in
            //Enter password
            if single {
                let textField = passwordPrompt.textFields![0]
                let password = textField.text
                if password == self.password {
                    self.privacyModeSwitch.setOn(false, animated: true)
                    UserDefaults.standard.set("", forKey: "Password")
                } else {
                    self.showPasswordAlert(NSLocalizedString("Password was wrong", comment: "Password was wrong"),single: true)
                }
            } else {
                // Setup password
                var textField = passwordPrompt.textFields![0]
                let password = textField.text
                textField = passwordPrompt.textFields![1]
                let passwordConfirmend = textField.text
                if password == passwordConfirmend && passwordConfirmend != "" {
                    self.password = passwordConfirmend!
                    UserDefaults.standard.set(passwordConfirmend, forKey: "Password")
                } else {
                    self.showPasswordAlert(NSLocalizedString("Confirmed password was wrong or empty", comment: "Confirmed password was wrong or empty"),single: false)
                }
            }
        }))
        passwordPrompt.addTextField(configurationHandler: {(textField: UITextField) in
            textField.placeholder = NSLocalizedString("Password", comment: "Password")
            textField.isSecureTextEntry = true
        })
        if single == false {
            passwordPrompt.addTextField(configurationHandler: {(textField: UITextField) in
                textField.placeholder = NSLocalizedString("Confirm Password", comment: "Confirm Password")
                textField.isSecureTextEntry = true
            })
        }
        
        present(passwordPrompt, animated: true, completion: nil)
    }
    
}
