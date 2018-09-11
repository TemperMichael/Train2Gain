//
//  TrainingModeVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 29.03.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import CoreData
import Fabric
import Crashlytics

class TrainingModeVC: UIViewController {
    
    var appDelegate: AppDelegate?
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
    var date: Date?
    var exercisesWithSets: [Exercise] = []
    var lengthUnit: String?
    var saveCurrentTime: TimeInterval?
    var savedEnteredExercises: [[String]] = []
    var startTime = TimeInterval()
    var selectedExercise: [Exercise] = []
    var setCounter: [Int] = []
    var timer = Timer()
    var wasStopped = true
    var weightUnit: String?
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
        var preparedDataSet = prepareDataSet()
        
        guard let unwrappedAppDelegate = appDelegate else {
            return
        }
        // Rollback to don't save exerices which were needed to get done exercises
        unwrappedAppDelegate.rollBackContext()
        
        saveDoneExercises(preparedDataSet)
        
        //Fabric - Analytic tool
        Answers.logLevelEnd("Finished Training",
                            score: nil,
                            success: true,
                            customAttributes: ["Training name": preparedDataSet[0][0]])
        
        AlertFormatHelper.showInfoAlert(self, "Your training was saved.")
    }
    
    @IBAction func selectDate(_ sender: AnyObject) {
        date = DateFormatHelper.setDate(datePicker.date, datePickerButton)
        PickerViewHelper.hidePickerView(datePickerBackgroundView)
    }
    
    @IBAction func showDatePicker(_ sender: AnyObject) {
        PickerViewHelper.setupPickerViewBackground(blurView, datePickerBackgroundView)
        PickerViewHelper.bringPickerToFront(datePickerBackgroundView, datePicker, selectDateButton, datePickerTitleLabel)
    }
    
    @IBAction func showNextDay(_ sender: AnyObject) {
        guard let unwrappedDate = date else {
            return
        }
        date = DateFormatHelper.setDate(unwrappedDate.addingTimeInterval(60 * 60 * 24), datePickerButton)
    }
    
    @IBAction func showNextExercise(_ sender: AnyObject) {
        filterSpecificView(false)
    }
    
    @IBAction func showPreviousDay(_ sender: AnyObject) {
        guard let unwrappedDate = date else {
            return
        }
        date = DateFormatHelper.setDate(unwrappedDate.addingTimeInterval(-60 * 60 * 24), datePickerButton)
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
                guard let unwrappedSaveCurrentTime = saveCurrentTime else {
                    return
                }
                startTime =  unwrappedSaveCurrentTime +  Date.timeIntervalSinceReferenceDate
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
        
        guard let unwrappedLengthUnit = UserDefaults.standard.object(forKey: "lengthUnit") as? String, let unwrappedWeightUnit = UserDefaults.standard.object(forKey: "weightUnit") as? String, let unwrappedAppDelegate = UIApplication.shared.delegate as? AppDelegate, let unwrappedDate = UserDefaults.standard.object(forKey: "dateUF") as? Date else {
            return
        }
        
        lengthUnit = unwrappedLengthUnit
        weightUnit = unwrappedWeightUnit
        appDelegate = unwrappedAppDelegate
        date = unwrappedDate
        
        //Set delegate of textfields
        exerciseRepsTextField.delegate = self
        exerciseWeightsTextField.delegate = self
        
        Answers.logLevelStart("Started training", customAttributes: ["Training name": selectedExercise[0].dayID])
        
        loadSelectedExercises()
        
        setupStartView()
        
        PickerViewHelper.setupPickerView(datePicker, datePickerTitleLabel)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        exercisesWithSets = []
        guard let unwrappedDate = UserDefaults.standard.object(forKey: "dateUF") as? Date else {
            return
        }
        datePickerButton.setTitle(DateFormatHelper.returnDateForm(unwrappedDate), for: UIControlState())
        date = unwrappedDate
        loadSelectedExercises()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Answers.logLevelEnd("Canceled Training",
                            score: nil,
                            success: true,
                            customAttributes: ["Training name": exerciseTrainingPlanNameLabel.text ?? ""])
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        guard let unwrappedAppDelegate = appDelegate else {
            return
        }
        unwrappedAppDelegate.rollBackContext()
    }
    
    // MARK: Own Methods
    
    func filterSpecificView(_ animationDirection: Bool) {
        for view in self.view.subviews {
            if view.tag == 123 {
                exerciseWeightsLabel.text = weightUnit
                var weight = (exerciseWeightsTextField.text as NSString? ?? "").doubleValue
                
                //Save all in kg
                if weightUnit == "lbs" {
                    weight = weight /  2.20462262185
                }
                exercisesWithSets[userPosition].weight =  exerciseWeightsTextField.text != "" ? NSDecimalNumber(value: weight as Double) : 0
                exercisesWithSets[userPosition].doneReps = exerciseRepsTextField.text != "" ?  NSDecimalNumber(string: exerciseRepsTextField.text) : 0
                slideIn(1, completionDelegate: view, direction: animationDirection)
                weight = (exercisesWithSets[userPosition].weight).doubleValue
                
                showWeightCorrectly(&weight)
                
                exerciseRepsTextField.text = exercisesWithSets[userPosition].doneReps == 0 ? "" : String(stringInterpolationSegment: exercisesWithSets[userPosition].doneReps)
                let translationSet = NSLocalizedString("Set", comment: "Set")
                exerciseSetLabel.text = "\(setCounter[userPosition]).\(translationSet)"
                
                exerciseNameLabel.text = exercisesWithSets[userPosition].name
                
                guard let unwrappedReps = exercisesWithSets[userPosition].reps as? Int else {
                    return
                }
                
                if unwrappedReps < 10 {
                    exerciseRepsLabel.text = "  / \(exercisesWithSets[userPosition].reps)"
                } else {
                    exerciseRepsLabel.text = " /\(exercisesWithSets[userPosition].reps)"
                }
                
                showNavigationButtonsCorrectly()
            }
        }
    }
    
    func showWeightCorrectly(_ weight: inout Double) {
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
    }
    
    func showNavigationButtonsCorrectly() {
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
    
    @objc func updateTime() {
        let currentTime = Date.timeIntervalSinceReferenceDate
        
        // Find the difference between current time and start time.
        var elapsedTime: TimeInterval = currentTime - startTime
        
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
        guard let completionView = completionDelegate as? UIView else {
            return
        }
        completionView.layer.add(slideInTransition, forKey: "slideInTransition")
    }
    
    func saveDoneExercises(_ preparedDataSet: [[String]]) {
        var i = 0
        guard let unwrappedAppDelegate = appDelegate, let unwrappedManagedObjectContext = unwrappedAppDelegate.managedObjectContext, let unwrappedDate = date else {
            return
        }
        
        //Save data
        for checkCells in preparedDataSet {
            guard let newItem = NSEntityDescription.insertNewObject(forEntityName: "DoneExercise", into: unwrappedManagedObjectContext) as? DoneExercise else {
                return
            }
            newItem.date = unwrappedDate
            newItem.dayID = checkCells[0]
            newItem.name = checkCells[1]
            newItem.reps = NSDecimalNumber(string: checkCells[2])
            newItem.doneReps = NSDecimalNumber(string:checkCells[3])
            newItem.sets = NSDecimalNumber(string:checkCells[4])
            newItem.weight = NSDecimalNumber(string: checkCells[5])
            newItem.setCounter = NSNumber(value: setCounter[i])
            unwrappedAppDelegate.saveContext()
            i += 1
        }
    }
    
    func prepareDataSet() -> [Array<String>] {
        var weight = (exerciseWeightsTextField.text as NSString? ?? "").doubleValue
        
        // Save all in kg
        if weightUnit == "lbs" {
            weight = weight /  2.20462262185
        }
        
        // If nothing was entered save zero as weight and rep value
        exercisesWithSets[userPosition].weight =  exerciseWeightsTextField.text != "" ?  NSDecimalNumber(value: weight as Double) : 0
        exercisesWithSets[userPosition].doneReps = exerciseRepsTextField.text != "" ?  NSDecimalNumber(string: exerciseRepsTextField.text) : 0
        
        var dataSet: [[String]] = []
        for i in 0  ..< exercisesWithSets.count {
            dataSet.append([exercisesWithSets[i].dayID, exercisesWithSets[i].name, "\(exercisesWithSets[i].reps)", "\(exercisesWithSets[i].doneReps)", "\(exercisesWithSets[i].sets)", "\(exercisesWithSets[i].weight)"])
            
        }
        return dataSet
    }
    
    func loadSelectedExercises() {
        for item in selectedExercise as [Exercise] {
            guard let unwrappedSet = item.sets as? Int else {
                return
            }
            for i in 0..<unwrappedSet {
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
    
    func setupStartView() {
        guard let unwrappedReps = exercisesWithSets[0].reps as? Int else {
            return
        }
        exerciseTrainingPlanNameLabel.text = selectedExercise[0].dayID
        exerciseWeightsLabel.text = weightUnit
        exerciseNameLabel.text = exercisesWithSets[0].name
        if unwrappedReps < 10 {
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
    }
    
}

// MARK: TextField

extension TrainingModeVC: UITextFieldDelegate {
    
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
            guard let unwrappedInput = Int(exerciseRepsTextField.text ?? "") as NSNumber? else {
                return
            }
            exercisesWithSets[userPosition].doneReps = unwrappedInput
        }
        if textField == exerciseWeightsTextField &&  exerciseWeightsTextField.text != "" {
            exercisesWithSets[userPosition].weight = NSDecimalNumber(string: exerciseWeightsTextField.text)
        }
    }
    
    // Set textfield input options
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text as NSString? ?? "").replacingCharacters(in: range, with: string)
        let disallowedCharacterSet = CharacterSet(charactersIn: "0123456789.").inverted
        let replacementStringIsLegal = string.rangeOfCharacter(from: disallowedCharacterSet) == nil
        let scanner = Scanner(string: text)
        let resultingTextIsNumeric = scanner.scanDecimal(nil) && scanner.isAtEnd
        var getDecimalNumbers = (textField.text as NSString? ?? "").components(separatedBy: ".")
        if getDecimalNumbers.count > 1 && (getDecimalNumbers[1] as NSString).integerValue > 9 && string != ""  {
            return false
        }
        let newLength = (textField.text ?? "").count + string.count - range.length
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
}
