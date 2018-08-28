//
//  OverviewTVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 27.03.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import LocalAuthentication

class OverviewTVC: UITableViewController {
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var cellIdentifier = "OverviewCell"
    var menuPoints: [String] = [NSLocalizedString("Training", comment: "Training"),  NSLocalizedString("Body measurements", comment: "Body measurements"), NSLocalizedString("Mood", comment: "Mood"), NSLocalizedString("Training data", comment: "Training data"), NSLocalizedString("Statistic", comment: "Statistic"), NSLocalizedString("Settings", comment: "Settings")]
    var password: String =  ""
    var selectedSection: String = ""
    
    // MARK: View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupView()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
    }
    
    // MARK: TableView Methods
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuPoints.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return setupCell(tableView, indexPath)
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        handleRowSelection(indexPath)
        return indexPath
    }
    
    // MARK: Own Methods

    func checkFingerprint() {
        var error: NSError?
        let context = LAContext()
        let messageText = NSLocalizedString("Scan your fingerprint", comment: "Scan your fingerprint")
        
        context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error)
        context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: messageText, reply: { [weak self]
            (success: Bool , policyError: Error?) -> Void in
            self?.handleFingerprintBehaviour(success, policyError)
        })
    }
    
    // Create password dialog: single = false for setup password
    //                         single = true for entering password
    func showPasswordAlert(_ _Message: String, single: Bool) {
        let passwordPrompt = UIAlertController(title: NSLocalizedString("Enter Password", comment: "Enter Password"), message: _Message, preferredStyle: UIAlertControllerStyle.alert)
        
        passwordPrompt.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.default, handler: nil))
        passwordPrompt.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.default, handler: { (action) -> Void in
            //Enter password
            if single {
                let textField = passwordPrompt.textFields![0] 
                let password = textField.text
                if password == self.password {
                    self.performSegue(withIdentifier: self.selectedSection, sender: self)
                } else {
                    self.showPasswordAlert(NSLocalizedString("Password was wrong", comment: "Password was wrong"),single: true)
                }
            } else {
                // Setup password
                var textField = passwordPrompt.textFields![0] 
                let password = textField.text
                textField = passwordPrompt.textFields![1] 
                let passwordConfirmend = textField.text
                if password == passwordConfirmend {
                    self.password = passwordConfirmend!
                    UserDefaults.standard.set(passwordConfirmend, forKey: "Password")
                } else {
                    self.showPasswordAlert(NSLocalizedString("Confirmed password was wrong or empty", comment: "Confirmed password was wrong or empty"), single: false)
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
    
    func setupCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        // Setup cells
        cell.textLabel?.text = menuPoints[(indexPath as NSIndexPath).row]
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 18)
        cell.textLabel?.textAlignment = .center
        self.tableView.rowHeight = (self.tableView.frame.height / CGFloat(menuPoints.count)) - 10
        
        // Set Seperator left to zero
        cell.separatorInset = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsets.zero
        return cell
    }
    
    func setupView() {
        appDelegate.shouldRotate = false
        
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
            appDelegate.shouldRotate = true
        }
        
        // Get and save actual date
        UserDefaults.standard.set(Date(), forKey: "dateUF")
        
        // Get actual pw if one is set
        if let pw = UserDefaults.standard.object(forKey: "Password") as? String{
            password = pw
        }
    }
    
    func handleRowSelection(_ indexPath: IndexPath) {
        switch (indexPath as NSIndexPath).row {
        case 0:
            performSegue(withIdentifier: "ExerciseSegue", sender: self)
        case 1:
            performSegue(withIdentifier: "MeasurementSegue", sender: self)
        case 2:
            performSegue(withIdentifier: "MoodSegue", sender: self)
        case 3:
            if password != "" {
                selectedSection = "TrainingData"
                self.checkFingerprint()
            } else {
                self.performSegue(withIdentifier: "TrainingData", sender: self)
            }
        case 4:
            if password != "" {
                selectedSection = "Statistic"
                self.checkFingerprint()
            } else {
                self.performSegue(withIdentifier: "Statistic", sender: self)
            }
        case 5:
            performSegue(withIdentifier: "Settings", sender: self)
        default:
            print("Error", terminator: "")
        }
    }
    
    func handleFingerprintBehaviour(_ success: Bool, _ policyError: Error?) {
        if success {
            OperationQueue.main.addOperation() {
                // Open training data if right touch id was entered
                if self.selectedSection == "TrainingData" {
                    self.performSegue(withIdentifier: self.selectedSection, sender: self)
                } else {
                    self.performSegue(withIdentifier: self.selectedSection, sender: self)
                }
            }
        } else {
            // Handle other possible situations
            switch policyError!._code {
            case LAError.Code.systemCancel.rawValue:
                UIAlertView(title:"Error", message: NSLocalizedString("Authentication was cancelled by the system", comment: "Authentication was cancelled by the system"), delegate: self, cancelButtonTitle: "OK").show()
            case LAError.Code.userCancel.rawValue:
                print("Authentication was cancelled by the user")
            case LAError.Code.userFallback.rawValue:
                self.showPasswordAlert(NSLocalizedString("Enter your password", comment: "Enter your password"), single: true)
            default:
                self.showPasswordAlert(NSLocalizedString("Enter your password", comment: "Enter your password"), single: true)
            }
        }
    }
    
}
