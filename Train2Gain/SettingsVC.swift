//
//  SettingsVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 27.04.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import LocalAuthentication
import iAd

class SettingsVC: UIViewController, ADBannerViewDelegate {
    
    var password : String =  ""
    
    // MARK: IBOutlets & IBActions
    @IBOutlet weak var weightUnit: UISwitch!
    @IBOutlet weak var lengthUnit: UISwitch!
    @IBOutlet weak var privacyMode: UISwitch!
    @IBOutlet weak var iAd: ADBannerView!
    
    @IBAction func privacyModeCL(_ sender: AnyObject) {
        
        if privacyMode.isOn {
            callPWAlert("Enter your password", single: false)
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
                        self.privacyMode.setOn(true, animated: true)
                    case LAError.Code.userFallback.rawValue :
                        self.callPWAlert("Enter your password", single: true)
                    default :
                        self.callPWAlert("Enter your password", single: true)
                    }
                }
            })
        }
        
    }
    
    // Reset tutorial user defaults and so show them again in views
    @IBAction func tutorialCL(_ sender: AnyObject) {
        
        let informUser = UIAlertController(title: "Tutorials", message: "Tutorials will be shown again in the views", preferredStyle: UIAlertControllerStyle.alert)
        informUser.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            UserDefaults.standard.set(nil, forKey: "tutorialAddExercise")
            UserDefaults.standard.set(nil, forKey: "tutorialMoods")
            UserDefaults.standard.set(nil, forKey: "tutorialBodyMeasurements")
            UserDefaults.standard.set(nil, forKey: "tutorialTrainingData")
            UserDefaults.standard.set(nil, forKey: "tutorialTrainingPlans")
        }))
        present(informUser, animated: true, completion: nil)
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //Handle iAd
        iAd.delegate = self
        iAd.isHidden = true
        
        //Set background
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        weightUnit.isOn = UserDefaults.standard.object(forKey: "weightUnit") as! String == "kg" ? true : false
        lengthUnit.isOn = UserDefaults.standard.object(forKey: "lengthUnit") as! String == "cm" ? true : false
        weightUnit.tintColor = UIColor.white
        lengthUnit.tintColor = UIColor.white
        privacyMode.tintColor = UIColor.white
        
        //Get password
        if let pw = UserDefaults.standard.object(forKey: "Password") as? String {
            password = pw
        }
        if password != "" {
            privacyMode.setOn(true, animated: false)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if let pw = UserDefaults.standard.object(forKey: "Password") as? String{
            password = pw
        }
        
    }
    
    //Show correct background after rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(true)
        
        //Save chosen units
        if weightUnit.isOn {
            UserDefaults.standard.set("kg", forKey: "weightUnit")
        } else {
            UserDefaults.standard.set("lbs", forKey: "weightUnit")
        }
        if lengthUnit.isOn {
            UserDefaults.standard.set("cm", forKey: "lengthUnit")
        } else {
            UserDefaults.standard.set("inch", forKey: "lengthUnit")
        }
        
    }
    
    // MARK: My Methods
    // Fit background image to display size
    func imageResize(_ imageObj: UIImage, sizeChange: CGSize) -> UIImage {
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
        
    }

    // Create password dialog: single = false for setup password
    //                        single = true for entering password
    func callPWAlert(_ _Message: String, single: Bool) {
        
        var inputTextField: UITextField?
        let passwordPrompt = UIAlertController(title: NSLocalizedString("Enter Password", comment: "Enter Password"), message: _Message, preferredStyle: UIAlertControllerStyle.alert)
        passwordPrompt.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.default, handler: { (action) -> Void in
            if self.privacyMode.isOn {
                self.privacyMode.setOn(false, animated: true)
            } else {
                self.privacyMode.setOn(true, animated: true)
            }
        }))
        passwordPrompt.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.default, handler: { (action) -> Void in
            //Enter password
            if single {
                let textField = passwordPrompt.textFields![0]
                let password = textField.text
                if password == self.password {
                    self.privacyMode.setOn(false, animated: true)
                    UserDefaults.standard.set("", forKey: "Password")
                } else {
                    self.callPWAlert(NSLocalizedString("Password was wrong", comment: "Password was wrong"),single: true)
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
                    self.callPWAlert(NSLocalizedString("Confirmed password was wrong or empty", comment: "Confirmed password was wrong or empty"),single: false)
                }
            }
        }))
        passwordPrompt.addTextField(configurationHandler: {(textField: UITextField) in
            textField.placeholder = NSLocalizedString("Password", comment: "Password")
            textField.isSecureTextEntry = true
            inputTextField = textField
        })
        if single == false {
            passwordPrompt.addTextField(configurationHandler: {(textField: UITextField) in
                textField.placeholder = NSLocalizedString("Confirm Password", comment: "Confirm Password")
                textField.isSecureTextEntry = true
                inputTextField = textField
            })
        }
        present(passwordPrompt, animated: true, completion: nil)
        
    }
    
    // MARK: iAd
    func bannerViewDidLoadAd(_ banner: ADBannerView!) {
        
        self.layoutAnimated(true)
        
    }
    
    func bannerView(_ banner: ADBannerView!, didFailToReceiveAdWithError error: Error!) {
        
        self.layoutAnimated(true)
        
    }
    
    func bannerViewActionShouldBegin(_ banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        
        return true
    }
    
    func layoutAnimated(_ animated: Bool) {
        
        if iAd.isBannerLoaded {
            iAd.isHidden = false
            UIView.animate(withDuration: animated ? 0.25 : 0.0, animations: {
                self.iAd.alpha = 1;
            })
        } else {
            UIView.animate(withDuration: animated ? 0.25 : 0.0, animations: {
                self.iAd.alpha = 0
                }, completion: {
                    (value: Bool) in
                    self.iAd.isHidden = true
            })
        }
        
    }
}
