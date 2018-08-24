//
//  AddExerciseVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 29.03.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import CoreData
import iAd
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


class TrainingPlanCreationVC: UIViewController, UITextFieldDelegate, ADBannerViewDelegate {
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var dayId: String = ""
    var deleteOn: Bool = false
    var editDayIDSaver = ""
    var editMode = false
    var exercises: [[String]] = [["", "", ""]]
    var selectedExercise: [Exercise] = []
    var userPosition: Int = 0
    
    // MARK: IBOutles & IBActions
    @IBOutlet weak var addExerciseButton: UIButton!
    @IBOutlet weak var deleteExerciseButton: UIButton!
    @IBOutlet weak var iAd: ADBannerView!
    @IBOutlet weak var nextExerciseButton: UIButton!
    @IBOutlet weak var previousExerciseButton: UIButton!
    @IBOutlet weak var trainingPlanNameTextField: UITextField!
    @IBOutlet weak var trainingPlanRepsTextField: UITextField!
    @IBOutlet weak var trainingPlanSetsTextField: UITextField!
    @IBOutlet weak var trainingPlanExerciseNameTextField: UITextField!
    
    @IBAction func addExercise(_ sender: AnyObject) {
        if isAllFilled() {
            exercises[userPosition] = [trainingPlanExerciseNameTextField.text!, trainingPlanRepsTextField.text!, trainingPlanSetsTextField.text!]
            exercises.insert(["", "", ""], at: userPosition+1)
            filterSpecificView(false)
            clearDetails()
        }
    }
    
    @IBAction func deleteExercise(_ sender: AnyObject) {
        exercises.remove(at: userPosition)
        deleteOn = true
        if userPosition > 0 {
            filterSpecificView(true)
        } else {
            filterSpecificView(false)
        }
    }
    
    @IBAction func saveTrainingPlan(_ sender: AnyObject) {
        // Save all created exercises
        if isAllFilled() {
            dayId = trainingPlanNameTextField.text!
            exercises[userPosition] = [trainingPlanExerciseNameTextField.text!, trainingPlanRepsTextField.text!, trainingPlanSetsTextField.text!]
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Exercise")
            let exercisesCD = (try! appDelegate.managedObjectContext?.fetch(request)) as! [Exercise]
            
            // In edit mode remove old saved exercises and add the new edited one
            if editMode {
                for singleExCD in exercisesCD {
                    if singleExCD.dayID == editDayIDSaver {
                        appDelegate.managedObjectContext!.delete(singleExCD as NSManagedObject)
                    }
                }
            }
            appDelegate.saveContext()
            for checkCells in self.exercises {
                let newItem = NSEntityDescription.insertNewObject(forEntityName: "Exercise", into: appDelegate.managedObjectContext!) as! Exercise
                newItem.dayID = dayId
                print(checkCells[0])
                newItem.name = checkCells[0]
                newItem.reps = Int(checkCells[1])! as NSNumber
                newItem.sets = Int(checkCells[2])! as NSNumber
                appDelegate.saveContext()
            }
            let informUser = UIAlertController(title: "Saved", message: "Your training plan was saved", preferredStyle: UIAlertControllerStyle.alert)
            informUser.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                self.navigationController?.popViewController(animated: true)
            }))
            present(informUser, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func showPreviousExercise(_ sender: AnyObject) {
        exercises[userPosition] = [trainingPlanExerciseNameTextField.text!, trainingPlanRepsTextField.text!, trainingPlanSetsTextField.text!]
        filterSpecificView(true)
    }
    
    @IBAction func showNextExercise(_ sender: AnyObject) {
        
        exercises[userPosition] = [trainingPlanExerciseNameTextField.text!, trainingPlanRepsTextField.text!, trainingPlanSetsTextField.text!]
        filterSpecificView(false)
        
    }
    
    // MARK: View Methods
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Handle iAd
        iAd.delegate = self
        iAd.isHidden = true
        
        // Set background
        var backgroundImage = UIImage(named: "Background2.png")
        backgroundImage = imageResize(backgroundImage!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundImage!)
        
        // Set delegates of textfields
        trainingPlanRepsTextField.delegate = self
        trainingPlanSetsTextField.delegate = self
        trainingPlanExerciseNameTextField.delegate = self
        trainingPlanNameTextField.delegate = self
        
        
        //Prepare data if view was opened in edit mode
        if editMode {
            self.title = NSLocalizedString("Edit Training plan", comment: "Edit Training plan")
            editDayIDSaver = selectedExercise[0].dayID
            var currentName = ""
            var first = true
            var prevName = ""
            for singleEx in selectedExercise {
                prevName = currentName
                currentName = singleEx.name
                if prevName != currentName {
                    if first {
                        exercises[userPosition] = [singleEx.name, "\(singleEx.reps)", "\(singleEx.sets)"]
                        trainingPlanNameTextField.text = singleEx.dayID
                        first = false
                    } else {
                        exercises.append([singleEx.name, "\(singleEx.reps)", "\(singleEx.sets)"])
                    }
                    trainingPlanExerciseNameTextField.text = exercises[userPosition][0]
                    trainingPlanRepsTextField.text = exercises[userPosition][1]
                    trainingPlanSetsTextField.text = exercises[userPosition][2]
                }
            }
        }
        
        if exercises.count <= 1 {
            deleteExerciseButton.isEnabled = false
            nextExerciseButton.isEnabled = false
            nextExerciseButton.setTitle("", for: UIControlState())
        }
        previousExerciseButton.isEnabled = false
        previousExerciseButton.setTitle("", for: UIControlState())
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    // Show correct background after rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        var backgroundImage = UIImage(named: "Background2.png")
        backgroundImage = imageResize(backgroundImage!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundImage!)
    }
    
    // MARK: Keyboard Methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Close Keyboard when clicking outside
        trainingPlanExerciseNameTextField.resignFirstResponder()
        trainingPlanSetsTextField.resignFirstResponder()
        trainingPlanRepsTextField.resignFirstResponder()
        trainingPlanNameTextField.resignFirstResponder()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Push up view to see what you are actual entering
        switch textField {
        case trainingPlanRepsTextField:
            self.view.frame.origin.y -= 80
        case trainingPlanSetsTextField:
            self.view.frame.origin.y -= 80
        case trainingPlanExerciseNameTextField:
            self.view.frame.origin.y -= 20
        default:
            print("Error keyboard")
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Put view back down after entering in text fields
        switch textField {
        case trainingPlanRepsTextField:
            self.view.frame.origin.y += 80
        case trainingPlanSetsTextField:
            self.view.frame.origin.y += 80
        case trainingPlanExerciseNameTextField:
            self.view.frame.origin.y += 20
        default:
            print("Error keyboard")
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Jump to next textfield by clicking on "next" button
        if string == "\n" {
            textField.endEditing(true)
            switch textField {
            case trainingPlanNameTextField:
                trainingPlanExerciseNameTextField.becomeFirstResponder()
            case trainingPlanExerciseNameTextField:
                trainingPlanSetsTextField.becomeFirstResponder()
            default:
                print("Error keyboard")
            }
            return true
        }
        textField.backgroundColor = UIColor.white
        textField.placeholder = ""
        let text = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        // Setup input settings
        let newLength = textField.text!.count + string.count - range.length
        var back = 0
        if textField == trainingPlanRepsTextField {
            back = 2
            if newLength <= back && ((Int(text) > 0 && Int(text) < 100) || text == "") {
                return true
            } else {
                return false
            }
        } else if textField == trainingPlanSetsTextField {
            back = 1
            if newLength <= back && ((Int(text) > 0 && Int(text) < 10) || text == "") {
                return true
            } else {
                return false
            }
        } else {
            back = 13
        }
        return newLength <= back
    }
    
    // Fit background image to display size
    func imageResize(_ imageObj: UIImage, sizeChange: CGSize) -> UIImage {
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
    }
    
    // Check if everything was entered
    func isAllFilled() -> Bool {
        var check = true
        if trainingPlanNameTextField.text == "" {
            trainingPlanNameTextField.backgroundColor = UIColor(red: 218 / 255, green: 52 / 255, blue: 60 / 255, alpha: 1)
            trainingPlanNameTextField.placeholder = NSLocalizedString("Enter something!", comment: "Enter something!")
            check = false
        }
        if trainingPlanRepsTextField.text == "" {
            trainingPlanRepsTextField.backgroundColor = UIColor(red: 218 / 255 , green: 52 / 255, blue: 60 / 255, alpha: 1)
            trainingPlanRepsTextField.placeholder = NSLocalizedString("Enter sth.!", comment: "Enter sth.!")
            check = false
        }
        if trainingPlanExerciseNameTextField.text == "" {
            trainingPlanExerciseNameTextField.backgroundColor = UIColor(red: 218 / 255, green: 52 / 255, blue: 60 / 255, alpha: 1)
            trainingPlanExerciseNameTextField.placeholder = NSLocalizedString("Enter sth.!", comment: "Enter sth.!")
            check = false
        }
        if trainingPlanSetsTextField.text == "" {
            trainingPlanSetsTextField.backgroundColor = UIColor(red: 218 / 255, green: 52 / 255, blue: 60 / 255, alpha: 1)
            trainingPlanSetsTextField.placeholder = NSLocalizedString("Enter sth.!", comment: "Enter sth.!")
            check = false
        }
        return check
    }
    
    func clearDetails() {
        trainingPlanExerciseNameTextField.text = ""
        trainingPlanRepsTextField.text = ""
        trainingPlanSetsTextField.text = ""
    }
    
    func filterSpecificView(_ animationDirection: Bool) {
        if deleteOn || isAllFilled() {
            dayId = trainingPlanNameTextField.text!
            for view in self.view.subviews {
                if view.tag == 123 {
                    // Start animation
                    slideIn(1, completionDelegate: view, direction: animationDirection)
                    
                    // Load in next exercise
                    if deleteOn && !animationDirection {
                        userPosition = 0
                    }
                    
                    trainingPlanExerciseNameTextField.text = exercises[userPosition][0]
                    trainingPlanRepsTextField.text = exercises[userPosition][1]
                    trainingPlanSetsTextField.text = exercises[userPosition][2]
                    
                    // Enable/Disable buttons
                    if userPosition > 0 {
                        previousExerciseButton.isEnabled = true
                        previousExerciseButton.setTitle("<", for: UIControlState())
                        deleteExerciseButton.isEnabled = true
                    } else {
                        previousExerciseButton.isEnabled = false
                        previousExerciseButton.setTitle("", for: UIControlState())
                    }
                    
                    if exercises.count <= 1 {
                        deleteExerciseButton.isEnabled = false
                    }
                    
                    if userPosition + 1 < exercises.count {
                        nextExerciseButton.isEnabled = true
                        nextExerciseButton.setTitle(">", for: UIControlState())
                    } else {
                        nextExerciseButton.isEnabled = false
                        nextExerciseButton.setTitle("", for: UIControlState())
                    }
                }
            }
            
            deleteOn = false
        }
    }
    
    func slideIn(_ duration: TimeInterval = 1.0, completionDelegate: AnyObject? = nil, direction:Bool) {
        trainingPlanExerciseNameTextField.backgroundColor = UIColor.white
        trainingPlanSetsTextField.backgroundColor = UIColor.white
        trainingPlanRepsTextField.backgroundColor = UIColor.white
        
        // Create a CATransition animation
        let slideInTransition = CATransition()
        
        // Set its callback delegate to the completionDelegate that was provided (if any)
        if let delegate = completionDelegate as? CAAnimationDelegate {
            slideInTransition.delegate = delegate
        }
        
        // Customize the animation's properties
        slideInTransition.type = kCATransitionMoveIn
        if direction {
            userPosition -= 1
            slideInTransition.subtype = kCATransitionFromLeft
        } else {
            userPosition += 1
            slideInTransition.subtype = kCATransitionFromRight
        }
        slideInTransition.duration = duration
        slideInTransition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        slideInTransition.fillMode = kCAFillModeRemoved
        
        // Add the animation to the View's layer
        (completionDelegate as! UIView).layer.add(slideInTransition, forKey: "slideInTransition")
        
    }
    
    // MARK: iAd
    func bannerViewDidLoadAd(_ banner: ADBannerView) {
        self.layoutAnimated(true)
    }
    
    func bannerView(_ banner: ADBannerView, didFailToReceiveAdWithError error: Error) {
        self.layoutAnimated(true)
    }
    
    func bannerViewActionShouldBegin(_ banner: ADBannerView, willLeaveApplication willLeave: Bool) -> Bool {
        return true
    }
    
    func layoutAnimated(_ animated: Bool) {
        if iAd.isBannerLoaded {
            iAd.isHidden = false
            UIView.animate(withDuration: animated ? 0.25 : 0.0, animations: {
                self.iAd.alpha = 1
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
