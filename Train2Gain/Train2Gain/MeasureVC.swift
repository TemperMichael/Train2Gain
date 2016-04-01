//
//  MeasureVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 28.03.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import CoreData
import Fabric
import Crashlytics
import iAd

class MeasureVC: UIViewController, UITextFieldDelegate, ADBannerViewDelegate {
    
    var editMode = false
    var dates: [Dates] = []
    var measures: [Measurements] = []
    var date: NSDate!
    var appdel = UIApplication.sharedApplication().delegate as! AppDelegate
    var tutorialView: UIImageView!
    var weightUnit: String! = NSUserDefaults.standardUserDefaults().objectForKey("weightUnit")! as! String
    var lengthUnit: String! = NSUserDefaults.standardUserDefaults().objectForKey("lengthUnit")! as! String
    let requestMeasures = NSFetchRequest(entityName: "Measurements")
    
    // MARK: IBOutles & IBActions
    @IBOutlet weak var m_tf_Weights: UITextField!
    @IBOutlet weak var m_tf_Chest: UITextField!
    @IBOutlet weak var iAd: ADBannerView!
    @IBOutlet weak var m_tf_Arm: UITextField!
    @IBOutlet weak var m_tf_Waist: UITextField!
    @IBOutlet weak var m_tf_Leg: UITextField!
    @IBOutlet weak var m_L_WeightUnit: UILabel!
    @IBOutlet weak var m_b_PickDate: UIButton!
    @IBOutlet var m_L_LengthUnit: [UILabel]!
    
    @IBAction func nextDayCL(sender: AnyObject) {
        
        // Go to next day
        date = date.dateByAddingTimeInterval(60 * 60 * 24)
        NSUserDefaults.standardUserDefaults().setObject(date ,forKey: "dateUF")
        m_b_PickDate.setTitle(returnDateForm(date), forState: UIControlState.Normal)
        
    }
    
    @IBAction func prevDayCL(sender: AnyObject) {
        
        //Go to prevoius day
        date = date.dateByAddingTimeInterval(-60*60*24)
        NSUserDefaults.standardUserDefaults().setObject(date ,forKey: "dateUF")
        m_b_PickDate.setTitle(returnDateForm(date), forState: UIControlState.Normal)
        
    }
    
    // MARK: View Methods
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Handle iAd
        iAd.delegate = self
        iAd.hidden = true
        
        // Set background
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
        // Show tutorial
        if NSUserDefaults.standardUserDefaults().objectForKey("tutorialBodyMeasurements") == nil {
            tutorialView = UIImageView(frame: self.view.frame)
            tutorialView.image = UIImage(named: "TutorialBodyMeasurements.png")
            tutorialView.frame.origin.y += 18
            if self.view.frame.size.height <= 490 {
                tutorialView.frame.size.height += 60
            } else {
                tutorialView.frame.size.height -= 60
            }
            tutorialView.userInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action:"hideTutorial")
            tutorialView.addGestureRecognizer(tap)
            self.view.addSubview(tutorialView)
            self.navigationController?.navigationBarHidden = true
        }
        date = NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate
        m_tf_Weights.delegate = self
        m_tf_Chest.delegate = self
        m_tf_Arm.delegate = self
        m_tf_Waist.delegate = self
        m_tf_Leg.delegate = self

        // Setup content of view
        if editMode {
            measures = (try! appdel.managedObjectContext?.executeFetchRequest(requestMeasures)) as! [Measurements]
            for singleMeasure in measures {
                if returnDateForm(singleMeasure.date) == returnDateForm(NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate) {
                    m_tf_Weights.text = getCorrectString(singleMeasure.weight.doubleValue,id: 0)
                    m_tf_Arm.text = getCorrectString(singleMeasure.arm.doubleValue,id: 1)
                    m_tf_Leg.text = getCorrectString(singleMeasure.leg.doubleValue,id: 1)
                    m_tf_Chest.text = getCorrectString(singleMeasure.chest.doubleValue,id: 1)
                    m_tf_Waist.text = getCorrectString(singleMeasure.waist.doubleValue,id: 1)
                }
            }
        }
        for singleLabel in m_L_LengthUnit {
            singleLabel.text = lengthUnit
        }
        m_L_WeightUnit.text = weightUnit
        m_b_PickDate.setTitle(returnDateForm(date), forState: UIControlState.Normal)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        date = NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate
        m_b_PickDate.setTitle(returnDateForm(date), forState: UIControlState.Normal)
        
    }
    
    // MARK: My Methods
    func hideTutorial() {
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
        self.navigationController?.navigationBarHidden = false
        UIView.transitionWithView(self.view, duration: 1, options: UIViewAnimationOptions.CurveLinear, animations: {
            self.tutorialView.alpha = 0
            }, completion:{ finished in
                NSUserDefaults.standardUserDefaults().setObject(false, forKey: "tutorialBodyMeasurements")
                self.tutorialView.removeFromSuperview()
        })
        
    }

    func getCorrectString(var amount : Double, id : Int) -> String{
      
        //Show as lbs
        if id == 0 && weightUnit == "lbs" {
            amount = amount *  2.20462262185
        }
        
        if id == 1 && lengthUnit == "inch" {
            amount = amount/2.54
        }
        var returnString = NSString(format:"%.2f", amount) as String
 /*
        if(amount<10){
            returnString = NSString(format: "%.4f",amount) as String
        }else if(amount < 100){
            returnString =  NSString(format: "%.3f",amount) as String
        }else if(amount < 10000){
            returnString = NSString(format: "%.2f",amount) as String
        }
*/
        
        if amount == 0 {
            returnString = "0"
        }
        return returnString
        
    }

    @IBAction func saveCL(sender: AnyObject) {
        
        var alreadyExists = true
        var savePos: Int?
        let  request = NSFetchRequest(entityName: "Dates")
        dates = (try! appdel.managedObjectContext?.executeFetchRequest(request))  as! [Dates]
        measures = (try! appdel.managedObjectContext?.executeFetchRequest(requestMeasures))  as! [Measurements]
        date = NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate
        
        
        // Check if data already exists
        for(var i = 0; i < dates.count ; i++){
            
            if(returnDateForm(dates[i].savedDate) == returnDateForm(date)){
                alreadyExists = false
                savePos=i;
            }
            
        }
        
        //Replace date
        if alreadyExists {
            let newItem = NSEntityDescription.insertNewObjectForEntityForName("Dates", inManagedObjectContext: appdel.managedObjectContext!) as! Dates
            newItem.savedDate = NSDate()
        }
        
        // Save data in correct way
        if !editMode {
            if measures.count <= 0 {
                addNewMeasure()
            } else {
                let lastMeasure = measures[measures.count-1]
                if returnDateForm(lastMeasure.date) != returnDateForm(NSDate()) {
                    addNewMeasure()
                } else {
                    addMeasure(lastMeasure)
                }
            }
        } else {
            var measurementExists = false
            if !alreadyExists {
                for singleMeasure in measures {
                    if returnDateForm(singleMeasure.date) == returnDateForm(date) {
                        measurementExists = true
                        addMeasure(singleMeasure)
                    }
                }
            }
            if !measurementExists {
                addNewMeasure()
            }
        }
        
        appdel.saveContext()

        let informUser = UIAlertController(title: NSLocalizedString("Saved", comment: "Saved"), message:NSLocalizedString("Your body measurements were saved", comment: "Your body measurements were saved"), preferredStyle: UIAlertControllerStyle.Alert)
        informUser.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.navigationController?.popViewControllerAnimated(true)
            
            
        }))
        
        // Fabric - Analytic tool
        Answers.logContentViewWithName("Body Measurement",
            contentType: "Saved data",
            contentId: String(stringInterpolationSegment: editMode),
            customAttributes: [:])
        
        presentViewController(informUser, animated: true, completion: nil)
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
    
    // Add measures in right units
    func addNewMeasure(){
        
        let newItem = NSEntityDescription.insertNewObjectForEntityForName("Measurements", inManagedObjectContext: appdel.managedObjectContext!) as! Measurements
        addMeasure(newItem)
        
    }
    
    func addMeasure(_Object: Measurements) {
        
        // TODO Werte  nicht formatiert gespeichert
        var value : Double!
        _Object.date = date
        value = (m_tf_Weights.text! as NSString).doubleValue
        if weightUnit == "lbs" {
            value = value / 2.20462262185
        }
        _Object.weight = NSDecimalNumber(string: !m_tf_Weights.text!.isEmpty ? "\(value)" : "0")
        value = (m_tf_Arm.text! as NSString).doubleValue
        if lengthUnit == "inch" {
            value = value * 2.54
        }
        _Object.arm = NSDecimalNumber(string: !m_tf_Arm.text!.isEmpty ? "\(value)" : "0")
        value = (m_tf_Chest.text! as NSString).doubleValue
        if lengthUnit == "inch" {
            value = value * 2.54
        }
        _Object.chest = NSDecimalNumber(string: !m_tf_Chest.text!.isEmpty ? "\(value)" : "0")
        value = (m_tf_Waist.text! as NSString).doubleValue
        if lengthUnit == "inch" {
            value = value * 2.54
        }
        _Object.waist = NSDecimalNumber(string: !m_tf_Waist.text!.isEmpty ? "\(value)" : "0")
        value = (m_tf_Leg.text! as NSString).doubleValue
        if lengthUnit == "inch" {
            value = value * 2.54
        }
        _Object.leg = NSDecimalNumber(string: !m_tf_Leg.text!.isEmpty ? "\(value)" : "0")

    }
    
    // Resize background image to fit in view
    func imageResize(imageObj: UIImage, sizeChange:CGSize) -> UIImage {
        
        let hasAlpha = false
        let scale: CGFloat = 0.0
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
        
    }
    
    // MARK: Textfield Methods
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        // Close Keyboard when clicking outside
        m_tf_Weights.resignFirstResponder()
        m_tf_Chest.resignFirstResponder()
        m_tf_Arm.resignFirstResponder()
        m_tf_Waist.resignFirstResponder()
        m_tf_Leg.resignFirstResponder()
        
    }
    
    
    // Move view to always show the selected textfield
    func textFieldDidBeginEditing(textField: UITextField) {
        
        switch textField {
            case m_tf_Arm :
                self.view.frame.origin.y -= 80
            case m_tf_Waist :
                self.view.frame.origin.y -= 150
            case m_tf_Leg :
                self.view.frame.origin.y -= 150
            default :
                print("Error textfield")
        }
        
    }
    
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        switch textField {
            case m_tf_Arm :
                self.view.frame.origin.y += 80
            case m_tf_Waist :
                self.view.frame.origin.y += 150
            case m_tf_Leg :
                self.view.frame.origin.y += 150
            default :
                print("Error textfield")
        }
        
    }
    
    // Setup textfield input settings
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        if string == "\n" {
            textField.endEditing(true)
            switch textField {
                case m_tf_Weights:
                    m_tf_Chest.becomeFirstResponder()
                case m_tf_Chest:
                    m_tf_Arm.becomeFirstResponder()
                case m_tf_Arm:
                    m_tf_Waist.becomeFirstResponder()
                case m_tf_Waist:
                    m_tf_Leg.becomeFirstResponder()
                case m_tf_Leg:
                    break
                default:
                    print("Error textfield")
            }
        }
        var getDecimalNumbers = (textField.text! as NSString).componentsSeparatedByString(".")
        
        
        if getDecimalNumbers.count > 1 && (getDecimalNumbers[1] as NSString).length > 1 && string != ""  {
            return false
        }
        let text = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        let disallowedCharacterSet = NSCharacterSet(charactersInString: "0123456789.").invertedSet
        let replacementStringIsLegal = string.rangeOfCharacterFromSet(disallowedCharacterSet) == nil
        let resultingStringLengthIsLegal =  (getDecimalNumbers.count > 1 || string == ".") ? text.characters.count <= 6 : text.characters.count <= 3
        let scanner = NSScanner(string: text)
        let resultingTextIsNumeric = scanner.scanDecimal(nil) && scanner.atEnd
        if text.characters.count == 0 || (replacementStringIsLegal &&
            resultingStringLengthIsLegal &&
            resultingTextIsNumeric) {
                if text != "." {
                    return true
                }
        }
        return false
        
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
    
    func layoutAnimated(animated: Bool) {
        
        if iAd.bannerLoaded{
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
        
        if NSUserDefaults.standardUserDefaults().objectForKey("tutorialBodyMeasurements") == nil {
            hideTutorial()
        }
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
    }
    
    
}
