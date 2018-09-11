//
//  TrainingPlanCreationVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 29.03.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import CoreData

class TrainingPlanCreationVC: UIViewController {
    
    var appDelegate: AppDelegate?
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
    @IBOutlet weak var nextExerciseButton: UIButton!
    @IBOutlet weak var previousExerciseButton: UIButton!
    @IBOutlet weak var trainingPlanNameTextField: UITextField!
    @IBOutlet weak var trainingPlanRepsTextField: UITextField!
    @IBOutlet weak var trainingPlanSetsTextField: UITextField!
    @IBOutlet weak var trainingPlanExerciseNameTextField: UITextField!
    
    @IBAction func addExercise(_ sender: AnyObject) {
        if isAllFilled() {
            exercises[userPosition] = [trainingPlanExerciseNameTextField.text ?? "", trainingPlanRepsTextField.text ?? "", trainingPlanSetsTextField.text ?? ""]
            exercises.insert(["", "", ""], at: userPosition + 1)
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
            do {
                dayId = trainingPlanNameTextField.text ?? ""
                exercises[userPosition] = [trainingPlanExerciseNameTextField.text ?? "", trainingPlanRepsTextField.text ?? "", trainingPlanSetsTextField.text ?? ""]
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Exercise")
                guard let exercisesCD = try appDelegate?.managedObjectContext?.fetch(request) as? [Exercise] else {
                    return
                }
                
                // In edit mode remove old saved exercises and add the new edited one
                if editMode {
                    removePreviousExercises(exercisesCD)
                }
                appDelegate?.saveContext()
                saveExercises()
                
                AlertFormatHelper.showInfoAlert(self, "Your training plan was saved.")
            } catch {
                print(error)
            }
        }
        
    }
    
    @IBAction func showPreviousExercise(_ sender: AnyObject) {
        exercises[userPosition] = [trainingPlanExerciseNameTextField.text ?? "", trainingPlanRepsTextField.text ?? "", trainingPlanSetsTextField.text ?? ""]
        filterSpecificView(true)
    }
    
    @IBAction func showNextExercise(_ sender: AnyObject) {
        exercises[userPosition] = [trainingPlanExerciseNameTextField.text ?? "", trainingPlanRepsTextField.text ?? "", trainingPlanSetsTextField.text ?? ""]
        filterSpecificView(false)
    }
    
    // MARK: View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let unwrappedAppDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        appDelegate = unwrappedAppDelegate
        
        // Set delegates of textfields
        trainingPlanRepsTextField.delegate = self
        trainingPlanSetsTextField.delegate = self
        trainingPlanExerciseNameTextField.delegate = self
        trainingPlanNameTextField.delegate = self
        
        
        //Prepare data if view was opened in edit mode
        if editMode {
            loadSavedExercises()
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
    
    // MARK: Own Methods
    
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
            dayId = trainingPlanNameTextField.text ?? ""
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
        guard let completionView = completionDelegate as? UIView else {
            return
        }
        completionView.layer.add(slideInTransition, forKey: "slideInTransition")
        
    }
    
    func removePreviousExercises(_ exercisesCD: [Exercise]) {
        guard let unwrappedManagedObjectContext = appDelegate?.managedObjectContext else {
            return
        }
        for singleExCD in exercisesCD {
            if singleExCD.dayID == editDayIDSaver {
                unwrappedManagedObjectContext.delete(singleExCD as NSManagedObject)
            }
        }
    }
    
    func saveExercises() {
        guard let unwrappedManagedObjectContext = appDelegate?.managedObjectContext else {
            return
        }
        for checkCells in self.exercises {
            guard let newItem = NSEntityDescription.insertNewObject(forEntityName: "Exercise", into: unwrappedManagedObjectContext) as? Exercise else {
                return
            }
            newItem.dayID = dayId
            newItem.name = checkCells[0]
            newItem.reps = Int(checkCells[1]) as NSNumber? ?? 0
            newItem.sets = Int(checkCells[2]) as NSNumber? ?? 0
            appDelegate?.saveContext()
        }
    }
    
    func loadSavedExercises() {
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
    
}

// MARK: TextField

extension TrainingPlanCreationVC: UITextFieldDelegate {
    
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
        let text = (textField.text as NSString? ?? "").replacingCharacters(in: range, with: string)
        
        // Setup input settings
        let newLength = (textField.text ?? "").count + string.count - range.length
        var back = 0
        if textField == trainingPlanRepsTextField {
            back = 2
            if let checksum = Int(text), newLength <= back, checksum > 0, checksum < 100 {
                return true
            } else if newLength <= back && text == "" {
                return true
            } else {
                return false
            }
        } else if textField == trainingPlanSetsTextField {
            back = 1
            if let checksum = Int(text), newLength <= back, checksum > 0, checksum < 10 {
                return true
            } else if newLength <= back && text == "" {
                return true
            } else {
                return false
            }
        } else {
            back = 13
        }
        return newLength <= back
    }
    
}
