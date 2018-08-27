//
//  EditDayIDVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 31.07.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import CoreData

class EditTrainingDataDetailVC: UIViewController, UITextFieldDelegate {
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var currentTime: TimeInterval?
    var editDate: Date!
    var exercisesWithSets: [DoneExercise] = []
    var lengthUnit = UserDefaults.standard.object(forKey: "lengthUnit")! as! String
    var saveCurrentTime: TimeInterval?
    var selectedExercise: [DoneExercise] = []
    var setCounter: [Int] = []
    var startTime = TimeInterval()
    var timer = Timer()
    var wasStopped = true
    var weightUnit = UserDefaults.standard.object(forKey: "weightUnit")! as! String
    var userPosition: Int = 0
    
    // MARK: IBOutles & IBActions
    @IBOutlet weak var editExerciseNameLabel: UILabel!
    @IBOutlet weak var editRepsLabel: UILabel!
    @IBOutlet weak var editRepsTextField: UITextField!
    @IBOutlet weak var editSetLabel: UILabel!
    @IBOutlet weak var editTrainingPlanNameLabel: UILabel!
    @IBOutlet weak var editWeightsLabel: UILabel!
    @IBOutlet weak var editWeightsTextField: UITextField!
    @IBOutlet weak var nextExerciseButton: UIButton!
    @IBOutlet weak var previousExerciseButton: UIButton!
    @IBOutlet weak var stopWatchLabel: UILabel!
    
    @IBAction func breakStopWatch(_ sender: AnyObject) {
        if !wasStopped {
            saveCurrentTime = startTime - Date.timeIntervalSinceReferenceDate
            timer.invalidate()
        }
    }
    
    func prepareDataSet() -> [Array<String>] {
        
        var weight = (editWeightsTextField.text! as NSString).doubleValue
        //Save all in kg
        if weightUnit == "lbs" {
            weight = weight /  2.20462262185
        }
        
        //If nothing was entered save zero as weight and rep value
        exercisesWithSets[userPosition].weight =  editWeightsTextField.text != "" ?  NSDecimalNumber(value: weight as Double) : 0
        exercisesWithSets[userPosition].doneReps = editRepsTextField.text != "" ?  NSDecimalNumber(string: editRepsTextField.text) : 0
        
        
        var dataSet: [[String]] = []
        for i in 0 ..< exercisesWithSets.count {
            dataSet.append([exercisesWithSets[i].dayID, exercisesWithSets[i].name,"\(exercisesWithSets[i].reps)", "\(exercisesWithSets[i].doneReps)","\(exercisesWithSets[i].sets)","\(exercisesWithSets[i].weight)", "\(exercisesWithSets[i].setCounter)"])
        }
        return dataSet
    }
    
    func saveDoneExercises(_ preparedDataSet: [[String]]) {
        let requestDoneEx = NSFetchRequest<NSFetchRequestResult>(entityName: "DoneExercise")
        let savedDoneExercises = (try! appDelegate.managedObjectContext?.fetch(requestDoneEx))  as! [DoneExercise]
        
        //setup data
        for doneExercises in preparedDataSet {
            for singleSavedDoneExercise in savedDoneExercises{
                if DateFormatHelper.returnDateForm(singleSavedDoneExercise.date) == DateFormatHelper.returnDateForm(editDate) && singleSavedDoneExercise.dayID == doneExercises[0] && singleSavedDoneExercise.name == doneExercises[1] && singleSavedDoneExercise.setCounter ==  NSDecimalNumber(string:doneExercises[6]){
                    singleSavedDoneExercise.doneReps = NSDecimalNumber(string:doneExercises[3])
                    singleSavedDoneExercise.weight = NSDecimalNumber(string: doneExercises[5])
                }
            }
            appDelegate.saveContext()
        }
        
    }
    
    @IBAction func saveTrainingPlan(_ sender: AnyObject) {
        let preparedDataSet: [[String]] = prepareDataSet()
        
        //Rollback to don't save exerices which were needed to get done exercises
        appDelegate.rollBackContext()
        
        saveDoneExercises(preparedDataSet)
        
        AlertFormatHelper.showInfoAlert(self, "Your training was changed.")
    }
    
    @IBAction func showNextExercise(_ sender: AnyObject) {
        filterSpecificView(false)
    }
    
    @IBAction func showPreviousExercise(_ sender: AnyObject) {
        filterSpecificView(true)
    }
    
    @IBAction func startStopWatch(_ sender: AnyObject) {
        if !timer.isValid {
            let updateTimeSelector: Selector = #selector(EditTrainingDataDetailVC.updateTime)
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
        
        // Set delegate of textfields
        editRepsTextField.delegate = self
        editWeightsTextField.delegate = self
        
        loadSelectedExercises()
        editDate = exercisesWithSets[0].date as Date?
        
        setupStartView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    // Cancel changings
    
    override func viewDidDisappear(_ animated: Bool) {
        appDelegate.rollBackContext()
    }
    
    // MARK: Keyboard Methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //Close Keyboard when clicking outside
        editWeightsTextField.resignFirstResponder()
        editRepsTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }
    
    //Move view to always see the selected textfield
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.view.frame.origin.y -= 20
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.view.frame.origin.y += 20
        if textField == editRepsTextField && editRepsTextField.text != "" {
            exercisesWithSets[userPosition].doneReps = Int(editRepsTextField.text!)! as NSNumber
        }
        if textField == editWeightsTextField &&  editWeightsTextField.text != "" {
            exercisesWithSets[userPosition].weight = NSDecimalNumber(string: editWeightsTextField.text)
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
        if textField == editWeightsTextField {
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
        } else if textField == editRepsTextField {
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
    
    // MARK: Own Methods
    
    func showWeightCorrectly(_ weight: inout Double) {
        //Show as lbs
        if weightUnit == "lbs" {
            weight = weight *  2.20462262185
        }
        
        if weight < 1000 {
            editWeightsTextField.text = exercisesWithSets[userPosition].weight == 0 ? "0" : NSString(format: "%.2f", weight) as String
        } else if weight < 10000 {
            editWeightsTextField.text = exercisesWithSets[userPosition].weight == 0 ? "0" : NSString(format: "%.1f", weight) as String
        } else {
            editWeightsTextField.text = NSString(format: "%.0f", weight) as String
        }
        if weight == 0 {
            editWeightsTextField.text = ""
        }
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
        
        // Concatenate minutes, seconds and milliseconds as assign it to the UILabel
        stopWatchLabel.text = "\(strMinutes):\(strSeconds):\(strFraction)"
    }
    
    func filterSpecificView(_ animationDirection: Bool) {
        for view in self.view.subviews {
            if view.tag == 123 {
                editWeightsLabel.text = weightUnit
                var weight = (editWeightsTextField.text! as NSString).doubleValue
                
                //Save all in kg
                if weightUnit == "lbs" {
                    weight = weight /  2.20462262185
                }
                exercisesWithSets[userPosition].weight = editWeightsTextField.text != "" ? NSDecimalNumber(value: weight as Double) : 0
                exercisesWithSets[userPosition].doneReps = editRepsTextField.text != "" ?  NSDecimalNumber(string: editRepsTextField.text) : 0
                slideIn(1, completionDelegate: view,direction: animationDirection)
                weight = (exercisesWithSets[userPosition].weight).doubleValue
                
                showWeightCorrectly(&weight)
                
                editRepsTextField.text = exercisesWithSets[userPosition].doneReps == 0 ? "0" : String(stringInterpolationSegment: exercisesWithSets[userPosition].doneReps)
                let translationSet = NSLocalizedString("Set", comment: "Set")
                editSetLabel.text = "\(setCounter[userPosition]).\(translationSet)"
                editExerciseNameLabel.text = exercisesWithSets[userPosition].name
                if (exercisesWithSets[userPosition].reps as! Int) < 10 {
                    editRepsLabel.text = "  / \(exercisesWithSets[userPosition].reps)"
                } else {
                    editRepsLabel.text = " /\(exercisesWithSets[userPosition].reps)"
                }
                
                showNavigationButtonsCorrectly()
            }
        }
    }
    
    func loadSelectedExercises() {
        var i = 1
        var actualExerciseName = ""
        var prevExerciseName = ""
        for item in selectedExercise as [DoneExercise] {
            prevExerciseName = actualExerciseName
            actualExerciseName = item.name
            if actualExerciseName != prevExerciseName {
                i = 1
            }
            setCounter.append(i)
            let newItem = DoneExercise()
            newItem.dayID = item.dayID
            newItem.sets = item.sets
            newItem.reps = item.reps
            newItem.weight = item.weight
            newItem.doneReps = item.doneReps
            newItem.name = item.name
            newItem.date = item.date
            newItem.setCounter = item.setCounter
            exercisesWithSets.append(newItem)
            i += 1
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
        
        if userPosition + 1 < exercisesWithSets.count {
            nextExerciseButton.isEnabled = true
            nextExerciseButton.setTitle(">", for: UIControlState())
        } else {
            nextExerciseButton.isEnabled = false
            nextExerciseButton.setTitle("", for: UIControlState())
        }
    }
    
    func setupStartView() {
        // Set start contents of the view
        editTrainingPlanNameLabel.text = selectedExercise[0].dayID
        editWeightsLabel.text = weightUnit
        editExerciseNameLabel.text = exercisesWithSets[0].name
        if (exercisesWithSets[0].reps as! Int) < 10 {
            editRepsLabel.text = "  / \(exercisesWithSets[0].reps)"
        } else {
            editRepsLabel.text = " /\(exercisesWithSets[0].reps)"
        }
        previousExerciseButton.isEnabled = false
        previousExerciseButton.setTitle("", for: UIControlState())
        if exercisesWithSets.count < 2 {
            nextExerciseButton.isEnabled = false
            nextExerciseButton.setTitle("", for: UIControlState())
        }
        
        var weight = (exercisesWithSets[0].weight).doubleValue
        
        // Show first exercise in correct unit
        editRepsTextField.text = exercisesWithSets[0].doneReps.stringValue
        
        showWeightCorrectly(&weight)
    }
    
}
