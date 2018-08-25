//
//  ExerciseChosenVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 29.03.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import CoreData
import Fabric
import Crashlytics

class TrainingModeVC: UIViewController, UITextFieldDelegate {
    
    var appDelegate =  UIApplication.shared.delegate as! AppDelegate
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
    var currentTime: TimeInterval?
    var date = UserDefaults.standard.object(forKey: "dateUF") as! Date
    var dates: [Dates] = []
    var exercisesWithSets: [Exercise] = []
    var lengthUnit = UserDefaults.standard.object(forKey: "lengthUnit")! as! String
    var saveCurrentTime: TimeInterval?
    var savedEnteredExercises: [[String]] = []
    var startTime = TimeInterval()
    var selectedExercise: [Exercise] = []
    var setCounter: [Int] = []
    var timer = Timer()
    var wasStopped = true
    var weightUnit = UserDefaults.standard.object(forKey: "weightUnit")! as! String
    var userPosition: Int = 0
    
    // MARK: IBOutlets & IBActions
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datePickerBackgroundView: UIView!
    @IBOutlet weak var datePickerButton: UIButton!
    @IBOutlet weak var datePickerTitleLabel: UILabel!
    @IBOutlet weak var exerciseNameLabel: UILabel!
    @IBOutlet weak var exerciseRepsLabel: UILabel!
    @IBOutlet weak var exerciseRepsTextField: UITextField!
    @IBOutlet weak var exerciseSetLabel: UILabel!
    @IBOutlet weak var exerciseTrainingPlanNameLabel: UILabel!
    @IBOutlet weak var exerciseWeightsLabel: UILabel!
    @IBOutlet weak var exerciseWeightsTextField: UITextField!
    @IBOutlet weak var nextExerciseButton: UIButton!
    @IBOutlet weak var previousExerciseButton: UIButton!
    @IBOutlet weak var selectDateButton: UIButton!
    @IBOutlet weak var stopWatchLabel: UILabel!
    
    
    @IBAction func breakStopWatch(_ sender: AnyObject) {
        if !wasStopped {
            saveCurrentTime = startTime -  Date.timeIntervalSinceReferenceDate
            timer.invalidate()
        }
    }
    
    @IBAction func saveTrainingPlan(_ sender: AnyObject) {
        
        var weight = (exerciseWeightsTextField.text! as NSString).doubleValue
        
        // Save all in kg
        if weightUnit == "lbs" {
            weight = weight /  2.20462262185
        }
        
        // If nothing was entered save zero as weight and rep value
        exercisesWithSets[userPosition].weight =  exerciseWeightsTextField.text != "" ?  NSDecimalNumber(value: weight as Double) : 0
        exercisesWithSets[userPosition].doneReps = exerciseRepsTextField.text != "" ?  NSDecimalNumber(string: exerciseRepsTextField.text) : 0
        var alreadyExists = true
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Dates")
        dates = (try! appDelegate.managedObjectContext?.fetch(request))  as! [Dates]
        for i in 0  ..< dates.count {
            if returnDateForm(dates[i].savedDate as Date) == returnDateForm(date) {
                alreadyExists = false
            }
        }
        var saveData: [[String]] = []
        for i in 0  ..< exercisesWithSets.count {
            saveData.append([exercisesWithSets[i].dayID, exercisesWithSets[i].name, "\(exercisesWithSets[i].reps)", "\(exercisesWithSets[i].doneReps)", "\(exercisesWithSets[i].sets)", "\(exercisesWithSets[i].weight)"])
            
        }
        
        // Rollback to don't save exerices which were needed to get done exercises
        appDelegate.rollBackContext()
        
        //Replace date
        if alreadyExists {
            let newItem = NSEntityDescription.insertNewObject(forEntityName: "Dates", into: appDelegate.managedObjectContext!) as! Dates
            newItem.savedDate = date
        }
        var i = 0
        
        //Save data
        for checkCells in saveData {
            let newItem = NSEntityDescription.insertNewObject(forEntityName: "DoneExercise", into: appDelegate.managedObjectContext!) as! DoneExercise
            newItem.date = date
            newItem.dayID = checkCells[0]
            newItem.name = checkCells[1]
            newItem.reps = NSDecimalNumber(string: checkCells[2])
            newItem.doneReps = NSDecimalNumber(string:checkCells[3])
            newItem.sets = NSDecimalNumber(string:checkCells[4])
            newItem.weight = NSDecimalNumber(string: checkCells[5])
            newItem.setCounter = NSNumber(value: setCounter[i])
            appDelegate.saveContext()
            i += 1
        }
        
        
        let informUser = UIAlertController(title: NSLocalizedString("Saved", comment: "Saved"), message:NSLocalizedString("Your training was saved", comment: "Your training was saved"), preferredStyle: UIAlertControllerStyle.alert)
        informUser.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.navigationController?.popViewController(animated: true)
        }))
        
        //Fabric - Analytic tool
        Answers.logLevelEnd("Finished Training",
                            score: nil,
                            success: true,
                            customAttributes: ["Training name": saveData[0][0]])
        present(informUser, animated: true, completion: nil)
        
    }
    
    @IBAction func selectDate(_ sender: AnyObject) {
        date = datePicker.date
        UserDefaults.standard.set(datePicker.date,forKey: "dateUF")
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.datePickerBackgroundView.alpha = 0
        }, completion: { finished in
            self.datePickerBackgroundView.isHidden = true
        })
        datePickerButton.setTitle(returnDateForm(date), for: UIControlState())
    }
    
    @IBAction func showDatePicker(_ sender: AnyObject) {
        setupPickerView()
    }
    
    @IBAction func showNextDay(_ sender: AnyObject) {
        date = date.addingTimeInterval(60 * 60 * 24)
        UserDefaults.standard.set(date, forKey: "dateUF")
        datePickerButton.setTitle(returnDateForm(date), for: UIControlState())
    }
    
    @IBAction func showNextExercise(_ sender: AnyObject) {
        filterSpecificView(false)
    }
    
    @IBAction func showPreviousDay(_ sender: AnyObject) {
        date = date.addingTimeInterval(-60 * 60 * 24)
        UserDefaults.standard.set(date, forKey: "dateUF")
        datePickerButton.setTitle(returnDateForm(date), for: UIControlState())
    }
    
    @IBAction func showPreviousExercise(_ sender: AnyObject) {
        filterSpecificView(true)
    }
    
    @IBAction func startStopWatch(_ sender: AnyObject) {
        if !timer.isValid {
            let updateTimeSelector : Selector = #selector(TrainingModeVC.updateTime)
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: updateTimeSelector, userInfo: nil, repeats: true)
            if wasStopped {
                startTime = Date.timeIntervalSinceReferenceDate
                wasStopped = false
            } else {
                startTime =  saveCurrentTime! +  Date.timeIntervalSinceReferenceDate
            }
        }
    }
    
    @IBAction func stopStopWatch(_ sender: AnyObject) {
        wasStopped = true
        timer.invalidate()
    }
    
    
   
    
    
    // MARK: View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup background
        let backgroundSize = CGSize(width: view.frame.width, height: view.frame.height)
        var backgroundImage = UIImage(named: "Background2.png")
        backgroundImage = imageResize(backgroundImage!, sizeChange: backgroundSize)
        self.view.backgroundColor = UIColor(patternImage: backgroundImage!)
        
        // Setup start view
        exerciseTrainingPlanNameLabel.text = selectedExercise[0].dayID
        exerciseWeightsLabel.text = weightUnit
        
        Answers.logLevelStart("Started training", customAttributes: ["Training name": selectedExercise[0].dayID])
        
        //Load in exercises as many sets they have
        for item in selectedExercise as [Exercise] {
            for i in 0..<(item.sets as! Int) {
                setCounter.append(i + 1)
                let newItem = Exercise()
                newItem.dayID = item.dayID
                newItem.sets = item.sets
                newItem.reps = item.reps
                newItem.name = item.name
                newItem.weight = item.weight
                newItem.doneReps = item.doneReps
                exercisesWithSets.append(newItem)
            }
        }
        
        //Set View start contents
        exerciseNameLabel.text = exercisesWithSets[0].name
        if (exercisesWithSets[0].reps as! Int) < 10 {
            exerciseRepsLabel.text = "  / \(exercisesWithSets[0].reps)"
        } else {
            exerciseRepsLabel.text = " /\(exercisesWithSets[0].reps)"
        }
        previousExerciseButton.isEnabled = false
        previousExerciseButton.setTitle("", for: UIControlState())
        if exercisesWithSets.count < 2 {
            nextExerciseButton.isEnabled = false
            nextExerciseButton.setTitle("", for: UIControlState())
        }
        
        //Set delegate of textfields
        exerciseRepsTextField.delegate = self
        exerciseWeightsTextField.delegate = self
        
        datePicker.setDate(UserDefaults.standard.object(forKey: "dateUF") as! Date, animated: true)
        datePicker.forBaselineLayout().setValue(UIColor.white, forKeyPath: "tintColor")
        for subview in datePicker.subviews {
            subview.setValue(UIColor.white, forKeyPath: "textColor")
            subview.setValue(UIColor.white, forKey: "tintColor")
        }
        
        datePickerTitleLabel.text = NSLocalizedString("Choose a date", comment: "Choose a date")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        exercisesWithSets = []
        date = UserDefaults.standard.object(forKey: "dateUF") as! Date
        datePickerButton.setTitle(returnDateForm(date), for: UIControlState())
        for item in selectedExercise as [Exercise] {
            for i in 0..<(item.sets as! Int) {
                setCounter.append(i + 1)
                let newItem = Exercise()
                newItem.dayID = item.dayID
                newItem.sets = item.sets
                newItem.reps = item.reps
                newItem.name = item.name
                newItem.weight = item.weight
                newItem.doneReps = item.doneReps
                exercisesWithSets.append(newItem)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Answers.logLevelEnd("Canceled Training",
                            score: nil,
                            success: true,
                            customAttributes: ["Training name": exerciseTrainingPlanNameLabel.text!])
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        appDelegate.rollBackContext()
    }
    
    // MARK: Own Methods
    // Fit background image to display size
    func imageResize(_ imageObj:UIImage, sizeChange: CGSize) -> UIImage {
        let hasAlpha = false
        let scale: CGFloat = 0.0
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
    }
    
    func filterSpecificView(_ animationDirection: Bool) {
        for view in self.view.subviews {
            if view.tag == 123 {
                exerciseWeightsLabel.text = weightUnit
                var weight = (exerciseWeightsTextField.text! as NSString).doubleValue
                
                //Save all in kg
                if weightUnit == "lbs" {
                    weight = weight /  2.20462262185
                }
                exercisesWithSets[userPosition].weight =  exerciseWeightsTextField.text != "" ? NSDecimalNumber(value: weight as Double) : 0
                exercisesWithSets[userPosition].doneReps = exerciseRepsTextField.text != "" ?  NSDecimalNumber(string: exerciseRepsTextField.text) : 0
                slideIn(1, completionDelegate: view, direction: animationDirection)
                weight = (exercisesWithSets[userPosition].weight).doubleValue
                
                //Show as lbs
                if weightUnit == "lbs" {
                    weight = weight *  2.20462262185
                }
                if weight < 1000 {
                    exerciseWeightsTextField.text = NSString(format: "%.2f", weight) as String
                } else if weight < 10000 {
                    exerciseWeightsTextField.text = NSString(format: "%.1f", weight) as String
                } else {
                    exerciseWeightsTextField.text = NSString(format: "%.0f", weight) as String
                }
                if weight == 0 {
                    exerciseWeightsTextField.text = ""
                }
                
                exerciseRepsTextField.text = exercisesWithSets[userPosition].doneReps == 0 ? "" :String(stringInterpolationSegment: exercisesWithSets[userPosition].doneReps)
                let translationSet = NSLocalizedString("Set", comment: "Set")
                exerciseSetLabel.text = "\(setCounter[userPosition]).\(translationSet)"
                
                exerciseNameLabel.text = exercisesWithSets[userPosition].name
                
                if (exercisesWithSets[userPosition].reps as! Int) < 10 {
                    exerciseRepsLabel.text = "  / \(exercisesWithSets[userPosition].reps)"
                } else {
                    exerciseRepsLabel.text = " /\(exercisesWithSets[userPosition].reps)"
                }
                
                // Disable / Enable buttons
                if userPosition > 0 {
                    previousExerciseButton.isEnabled = true
                    previousExerciseButton.setTitle("<", for: UIControlState())
                } else {
                    previousExerciseButton.isEnabled = false
                    previousExerciseButton.setTitle("", for: UIControlState())
                }
                if userPosition+1 < exercisesWithSets.count {
                    nextExerciseButton.isEnabled = true
                    nextExerciseButton.setTitle(">", for: UIControlState())
                } else {
                    nextExerciseButton.isEnabled = false
                    nextExerciseButton.setTitle("", for: UIControlState())
                }
            }
        }
    }
    
    // Get date in a good format
    func returnDateForm(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        let theDateFormat = DateFormatter.Style.short
        let theTimeFormat = DateFormatter.Style.none
        dateFormatter.dateStyle = theDateFormat
        dateFormatter.timeStyle = theTimeFormat
        return dateFormatter.string(from: date)
    }
    
    @objc func updateTime() {
        currentTime = Date.timeIntervalSinceReferenceDate
        
        // Find the difference between current time and start time.
        var elapsedTime: TimeInterval = currentTime! - startTime
        
        // Calculate the minutes in elapsed time.
        let minutes = UInt8(elapsedTime / 60.0)
        elapsedTime -= (TimeInterval(minutes) * 60)
        
        // Calculate the seconds in elapsed time.
        let seconds = UInt8(elapsedTime)
        elapsedTime -= TimeInterval(seconds)
        
        // Find out the fraction of milliseconds to be displayed.
        let fraction = UInt8(elapsedTime * 100)
        
        // Add the leading zero for minutes, seconds and millseconds and store them as string constants
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        let strFraction = String(format: "%02d", fraction)
        
        // Concatenate minuets, seconds and milliseconds as assign it to the UILabel
        stopWatchLabel.text = "\(strMinutes):\(strSeconds):\(strFraction)"
    }
    
    // Animation
    func slideIn(_ duration: TimeInterval = 1.0, completionDelegate: AnyObject? = nil, direction: Bool) {
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
    
    func setupPickerView() {
        blurView.frame = datePickerBackgroundView.bounds
        blurView.translatesAutoresizingMaskIntoConstraints = false
        if !datePickerBackgroundView.subviews.contains(blurView) {
            datePickerBackgroundView.addSubview(blurView)
            datePickerBackgroundView.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: datePickerBackgroundView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0.0))
            datePickerBackgroundView.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: datePickerBackgroundView, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0.0))
            datePickerBackgroundView.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: datePickerBackgroundView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0.0))
            datePickerBackgroundView.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: datePickerBackgroundView, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0.0))
        }
        datePickerBackgroundView.alpha = 0
        datePickerBackgroundView.isHidden = false
        self.view.bringSubview(toFront: datePickerBackgroundView)
        datePickerBackgroundView.bringSubview(toFront: datePicker)
        datePickerBackgroundView.bringSubview(toFront: selectDateButton)
        datePickerBackgroundView.bringSubview(toFront: datePickerTitleLabel)
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.datePickerBackgroundView.alpha = 1
        }, completion: { finished in
        })
    }
    
    
    // MARK: Keyboard methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //Close Keyboard when clicking outside
        exerciseWeightsTextField.resignFirstResponder()
        exerciseRepsTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.view.frame.origin.y -= 20
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.view.frame.origin.y += 20
        if textField == exerciseRepsTextField && exerciseRepsTextField.text != "" {
            exercisesWithSets[userPosition].doneReps = Int(exerciseRepsTextField.text!)! as NSNumber
        }
        if textField == exerciseWeightsTextField &&  exerciseWeightsTextField.text != "" {
            exercisesWithSets[userPosition].weight = NSDecimalNumber(string: exerciseWeightsTextField.text)
        }
    }
    
    // Set textfield input options
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let text = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let disallowedCharacterSet = CharacterSet(charactersIn: "0123456789.").inverted
        let replacementStringIsLegal = string.rangeOfCharacter(from: disallowedCharacterSet) == nil
        let scanner = Scanner(string: text)
        let resultingTextIsNumeric = scanner.scanDecimal(nil) && scanner.isAtEnd
        var getDecimalNumbers = (textField.text! as NSString).components(separatedBy: ".")
        if getDecimalNumbers.count > 1 && (getDecimalNumbers[1] as NSString).integerValue > 9 && string != ""  {
            return false
        }
        let newLength = textField.text!.count + string.count - range.length
        var back = 0
        if textField == exerciseWeightsTextField {
            back = 6
            let resultingStringLengthIsLegal = text.count <= 6
            if text.count == 0 || (replacementStringIsLegal &&
                resultingStringLengthIsLegal &&
                resultingTextIsNumeric) {
                if text != "." {
                    return true
                }
            }
            return false
        } else if textField == exerciseRepsTextField {
            back = 2
            if let checksum = Int(text), newLength <= back, checksum >= 0, checksum < 100 {
                return true
            } else if newLength <= back && text == "" {
                return true
            } else {
                return false
            }
        }
        return newLength <= back
    }
    
    // Show correct background after rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        var backgroundImage = UIImage(named: "Background2.png")
        backgroundImage = imageResize(backgroundImage!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundImage!)
    }
    
}
