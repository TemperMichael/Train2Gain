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
    
    var dates : [Dates] = []
    var measures : [Measurements] = []
    
    let  requestMeasures = NSFetchRequest(entityName: "Measurements")
    
    var date : NSDate!

    
    var appdel =  UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet weak var m_tf_Weights: UITextField!
    
    @IBOutlet weak var m_tf_Chest: UITextField!
    
    @IBOutlet weak var iAd: ADBannerView!
    
    @IBOutlet weak var m_tf_Arm: UITextField!
    
    @IBOutlet weak var m_tf_Waist: UITextField!
    
    @IBOutlet weak var m_tf_Leg: UITextField!
    
    
    @IBOutlet weak var m_L_WeightUnit: UILabel!
    
    @IBOutlet var m_L_LengthUnit: [UILabel]!
    
    
    @IBOutlet weak var m_b_PickDate: UIButton!
    
     var tutorialView:UIImageView!
    
    
    var weightUnit: String! = NSUserDefaults.standardUserDefaults().objectForKey("weightUnit")! as! String
    
    var lengthUnit:String! = NSUserDefaults.standardUserDefaults().objectForKey("lengthUnit")! as! String
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        iAd.delegate = self
        iAd.hidden = true
       
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)

        if(NSUserDefaults.standardUserDefaults().objectForKey("tutorialBodyMeasurements") == nil){
            
            //self.view.backgroundColor = UIColor(red: 0/255, green: 185/255, blue: 1, alpha: 1)
            
            tutorialView = UIImageView(frame: self.view.frame)
            
            tutorialView.image = UIImage(named: "TutorialBodyMeasurements.png")
            tutorialView.frame.origin.y += 18
            if(self.view.frame.size.height <= 490){
                tutorialView.frame.size.height += 60
            }else{
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
        
        if(editMode){
            measures = (try! appdel.managedObjectContext?.executeFetchRequest(requestMeasures))  as! [Measurements]
            
            for singleMeasure in measures{
                if(returnDateForm(singleMeasure.date) ==  returnDateForm(NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate)){
                    m_tf_Weights.text = getCorrectString(singleMeasure.weight.doubleValue)
                    m_tf_Arm.text = getCorrectString(singleMeasure.arm.doubleValue)
                    m_tf_Leg.text = getCorrectString(singleMeasure.leg.doubleValue)
                    m_tf_Chest.text = getCorrectString(singleMeasure.chest.doubleValue)
                    m_tf_Waist.text = getCorrectString(singleMeasure.waist.doubleValue)
                }
                
            }
            
        }
        
        for singleLabel in m_L_LengthUnit{
            singleLabel.text = lengthUnit
        }
        m_L_WeightUnit.text = weightUnit
        
        
        m_b_PickDate.setTitle(returnDateForm(date), forState: UIControlState.Normal)
    }
    
    
    func hideTutorial(){
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)

        self.navigationController?.navigationBarHidden = false
        UIView.transitionWithView(self.view, duration: 1, options: UIViewAnimationOptions.CurveLinear, animations: {
            self.tutorialView.alpha = 0;
            
            }, completion:{ finished in
                NSUserDefaults.standardUserDefaults().setObject(false, forKey: "tutorialBodyMeasurements")
                
                self.tutorialView.removeFromSuperview()
        })
        
    }

    
    func getCorrectString(amount : Double) -> String{
        var returnString = "0"
        
        if(amount<10){
            returnString = NSString(format: "%.4f",amount) as String
        }else if(amount < 100){
            returnString =  NSString(format: "%.3f",amount) as String
        }else if(amount < 1000){
            returnString = NSString(format: "%.2f",amount) as String
        }
      
        if(amount == 0){
            returnString = "0"
        }
        
        return returnString
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
          date = NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate
         m_b_PickDate.setTitle(returnDateForm(date), forState: UIControlState.Normal)
    }
    
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

    
    
    @IBAction func saveCL(sender: AnyObject) {
        
        var managedObjectContext: NSManagedObjectContext? = {
            let coordinator = self.appdel.persistentStoreCoordinator;
            if coordinator == nil{
                return nil
            }
            let managedObjectContext = NSManagedObjectContext()
            managedObjectContext.persistentStoreCoordinator = coordinator
            return managedObjectContext
            
            }()
        
        var alreadyExists = true
        var savePos : Int?
        let  request = NSFetchRequest(entityName: "Dates")
        dates = (try! appdel.managedObjectContext?.executeFetchRequest(request))  as! [Dates]
        
        
            measures = (try! appdel.managedObjectContext?.executeFetchRequest(requestMeasures))  as! [Measurements]
        
        
        
   
            date = NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate
            
        
        
        for(var i = 0; i < dates.count ; i++){
            
            if(returnDateForm(dates[i].savedDate) == returnDateForm(date)){
                alreadyExists = false
                savePos=i;
            }
            
        }

        
        if(alreadyExists){
            
            let newItem = NSEntityDescription.insertNewObjectForEntityForName("Dates", inManagedObjectContext: appdel.managedObjectContext!) as! Dates
            newItem.savedDate = NSDate()
            
        }
        
        
        if(!editMode){
        if(measures.count <= 0){
           addNewMeasure()
        }else{
            let lastMeasure = measures[measures.count-1]
            if(returnDateForm(lastMeasure.date) != returnDateForm(NSDate())){
             addNewMeasure()
            }else{
                addMeasure(lastMeasure)
            }
        }
        }else{
            var measurementExists = false
            if(!alreadyExists){
                for singleMeasure in measures{
                    if(returnDateForm(singleMeasure.date) == returnDateForm(date)){
                        measurementExists = true
                        addMeasure(singleMeasure)
                    }
                }
            }
            
            
            if(!measurementExists){
                addNewMeasure()
            }

            
        }
        
        appdel.saveContext()
        
        
        let informUser = UIAlertController(title: "Saved", message:"Your body measurements were saved", preferredStyle: UIAlertControllerStyle.Alert)
        informUser.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.navigationController?.popViewControllerAnimated(true)
            
            
        }))
        
        Answers.logContentViewWithName("Body Measurement",
            contentType: "Saved data",
            contentId: String(stringInterpolationSegment: editMode),
            customAttributes: [:])
        
        presentViewController(informUser, animated: true, completion: nil)
        
        
        
    }
    
    //Get date in a good format
    func returnDateForm(date:NSDate) -> String{
        let dateFormatter = NSDateFormatter()
        
        let theDateFormat = NSDateFormatterStyle.ShortStyle
        let theTimeFormat = NSDateFormatterStyle.NoStyle
        
        dateFormatter.dateStyle = theDateFormat
        dateFormatter.timeStyle = theTimeFormat
        
        return dateFormatter.stringFromDate(date)
    }
    
    //Add measures in right units
    
    func addNewMeasure(){
        let newItem = NSEntityDescription.insertNewObjectForEntityForName("Measurements", inManagedObjectContext: appdel.managedObjectContext!) as! Measurements
        addMeasure(newItem)
    }
    
    func addMeasure(_Object:Measurements){
        //TODO werte  nicht formatiert gespeichert
        var value : Double!
        
        _Object.date = date
        
        value = (m_tf_Weights.text! as NSString).doubleValue
        if(weightUnit == "lbs"){
            value = value /  2.20462262185
        }
        _Object.weight = NSDecimalNumber(string: !m_tf_Weights.text!.isEmpty ? "\(value)" : "0")
        
        
        value = (m_tf_Arm.text! as NSString).doubleValue
        if(lengthUnit == "inch"){
            value = value * 2.54
        }
        _Object.arm = NSDecimalNumber(string: !m_tf_Arm.text!.isEmpty ? "\(value)" : "0")
        
        
        value = (m_tf_Chest.text! as NSString).doubleValue
        if(lengthUnit == "inch"){
            value = value * 2.54        }
        _Object.chest = NSDecimalNumber(string: !m_tf_Chest.text!.isEmpty ? "\(value)" : "0")
        
        value = (m_tf_Waist.text! as NSString).doubleValue
        if(lengthUnit == "inch"){
            value = value * 2.54        }
        _Object.waist = NSDecimalNumber(string: !m_tf_Waist.text!.isEmpty ? "\(value)" : "0")
        
        value = (m_tf_Leg.text! as NSString).doubleValue
        if(lengthUnit == "inch"){
            value = value * 2.54        }
        _Object.leg = NSDecimalNumber(string: !m_tf_Leg.text!.isEmpty ? "\(value)" : "0")
        
    }
    
    func imageResize (imageObj:UIImage, sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    //--------------------------------------------------------------
    //Keyboard methods
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        //Close Keyboard when clicking outside
        m_tf_Weights.resignFirstResponder()
        m_tf_Chest.resignFirstResponder()
        m_tf_Arm.resignFirstResponder()
        m_tf_Waist.resignFirstResponder()
        m_tf_Leg.resignFirstResponder()
        
    }
    
    
    
    func textFieldDidBeginEditing(textField: UITextField) {
        switch (textField){
        case m_tf_Arm:
            self.view.frame.origin.y -= 80
            break;
        case m_tf_Waist:
            self.view.frame.origin.y -= 150
            break;
            
        case m_tf_Leg:
            self.view.frame.origin.y -= 150
            break;
            
        default:
            break;
            
        }
    }
    
    
    func textFieldDidEndEditing(textField: UITextField) {
        switch (textField){
        case m_tf_Arm:
            self.view.frame.origin.y += 80
            break;
        case m_tf_Waist:
            self.view.frame.origin.y += 150
            break;
            
        case m_tf_Leg:
            self.view.frame.origin.y += 150
            break;
            
        default:
            break;
            
        }
        
        
    }
    
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        
        if(string == "\n"){
            textField.endEditing(true)
            switch (textField){
                
            case m_tf_Weights:
                m_tf_Chest.becomeFirstResponder()
                break;
                
            case m_tf_Chest:
                m_tf_Arm.becomeFirstResponder()
                break;
                
            case m_tf_Arm:
                m_tf_Waist.becomeFirstResponder()
                break;
            case m_tf_Waist:
                m_tf_Leg.becomeFirstResponder()
                break;
                
            case m_tf_Leg:
                
                break;
                
            default:
                break;
                
            }
        }
        
        var getDecimalNumbers = (textField.text! as NSString).componentsSeparatedByString(".")
        if getDecimalNumbers.count > 1 && (getDecimalNumbers[1] as NSString).integerValue > 9 && string != ""  {
            return false
        }
        
        
        let text = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        
        
        
        let disallowedCharacterSet = NSCharacterSet(charactersInString: "0123456789.").invertedSet
        let replacementStringIsLegal = string.rangeOfCharacterFromSet(disallowedCharacterSet) == nil
        
        let resultingStringLengthIsLegal =  (getDecimalNumbers.count > 1 || string == ".") ? text.characters.count <= 6 : text.characters.count <= 3
        
        let scanner = NSScanner(string: text)
        let resultingTextIsNumeric = scanner.scanDecimal(nil) && scanner.atEnd
        if(text.characters.count == 0 || (replacementStringIsLegal &&
            resultingStringLengthIsLegal &&
            resultingTextIsNumeric) ){
                
                
                if(text != "."){
                    
                    
                    return true
                }
                
                
        }
        
        return false
        
    }
    
    // iAd Handling
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        self.layoutAnimated(true)
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        self.layoutAnimated(true)
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        return true
    }
    func layoutAnimated(animated : Bool){
        
        var contentFrame = self.view.bounds;
        var bannerFrame = iAd.frame;
        if (iAd.bannerLoaded)
        {
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

    
}
