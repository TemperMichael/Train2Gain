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
import iAd


class ExerciseChosenVC: UIViewController, UITextFieldDelegate, ADBannerViewDelegate{
    
    var date = NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate
    var userPos: Int = 0
    var clickedExc: [Exercise] = []
    var allExWithSets: [Exercise] = []
    var dates: [Dates] = []
    var setCounter: [Int] = []
    var appdel =  UIApplication.sharedApplication().delegate as! AppDelegate
    var timer = NSTimer()
    var startTime = NSTimeInterval()
    var wasStopped = true
    var saveCurrentTime: NSTimeInterval?
    var currentTime: NSTimeInterval?
    var savedEnteredExercises: [[String]] = []
    var weightUnit: String! = NSUserDefaults.standardUserDefaults().objectForKey("weightUnit")! as! String
    var lengthUnit: String! = NSUserDefaults.standardUserDefaults().objectForKey("lengthUnit")! as! String
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Dark))

    // MARK: IBOutlets & IBActions
    @IBOutlet weak var iAd: ADBannerView!
    @IBOutlet weak var stopWatchLabel: UILabel!
    @IBOutlet weak var m_L_Weights: UILabel!
    @IBOutlet weak var m_L_ListName: UILabel!
    @IBOutlet weak var m_tf_Reps: UITextField!
    @IBOutlet weak var m_tf_Weights: UITextField!
    @IBOutlet weak var m_L_SetCounter: UILabel!
    @IBOutlet weak var m_L_Reps: UILabel!
    @IBOutlet weak var m_L_ExerciseName: UILabel!
    @IBOutlet weak var m_b_PickDate: UIButton!
    @IBOutlet weak var nextExButton: UIButton!
    @IBOutlet weak var previousExButton: UIButton!
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var pickerTitle: UILabel!
    @IBOutlet weak var pickerView: UIDatePicker!
    @IBOutlet weak var pickerBG: UIView!
    
    @IBAction func nextDayCL(sender: AnyObject) {
        
        //Go to next day
        date = date.dateByAddingTimeInterval(60*60*24)
        NSUserDefaults.standardUserDefaults().setObject(date ,forKey: "dateUF")
        
        
        m_b_PickDate.setTitle(returnDateForm(date), forState: UIControlState.Normal)
        
    }
    
    @IBAction func prevDayCL(sender: AnyObject) {
        
        //Go to prevoius day
        date = date.dateByAddingTimeInterval(-60*60*24)
        NSUserDefaults.standardUserDefaults().setObject(date ,forKey: "dateUF")
        
        
        m_b_PickDate.setTitle(returnDateForm(date), forState: UIControlState.Normal)
        
    }
    
    @IBAction func startStopWatch(sender: AnyObject) {
        
        if !timer.valid {
            let aSelector : Selector = "updateTime"
            timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: aSelector, userInfo: nil, repeats: true)
            if wasStopped {
                startTime = NSDate.timeIntervalSinceReferenceDate()
                wasStopped = false
            } else {
                startTime =  saveCurrentTime! +  NSDate.timeIntervalSinceReferenceDate()
            }
        }
        
    }
    
    @IBAction func stopStopWatch(sender: AnyObject) {
        
        wasStopped = true
        timer.invalidate()
        
    }
    
    @IBAction func breakStopWatch(sender: AnyObject) {
        
        if !wasStopped {
            saveCurrentTime = startTime -  NSDate.timeIntervalSinceReferenceDate()
            timer.invalidate()
        }
        
    }
    
    @IBAction func pickDateClicked(sender: AnyObject) {
        
        setupPickerView()
        
    }
    
    @IBAction func previousExButtonCL(sender: AnyObject) {
        
        filterSpecificView(true)
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        
        appdel.rollBackContext()
        
    }
    
    @IBAction func saveCL(sender: AnyObject) {
        
        var weight = (m_tf_Weights.text! as NSString).doubleValue
        
        // Save all in kg
        if weightUnit == "lbs" {
            weight = weight /  2.20462262185
        }
        
        // If nothing was entered save zero as weight and rep value
        allExWithSets[userPos].weight =  m_tf_Weights.text != "" ?  NSDecimalNumber(double: weight) : 0
        allExWithSets[userPos].doneReps = m_tf_Reps.text != "" ?  NSDecimalNumber(string: m_tf_Reps.text) : 0
        var alreadyExists = true
        var savePos: Int?
        let request = NSFetchRequest(entityName: "Dates")
        dates = (try! appdel.managedObjectContext?.executeFetchRequest(request))  as! [Dates]
        for var i = 0 ; i < dates.count ; i++ {
            if returnDateForm(dates[i].savedDate) == returnDateForm(date) {
                alreadyExists = false
                savePos=i;
            }
        }
        var saveData: [[String]] = []
        for var i = 0 ; i < allExWithSets.count ; i++ {
            saveData.append([allExWithSets[i].dayID, allExWithSets[i].name, "\(allExWithSets[i].reps)", "\(allExWithSets[i].doneReps)", "\(allExWithSets[i].sets)", "\(allExWithSets[i].weight)"])
            
        }
        
        // Rollback to don't save exerices which were needed to get done exercises
        appdel.rollBackContext()
        
        //Replace date
        if alreadyExists {
            let newItem = NSEntityDescription.insertNewObjectForEntityForName("Dates", inManagedObjectContext: appdel.managedObjectContext!) as! Dates
            newItem.savedDate = date
        }
        var i = 0
        
        //Save data
        for checkCells in saveData {
            let newItem = NSEntityDescription.insertNewObjectForEntityForName("DoneExercise", inManagedObjectContext: appdel.managedObjectContext!) as! DoneExercise
            newItem.date = date
            newItem.dayID = checkCells[0]
            newItem.name = checkCells[1]
            newItem.reps = NSDecimalNumber(string: checkCells[2])
            newItem.doneReps = NSDecimalNumber(string:checkCells[3])
            newItem.sets = NSDecimalNumber(string:checkCells[4])
            newItem.weight = NSDecimalNumber(string: checkCells[5])
            newItem.setCounter = setCounter[i]
            appdel.saveContext()
            i++
        }

        
        let informUser = UIAlertController(title: NSLocalizedString("Saved", comment: "Saved"), message:NSLocalizedString("Your training was saved", comment: "Your training was saved"), preferredStyle: UIAlertControllerStyle.Alert)
        informUser.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.navigationController?.popViewControllerAnimated(true)
        }))
        
        //Fabric - Analytic tool
        Answers.logLevelEnd("Finished Training",
            score: nil,
            success: true,
            customAttributes: ["Training name": saveData[0][0]])
        presentViewController(informUser, animated: true, completion: nil)
        
    }
    
    @IBAction func nextExButtonCL(sender: AnyObject) {
        
        filterSpecificView(false)
        
    }
    
    @IBAction func finishCL(sender: AnyObject) {
        
        // Save date
        date = pickerView.date
        NSUserDefaults.standardUserDefaults().setObject(pickerView.date,forKey: "dateUF")
        UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.pickerBG.alpha = 0
            }, completion: { finished in
                self.pickerBG.hidden = true
        })
        m_b_PickDate.setTitle(returnDateForm(date), forState: UIControlState.Normal)
    }

    
    // MARK: View Methods
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Handle iAd
        iAd.delegate = self
        iAd.hidden = true
        
        // Setup background
        let bgSize = CGSize(width: view.frame.width, height: view.frame.height)
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: bgSize)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
      
        // Setup start view
        m_L_ListName.text = clickedExc[0].dayID
        m_L_Weights.text = weightUnit
        
        Answers.logLevelStart("Started training", customAttributes: ["Training name": clickedExc[0].dayID])
        
        //Load in exercises as many sets they have
        for item in clickedExc as [Exercise] {
            for var i = 0 ; i < item.sets as Int ;i++ {
                setCounter.append(i+1);
                let newItem = Exercise()
                newItem.dayID = item.dayID
                newItem.sets = item.sets
                newItem.reps = item.reps
                newItem.name = item.name
                newItem.weight = item.weight
                newItem.doneReps = item.doneReps
                allExWithSets.append(newItem)
            }
        }
        
        //Set View start contents
        m_L_ExerciseName.text = allExWithSets[0].name
        if (allExWithSets[0].reps as Int) < 10 {
            m_L_Reps.text = "  / \(allExWithSets[0].reps)"
        } else {
            m_L_Reps.text = " /\(allExWithSets[0].reps)"
        }
        previousExButton.enabled = false
        previousExButton.setTitle("", forState: UIControlState.Normal)
        if allExWithSets.count < 2 {
            nextExButton.enabled = false
            nextExButton.setTitle("", forState: UIControlState.Normal)
        }
        
        //Set delegate of textfields
        m_tf_Reps.delegate = self
        m_tf_Weights.delegate = self
        
        pickerView.setDate(NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate, animated: true)
        pickerView.viewForBaselineLayout().setValue(UIColor.whiteColor(), forKeyPath: "tintColor")
        for sub in pickerView.subviews {
            sub.setValue(UIColor.whiteColor(), forKeyPath: "textColor")
            sub.setValue(UIColor.whiteColor(), forKey: "tintColor")
        }
        
        pickerTitle.text = NSLocalizedString("Choose a date", comment: "Choose a date")
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        allExWithSets = []
        date = NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate
        m_b_PickDate.setTitle(returnDateForm(date), forState: UIControlState.Normal)
        for item in clickedExc as [Exercise] {
            for var i = 0 ; i < item.sets as Int ; i++ {
                setCounter.append(i + 1);
                let newItem = Exercise()
                newItem.dayID = item.dayID
                newItem.sets = item.sets
                newItem.reps = item.reps
                newItem.name = item.name
                newItem.weight = item.weight
                newItem.doneReps = item.doneReps
                allExWithSets.append(newItem)
            }
        }
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        Answers.logLevelEnd("Canceled Training",
            score: nil,
            success: true,
            customAttributes: ["Training name": m_L_ListName.text!])
        self.navigationController?.setToolbarHidden(true, animated: true)
        
    }
    
    // MARK: My Methods
    // Fit background image to display size
    func imageResize(imageObj:UIImage, sizeChange: CGSize) -> UIImage {
        
        let hasAlpha = false
        let scale: CGFloat = 0.0
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
        
    }
    
    func filterSpecificView(animationDirection: Bool) {
        for _view in self.view.subviews {
            if let view = _view as? UIView {
                if view.tag == 123 {
                    m_L_Weights.text = weightUnit
                    var weight = (m_tf_Weights.text! as NSString).doubleValue
                    
                    //Save all in kg
                    if weightUnit == "lbs" {
                        weight = weight /  2.20462262185
                    }
                    allExWithSets[userPos].weight =  m_tf_Weights.text != "" ? NSDecimalNumber(double: weight) : 0
                    allExWithSets[userPos].doneReps = m_tf_Reps.text != "" ?  NSDecimalNumber(string: m_tf_Reps.text) : 0
                    slideIn(1, completionDelegate: _view, direction: animationDirection)
                    weight = (allExWithSets[userPos].weight).doubleValue
                    
                    //Show as lbs
                    if weightUnit == "lbs" {
                        weight = weight *  2.20462262185
                    }
                    if weight < 1000 {
                        m_tf_Weights.text = NSString(format: "%.2f", weight) as String
                    } else if weight < 10000 {
                        m_tf_Weights.text = NSString(format: "%.1f", weight) as String
                    } else {
                        m_tf_Weights.text = NSString(format: "%.0f", weight) as String
                    }
                    if weight == 0 {
                        m_tf_Weights.text = ""
                    }
                    
                    m_tf_Reps.text = allExWithSets[userPos].doneReps == 0 ? "" :String(stringInterpolationSegment: allExWithSets[userPos].doneReps)
                    let translationSet = NSLocalizedString("Set", comment: "Set")
                    m_L_SetCounter.text = "\(setCounter[userPos]).\(translationSet)"

                    m_L_ExerciseName.text = allExWithSets[userPos].name
                    
                    if (allExWithSets[userPos].reps as Int) < 10 {
                        m_L_Reps.text = "  / \(allExWithSets[userPos].reps)"
                    } else {
                        m_L_Reps.text = " /\(allExWithSets[userPos].reps)"
                    }
                    
                    // Disable / Enable buttons
                    if userPos > 0 {
                        previousExButton.enabled = true
                        previousExButton.setTitle("<", forState: UIControlState.Normal)
                    } else {
                        previousExButton.enabled = false
                        previousExButton.setTitle("", forState: UIControlState.Normal)
                    }
                    if userPos+1 < allExWithSets.count {
                        nextExButton.enabled = true
                        nextExButton.setTitle(">", forState: UIControlState.Normal)
                    } else {
                        nextExButton.enabled = false
                        nextExButton.setTitle("", forState: UIControlState.Normal)
                    }
                    layoutAnimated(true)
                }
            }
        }
        
    }
    
    // Get date in a good format
    func returnDateForm(date: NSDate) -> String {
        
        let dateFormatter = NSDateFormatter()
        let theDateFormat = NSDateFormatterStyle.ShortStyle
        let theTimeFormat = NSDateFormatterStyle.NoStyle
        dateFormatter.dateStyle = theDateFormat
        dateFormatter.timeStyle = theTimeFormat
        return dateFormatter.stringFromDate(date)
        
    }
    
    func updateTime() {
        
        currentTime = NSDate.timeIntervalSinceReferenceDate()
        
        // Find the difference between current time and start time.
        var elapsedTime: NSTimeInterval = currentTime! - startTime
        
        // Calculate the minutes in elapsed time.
        let minutes = UInt8(elapsedTime / 60.0)
        elapsedTime -= (NSTimeInterval(minutes) * 60)
        
        // Calculate the seconds in elapsed time.
        let seconds = UInt8(elapsedTime)
        elapsedTime -= NSTimeInterval(seconds)
        
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
    func slideIn(duration: NSTimeInterval = 1.0, completionDelegate: AnyObject? = nil, direction: Bool) {
        
        // Create a CATransition animation
        let slideInTransition = CATransition()
        
        // Set its callback delegate to the completionDelegate that was provided (if any)
        if let delegate: AnyObject = completionDelegate {
            slideInTransition.delegate = delegate
        }
        
        // Customize the animation's properties
        slideInTransition.type = kCATransitionMoveIn
        if direction {
            userPos--
            slideInTransition.subtype = kCATransitionFromLeft
        } else {
            userPos++
            slideInTransition.subtype = kCATransitionFromRight
        }
        slideInTransition.duration = duration
        slideInTransition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        slideInTransition.fillMode = kCAFillModeRemoved
        
        // Add the animation to the View's layer
        (completionDelegate as! UIView).layer.addAnimation(slideInTransition, forKey: "slideInTransition")
        
    }
    
    func setupPickerView() {
        
        blurView.frame = pickerBG.bounds
        blurView.translatesAutoresizingMaskIntoConstraints = false
        if !pickerBG.subviews.contains(blurView) {
            pickerBG.addSubview(blurView)
            pickerBG.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: pickerBG, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0.0))
            pickerBG.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: pickerBG, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 0.0))
            pickerBG.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: pickerBG, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0.0))
            pickerBG.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: pickerBG, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 0.0))
        }
        pickerBG.alpha = 0
        pickerBG.hidden = false
        self.view.bringSubviewToFront(pickerBG)
        pickerBG.bringSubviewToFront(pickerView)
        pickerBG.bringSubviewToFront(finishButton)
        pickerBG.bringSubviewToFront(pickerTitle)
        UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.pickerBG.alpha = 1
            }, completion: { finished in
        })
        
    }

    
    // MARK: Keyboard methods
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        //Close Keyboard when clicking outside
        m_tf_Weights.resignFirstResponder()
        m_tf_Reps.resignFirstResponder()
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.endEditing(true)
        return false
        
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        self.view.frame.origin.y -= 20
        
    }
    
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        self.view.frame.origin.y += 20
        if textField == m_tf_Reps && m_tf_Reps.text != "" {
            allExWithSets[userPos].doneReps = Int(m_tf_Reps.text!)!
        }
        if textField == m_tf_Weights &&  m_tf_Weights.text != "" {
            allExWithSets[userPos].weight = NSDecimalNumber(string: m_tf_Weights.text)
        }
        
    }
    
    // Set textfield input options
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        let text = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        let disallowedCharacterSet = NSCharacterSet(charactersInString: "0123456789.").invertedSet
        let replacementStringIsLegal = string.rangeOfCharacterFromSet(disallowedCharacterSet) == nil
        let scanner = NSScanner(string: text)
        let resultingTextIsNumeric = scanner.scanDecimal(nil) && scanner.atEnd
        var getDecimalNumbers = (textField.text! as NSString).componentsSeparatedByString(".")
        if getDecimalNumbers.count > 1 && (getDecimalNumbers[1] as NSString).integerValue > 9 && string != ""  {
            return false
        }
        let newLength = textField.text!.characters.count + string.characters.count - range.length
        var back = 0
        if textField == m_tf_Weights {
            back = 6
            let resultingStringLengthIsLegal = text.characters.count <= 6
            if text.characters.count == 0 || (replacementStringIsLegal &&
                resultingStringLengthIsLegal &&
                resultingTextIsNumeric) {
                    if text != "." {
                        return true
                    }
            }
            return false
        } else if textField == m_tf_Reps {
            back = 2
            if newLength <= back && ((Int(text) >= 0 && Int(text) < 100) || text == "") {
                return true
            } else {
                return false
            }
        }
        return newLength <= back
    }
    
    // MARK: iAd
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        
        self.layoutAnimated(true)
        
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        
        self.layoutAnimated(true)
        
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        
        return true
        
    }
    
    func layoutAnimated(animated : Bool) {
        
        if iAd.bannerLoaded {
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
    
    // Show correct background after rotation
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
    }
    
}
