//
//  OverViewTVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 27.03.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import LocalAuthentication

class OverViewTVC: UITableViewController {
    
    var m_string_MenuPoints : [String] = ["Training","Body measurements","Mood","Training data","Statistic","Settings"]
    
    var m_Password : String =  ""
    var selectedSection:String = ""
    
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate.shouldRotate = false
        tableView.scrollEnabled = false
        
        
        
        //Set toolbar background transparent
        self.navigationController?.toolbar.setBackgroundImage(UIImage(),
            forToolbarPosition: UIBarPosition.Any,
            barMetrics: UIBarMetrics.Default)
        self.navigationController?.toolbar.setShadowImage(UIImage(),
            forToolbarPosition: UIBarPosition.Any)
        
        tableView.reloadData()
        
        //Remove text from back button
        let backButton = UIBarButtonItem(title: " ", style: UIBarButtonItemStyle.Plain, target: self, action: nil)
        backButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Chalkduster", size: 20)!], forState: UIControlState.Normal)
        navigationItem.backBarButtonItem = backButton
        
        
        
        //Get the actual chosen units
        if(NSUserDefaults.standardUserDefaults().objectForKey("weightUnit") == nil ){
            NSUserDefaults.standardUserDefaults().setObject("lbs", forKey: "weightUnit")
            
        }
        if(NSUserDefaults.standardUserDefaults().objectForKey("lengthUnit") == nil ){
            
            NSUserDefaults.standardUserDefaults().setObject("inch", forKey: "lengthUnit")
            
        }
        
        //Get actual pw if one is set
        if let pw = NSUserDefaults.standardUserDefaults().objectForKey("Password") as? String{
            m_Password = pw
        }
 
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
 
    }
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_string_MenuPoints.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("MenuPointCell", forIndexPath: indexPath) 
        
        
        //Setup cells
        
        cell.textLabel?.text = m_string_MenuPoints[indexPath.row]
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 18)
        cell.textLabel?.textAlignment = .Center
    
        self.tableView.rowHeight = (self.tableView.frame.height / 6) - 10
        
        
        //Set Seperator left to zero
        cell.separatorInset = UIEdgeInsetsZero
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsetsZero
        
        
        return cell
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        //Set colors of cells
        cell.backgroundColor = UIColor(red:22/255 ,green:200/255, blue:1.00 ,alpha:1.0)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        appDelegate.shouldRotate = false
        //Hide empty cells
        let backgroundView = UIView(frame: CGRectZero)
        
        self.tableView.tableFooterView = backgroundView
        
        self.tableView.backgroundColor = UIColor(red:22/255 ,green:200/255, blue:1.00 ,alpha:1.0)
        
        //Get and save actual date
        NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: "dateUF")
        //Get actual pw if one is set
        if let pw = NSUserDefaults.standardUserDefaults().objectForKey("Password") as? String{
            m_Password = pw
        }
        
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        
        switch indexPath.row{
        case 0:
            performSegueWithIdentifier("ExerciseSegue", sender: self)
            break;
        case 1:
            performSegueWithIdentifier("MeasurementSegue", sender: self)
            break;
        case 2:
            performSegueWithIdentifier("MoodSegue", sender: self)
            break;
        case 3:
          
            if(m_Password != ""){
                selectedSection = "TrainingData"
                self.checkPassword();
            }else{
                  self.performSegueWithIdentifier("TrainingData", sender: self)
            }
        case 4:
            if(m_Password != ""){
                selectedSection = "Statistic"
                self.checkPassword();
            }else{
                self.performSegueWithIdentifier("Statistic", sender: self)
            }
        case 5:
            performSegueWithIdentifier("Settings", sender: self)
            
        default:
            print("Error", terminator: "")
        }
        
        return indexPath
    }
    
    func checkPassword(){
        
        //let cell = tableView.dequeueReusableCellWithIdentifier("MenuPointCell", forIndexPath: indexPath) as! UITableViewCell
        
        let context = LAContext()
        var error:NSError?
        
        let messageText = "Scan your fingerprint"
        
        do {
           context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error)
            context.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: messageText, reply: {
                (success: Bool , policyError: NSError?) -> Void in
                
                if success {
                    NSOperationQueue.mainQueue().addOperationWithBlock(){
                        
                        //Open training data if right touch id was entered
                        
                        if(self.selectedSection == "TrainingData"){
                            self.performSegueWithIdentifier(self.selectedSection, sender: self)
                        }else{
                             self.performSegueWithIdentifier(self.selectedSection, sender: self)
                        }
                    }
                    
                }
                    
                else{
                    //Handl other possible situations
                    switch policyError!.code {
                        
                    case LAError.SystemCancel.rawValue :
                        
                        UIAlertView(title:"Error", message: "Authentication was cancelled by the system", delegate: self, cancelButtonTitle: "OK").show()
                        
                        
                    case LAError.UserCancel.rawValue :
                        
                        print("Authentication was cancelled by the user")
                        
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
                
                self.callPWAlert("Enter your password", single: true)
                
            case LAError.PasscodeNotSet.rawValue:
                
                self.callPWAlert("Enter your password", single: true)
                
                
            default:
                
                self.callPWAlert("Enter your password", single: true)
            }
            
        }
        

    }
    
    //Create password dialog - single = false for setup password - single = true for entering password
    func callPWAlert(_Message:String, single:Bool){
        
        
        var inputTextField: UITextField?
        let passwordPrompt = UIAlertController(title: "Enter Password", message: _Message, preferredStyle: UIAlertControllerStyle.Alert)
        passwordPrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        passwordPrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            
            if(single){
                
                let textField = passwordPrompt.textFields![0] 
                let password = textField.text
              
                
                if(password == self.m_Password){
                    self.performSegueWithIdentifier(self.selectedSection, sender: self)

                }else{
                    
                    self.callPWAlert("Password was wrong",single: true)
                }
                
            }else{
                var textField = passwordPrompt.textFields![0] 
                let password = textField.text
                textField = passwordPrompt.textFields![1] 
                let passwordConfirmend = textField.text
                
                if(password == passwordConfirmend){
                    self.m_Password = passwordConfirmend!
                    NSUserDefaults.standardUserDefaults().setObject(passwordConfirmend, forKey: "Password")
                }else{
                    
                    self.callPWAlert("Confirmed password was wrong",single: false)
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

};