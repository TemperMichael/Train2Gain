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

class SettingsVC: UIViewController,ADBannerViewDelegate {
    
    
    @IBOutlet weak var weightUnit: UISwitch!
    
    @IBOutlet weak var lengthUnit: UISwitch!
    
    @IBOutlet weak var privacyMode: UISwitch!
    
    @IBOutlet weak var iAd: ADBannerView!
    
    
      var m_Password : String =  ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        iAd.delegate = self
        iAd.hidden = true
        //Set background
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
        weightUnit.on = NSUserDefaults.standardUserDefaults().objectForKey("weightUnit") as! String == "kg" ? true : false
        
        lengthUnit.on = NSUserDefaults.standardUserDefaults().objectForKey("lengthUnit") as! String == "cm" ? true : false
        
        weightUnit.tintColor = UIColor.whiteColor()
        lengthUnit.tintColor = UIColor.whiteColor()
        privacyMode.tintColor = UIColor.whiteColor()
        
        if let pw = NSUserDefaults.standardUserDefaults().objectForKey("Password") as? String{
            m_Password = pw
        }
        
        if(m_Password != ""){
            privacyMode.setOn(true, animated: false);
        }
   
        
    }
    
    
    override func viewDidAppear(animated: Bool) {
        if let pw = NSUserDefaults.standardUserDefaults().objectForKey("Password") as? String{
            m_Password = pw
        }

    }
    //Fit background image to display size
    func imageResize (imageObj:UIImage, sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        
        //Save chosen units
        if(weightUnit.on){
            NSUserDefaults.standardUserDefaults().setObject("kg", forKey: "weightUnit")
            
        }else{
            NSUserDefaults.standardUserDefaults().setObject("lbs", forKey: "weightUnit")
        }
        
        if(lengthUnit.on){
            NSUserDefaults.standardUserDefaults().setObject("cm", forKey: "lengthUnit")
            
        }else{
            NSUserDefaults.standardUserDefaults().setObject("inch", forKey: "lengthUnit")
            
        }
        
    }
    
    
    @IBAction func privacyModeCL(sender: AnyObject) {
        
        if(privacyMode.on){
            callPWAlert("Enter your password", single: false)
            
        }else{
            
            var context = LAContext()
            var error:NSError?
            var messageText = "Scan your fingerprint"
            
            do {
                context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error)
                context.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: messageText, reply: {
                    (success: Bool , policyError: NSError?) -> Void in
                    
                    if success {
                        NSOperationQueue.mainQueue().addOperationWithBlock(){
                             NSUserDefaults.standardUserDefaults().setObject("", forKey: "Password")
                          
                        }
                        
                    }
                        
                    else{
                        //Handl other possible situations
                        switch policyError!.code {
                            
                        case LAError.SystemCancel.rawValue :
                            
                            UIAlertView(title:"Error", message: "Authentication was cancelled by the system", delegate: self, cancelButtonTitle: "OK").show()
                            
                            
                        case LAError.UserCancel.rawValue :
                            
                             self.privacyMode.setOn(true, animated: true)
                            
                        case LAError.UserFallback.rawValue :
                            
                            self.callPWAlert("Enter your password", single: true)
                            
                        default:
                            self.callPWAlert("Enter your password", single: true)
                            
                        }
                    }
                    
                    
                })
                //If touch id is not supported
            } catch var error1 as NSError {
                error = error1
                // If the security policy cannot be evaluated then show a short message depending on the error.
                switch error!.code{
                    
                case LAError.TouchIDNotEnrolled.rawValue:
                    
                  //  UIAlertView(title:"Error", message: "TouchID is not enrolled", delegate: self, cancelButtonTitle: "OK").show()
                    
                     self.callPWAlert("Enter your password", single: true)
                    
                case LAError.PasscodeNotSet.rawValue:
                    
                    self.callPWAlert("Enter your password", single: true)
                    
                    
                default:
                    
                    self.callPWAlert("Enter your password", single: true)
                }
                
            }
            
            

            
            
        }
        
        
        
    }
    
    func callPWAlert(_Message:String, single:Bool){
        
        
        var inputTextField: UITextField?
        let passwordPrompt = UIAlertController(title: "Enter Password", message: _Message, preferredStyle: UIAlertControllerStyle.Alert)
        passwordPrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            if(self.privacyMode.on){
            self.privacyMode.setOn(false, animated: true)
            }else{
                 self.privacyMode.setOn(true, animated: true)
            }
        }))
        passwordPrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            
            if(single){
                
                let textField = passwordPrompt.textFields![0] 
                let password = textField.text
                
                
                if(password == self.m_Password){
                    self.privacyMode.setOn(false, animated: true)
                      NSUserDefaults.standardUserDefaults().setObject("", forKey: "Password")
                    
                }else{
                    
                    self.callPWAlert("Password was wrong",single: true)
                    
                }
                
            }else{
                var textField = passwordPrompt.textFields![0] 
                let password = textField.text
                textField = passwordPrompt.textFields![1] 
                let passwordConfirmend = textField.text
                
                if(password == passwordConfirmend && passwordConfirmend != ""){
                    self.m_Password = passwordConfirmend!
                    NSUserDefaults.standardUserDefaults().setObject(passwordConfirmend, forKey: "Password")
                }else{
                   
                    self.callPWAlert("Confirmed password was wrong or empty",single: false)
                }
            }
            
        }))
        passwordPrompt.addTextFieldWithConfigurationHandler({(textField: UITextField) in
            textField.placeholder = "Password"
            textField.secureTextEntry = true
            inputTextField = textField
        })
        if(single == false){
            passwordPrompt.addTextFieldWithConfigurationHandler({(textField: UITextField) in
                textField.placeholder = "Confirm Password"
                textField.secureTextEntry = true
                inputTextField = textField
            })
        }
        
        presentViewController(passwordPrompt, animated: true, completion: nil)
        
    }
    
    
    @IBAction func tutorialCL(sender: AnyObject) {
        
        let informUser = UIAlertController(title: "Tutorials", message:"Tutorials will be shown again in the views", preferredStyle: UIAlertControllerStyle.Alert)
        informUser.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
          
            NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "tutorialAddExercise")
            
            NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "tutorialMoods")
          
            NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "tutorialBodyMeasurements")
          
            NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "tutorialTrainingData")
          
            NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "tutorialTrainingPlans")
            
            
            
        }))
         presentViewController(informUser, animated: true, completion: nil)

    }
    
    // iAd Handling
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        self.layoutAnimated(true)
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        self.layoutAnimated(true)
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        return true
    }
    func layoutAnimated(animated : Bool){
        
        var contentFrame = self.view.bounds;
        var bannerFrame = iAd.frame;
        if (iAd.bannerLoaded)
        {
            iAd.hidden = false
            UIView.animateWithDuration(animated ? 0.25 : 0.0, animations: {
                
                self.iAd.alpha = 1;
            })
            
        } else {
            UIView.animateWithDuration(animated ? 0.25 : 0.0, animations: {
                self.iAd.alpha = 0
                }, completion: {
                    (value: Bool) in
                    self.iAd.hidden = true
            })
            
        }
        
        
    }


    
    
    
    
}
