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


class AddExerciseVC: UIViewController, UITextFieldDelegate, ADBannerViewDelegate {

    var exercises: [[String]] = [["", "", ""]]
    var dayId: String = ""
    var userPos: Int = 0
    var deleteOn: Bool = false
    var appdel = UIApplication.shared.delegate as! AppDelegate
    var editMode = false
    var editDayIDSaver = ""
    var selectedExc: [Exercise] = []
    var tutorialView: UIImageView!
    
    // MARK: IBOutles & IBActions
    @IBOutlet weak var m_tf_ListName: UITextField!
    @IBOutlet weak var m_tf_Reps: UITextField!
    @IBOutlet weak var m_tf_Sets: UITextField!
    @IBOutlet weak var m_tf_Name: UITextField!
    @IBOutlet weak var previousExButton: UIButton!
    @IBOutlet weak var iAd: ADBannerView!
    @IBOutlet weak var deleteExButton: UIButton!
    @IBOutlet weak var nextExButton: UIButton!
    @IBOutlet weak var addExButton: UIButton!
    
    // Add a new exercise
    @IBAction func AddExButtonCL(_ sender: AnyObject) {
        
        if allFilled() {
            exercises[userPos] = [m_tf_Name.text!, m_tf_Reps.text!, m_tf_Sets.text!]
            exercises.insert(["", "", ""], at: userPos+1)
            filterSpecificView(false)
            clearDetails()
        }
        
    }
    
    // Delete actual exercise
    @IBAction func deleteExButtonCL(_ sender: AnyObject) {
        
        exercises.remove(at: userPos)
        deleteOn = true
        if userPos > 0 {
            filterSpecificView(true)
        } else {
            filterSpecificView(false)
        }
        
    }
    
    // Show previous exercise
    @IBAction func previousExButtonCL(_ sender: AnyObject) {
        
        exercises[userPos] = [m_tf_Name.text!, m_tf_Reps.text!, m_tf_Sets.text!]
        filterSpecificView(true)
        
    }
    
    // Show next exercise
    @IBAction func nextExButtonCL(_ sender: AnyObject) {
        
        exercises[userPos] = [m_tf_Name.text!, m_tf_Reps.text!, m_tf_Sets.text!]
        filterSpecificView(false)
        
    }
    
    @IBAction func saveClickListener(_ sender: AnyObject) {
        
        // Save all created exercises
        if allFilled() {
            dayId = m_tf_ListName.text!
            exercises[userPos] = [m_tf_Name.text!, m_tf_Reps.text!, m_tf_Sets.text!]
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Exercise")
            let exercisesCD = (try! appdel.managedObjectContext?.fetch(request)) as! [Exercise]
            
            // In edit mode remove old saved exercises and add the new edited one
            if editMode {
                for singleExCD in exercisesCD {
                    if singleExCD.dayID == editDayIDSaver {
                        appdel.managedObjectContext!.delete(singleExCD as NSManagedObject)
                    }
                }
            }
            appdel.saveContext()
            for checkCells in self.exercises {
                let newItem = NSEntityDescription.insertNewObject(forEntityName: "Exercise", into: appdel.managedObjectContext!) as! Exercise
                newItem.dayID = dayId
                print(checkCells[0])
                newItem.name = checkCells[0]
                newItem.reps = Int(checkCells[1])! as NSNumber
                newItem.sets = Int(checkCells[2])! as NSNumber
                appdel.saveContext()
            }
            let informUser = UIAlertController(title: "Saved", message: "Your training plan was saved", preferredStyle: UIAlertControllerStyle.alert)
            informUser.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                self.navigationController?.popViewController(animated: true)
            }))
            present(informUser, animated: true, completion: nil)
        }
        
    }


    // MARK: View Methods
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Handle iAd
        iAd.delegate = self
        iAd.isHidden = true
        
        // Set background
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
        // Show tutorial
        if UserDefaults.standard.object(forKey: "tutorialAddExercise") == nil {
            tutorialView = UIImageView(frame: self.view.frame)
            tutorialView.image = UIImage(named: "TutorialAddExercise.png")
            tutorialView.frame.origin.y += 18
            if self.view.frame.size.height <= 490 {
                tutorialView.frame.size.height -= 10
            } else {
                tutorialView.frame.size.height -= 60
            }
            tutorialView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(AddExerciseVC.hideTutorial))
            tutorialView.addGestureRecognizer(tap)
            self.view.addSubview(tutorialView)
            self.navigationController?.isNavigationBarHidden = true
        }

        // Set delegates of textfields
        m_tf_Reps.delegate = self
        m_tf_Sets.delegate = self
        m_tf_Name.delegate = self
        m_tf_ListName.delegate = self
        
        
         //Prepare data if view was opened in edit mode
        if editMode {
            self.title = NSLocalizedString("Edit Training plan", comment: "Edit Training plan")
            editDayIDSaver = selectedExc[0].dayID
            var currentName = ""
            var prevName = ""
            var first = true
            for singleEx in selectedExc {
                prevName = currentName
                currentName = singleEx.name
                if prevName != currentName {
                    if first {
                        exercises[userPos] = [singleEx.name, "\(singleEx.reps)", "\(singleEx.sets)"]
                        m_tf_ListName.text = singleEx.dayID
                        first = false
                    } else {
                        exercises.append([singleEx.name, "\(singleEx.reps)", "\(singleEx.sets)"])
                    }
                    m_tf_Name.text = exercises[userPos][0]
                    m_tf_Reps.text = exercises[userPos][1]
                    m_tf_Sets.text = exercises[userPos][2]
                }
            }
        }
        
        if exercises.count <= 1 {
            deleteExButton.isEnabled = false
            nextExButton.isEnabled = false
            nextExButton.setTitle("", for: UIControlState())
        }
        previousExButton.isEnabled = false
        previousExButton.setTitle("", for: UIControlState())
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        self.navigationController?.setToolbarHidden(true, animated: true)
        
    }
    
    // Show correct background after rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if UserDefaults.standard.object(forKey: "tutorialAddExercise") == nil {
            hideTutorial()
        }
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
    }
    
    // MARK: Keyboard Methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Close Keyboard when clicking outside
        m_tf_Name.resignFirstResponder()
        m_tf_Sets.resignFirstResponder()
        m_tf_Reps.resignFirstResponder()
        m_tf_ListName.resignFirstResponder()
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        // Push up view to see what you are actual entering
        switch textField {
        case m_tf_Reps :
            self.view.frame.origin.y -= 80
        case m_tf_Sets :
            self.view.frame.origin.y -= 80
        case m_tf_Name :
            self.view.frame.origin.y -= 20
        default :
            print("Error keyboard")
        }
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        // Put view back down after entering in text fields
        switch textField {
        case m_tf_Reps :
            self.view.frame.origin.y += 80
        case m_tf_Sets :
            self.view.frame.origin.y += 80
        case m_tf_Name :
            self.view.frame.origin.y += 20
        default :
            print("Error keyboard")
        }
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // Jump to next textfield by clicking on "next" button
        if string == "\n" {
            textField.endEditing(true)
            switch textField {
            case m_tf_ListName :
                m_tf_Name.becomeFirstResponder()
            case m_tf_Name :
                m_tf_Sets.becomeFirstResponder()
            default :
                print("Error keyboard")
            }
            return true
        }
        textField.backgroundColor = UIColor.white
        textField.placeholder = ""
        let text = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        // Setup input settings
        let newLength = textField.text!.characters.count + string.characters.count - range.length
        var back = 0
        if textField == m_tf_Reps {
            back = 2
            if newLength <= back && ((Int(text) > 0 && Int(text) < 100) || text == "") {
                return true
            } else {
                return false
            }
        } else if textField == m_tf_Sets {
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
    
    // MARK: My Methods
    func hideTutorial() {
      
        self.navigationController?.isNavigationBarHidden = false
        UIView.transition(with: self.view, duration: 1, options: UIViewAnimationOptions.curveLinear, animations: {
            self.tutorialView.alpha = 0;
            }, completion:{ finished in
                 UserDefaults.standard.set(false, forKey: "tutorialAddExercise")
                self.tutorialView.removeFromSuperview()
        })
        
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
    func allFilled() -> Bool {
        
        var check = true
        if m_tf_ListName.text == "" {
            m_tf_ListName.backgroundColor = UIColor(red: 218 / 255, green: 52 / 255, blue: 60 / 255, alpha: 1.0)
            m_tf_ListName.placeholder = NSLocalizedString("Enter something!", comment: "Enter something!")
            check = false
        }
        if m_tf_Reps.text == "" {
            m_tf_Reps.backgroundColor = UIColor(red: 218 / 255 , green: 52 / 255, blue: 60 / 255, alpha: 1.0)
            m_tf_Reps.placeholder = NSLocalizedString("Enter sth.!", comment: "Enter sth.!")
            check = false
        }
        if m_tf_Name.text == "" {
            m_tf_Name.backgroundColor = UIColor(red: 218 / 255, green: 52 / 255, blue: 60 / 255, alpha: 1.0)
            m_tf_Name.placeholder = NSLocalizedString("Enter sth.!", comment: "Enter sth.!")
            check = false
        }
        if m_tf_Sets.text == "" {
            m_tf_Sets.backgroundColor = UIColor(red: 218 / 255, green: 52 / 255, blue: 60 / 255, alpha: 1.0)
            m_tf_Sets.placeholder = NSLocalizedString("Enter sth.!", comment: "Enter sth.!")
            check = false
        }
        return check
        
    }
    
    func clearDetails(){
        
        m_tf_Name.text = ""
        m_tf_Reps.text = ""
        m_tf_Sets.text = ""
        
    }
    
    func filterSpecificView(_ animationDirection: Bool) {
        
        if deleteOn || allFilled() {
            dayId = m_tf_ListName.text!
            for _view in self.view.subviews {
                if let view = _view as? UIView {
                    if view.tag == 123 {
                
                        // Start animation
                        slideIn(1, completionDelegate: _view, direction: animationDirection)
                        
                        // Load in next exercise
                        if deleteOn && !animationDirection {
                            userPos = 0
                        }
                        m_tf_Name.text = exercises[userPos][0]
                        m_tf_Reps.text = exercises[userPos][1]
                        m_tf_Sets.text = exercises[userPos][2]
                        
                        // Enable/Disable buttons
                        if userPos > 0 {
                            previousExButton.isEnabled = true
                            previousExButton.setTitle("<", for: UIControlState())
                            deleteExButton.isEnabled = true
                        } else {
                            previousExButton.isEnabled = false
                            previousExButton.setTitle("", for: UIControlState())
                        }
                        if exercises.count <= 1 {
                            deleteExButton.isEnabled = false
                        }
                        if userPos + 1 < exercises.count {
                            nextExButton.isEnabled = true
                            nextExButton.setTitle(">", for: UIControlState())
                        } else {
                            nextExButton.isEnabled = false
                            nextExButton.setTitle("", for: UIControlState())
                        }
                    }
                }
            }
            deleteOn = false
        }
        
    }

    func slideIn(_ duration: TimeInterval = 1.0, completionDelegate: AnyObject? = nil, direction:Bool) {
        
        m_tf_Name.backgroundColor = UIColor.white
        m_tf_Sets.backgroundColor = UIColor.white
        m_tf_Reps.backgroundColor = UIColor.white
        
        // Create a CATransition animation
        let slideInTransition = CATransition()
        
        // Set its callback delegate to the completionDelegate that was provided (if any)
        if let delegate = completionDelegate as? CAAnimationDelegate {
            slideInTransition.delegate = delegate
        }
        
        // Customize the animation's properties
        slideInTransition.type = kCATransitionMoveIn
        if direction {
            userPos -= 1
            slideInTransition.subtype = kCATransitionFromLeft
        } else {
            userPos += 1
            slideInTransition.subtype = kCATransitionFromRight
        }
        slideInTransition.duration = duration
        slideInTransition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        slideInTransition.fillMode = kCAFillModeRemoved
        
        // Add the animation to the View's layer
        (completionDelegate as! UIView).layer.add(slideInTransition, forKey: "slideInTransition")
        
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
