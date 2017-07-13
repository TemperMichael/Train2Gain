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
    var date: Date!
    var appdel = UIApplication.shared.delegate as! AppDelegate
    var tutorialView: UIImageView!
    var weightUnit = UserDefaults.standard.object(forKey: "weightUnit")! as! String
    var lengthUnit = UserDefaults.standard.object(forKey: "lengthUnit")! as! String
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
    let requestMeasures = NSFetchRequest<Measurements>(entityName: "Measurements")
    
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
    @IBOutlet weak var pickerBG: UIView!
    
    @IBOutlet weak var pickerView: UIDatePicker!
    @IBOutlet weak var pickerTitle: UILabel!
    @IBOutlet weak var finishButton: UIButton!
    @IBAction func nextDayCL(_ sender: AnyObject) {
        
        // Go to next day
        date = date.addingTimeInterval(60 * 60 * 24)
        UserDefaults.standard.set(date ,forKey: "dateUF")
        m_b_PickDate.setTitle(returnDateForm(date), for: UIControlState())
        
    }
    
    @IBAction func prevDayCL(_ sender: AnyObject) {
        
        //Go to prevoius day
        date = date.addingTimeInterval(-60*60*24)
        UserDefaults.standard.set(date ,forKey: "dateUF")
        m_b_PickDate.setTitle(returnDateForm(date), for: UIControlState())
        
    }

       
    @IBAction func finishCL(_ sender: AnyObject) {
        
        // Save date
        date = pickerView.date
        UserDefaults.standard.set(pickerView.date,forKey: "dateUF")
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.pickerBG.alpha = 0
            }, completion: { finished in
                self.pickerBG.isHidden = true
        })
        m_b_PickDate.setTitle(returnDateForm(date), for: UIControlState())
        
    }
    
    @IBAction func pickDateClicked(_ sender: AnyObject) {
        
        setupPickerView()
        
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
        if UserDefaults.standard.object(forKey: "tutorialBodyMeasurements") == nil {
            tutorialView = UIImageView(frame: self.view.frame)
            tutorialView.image = UIImage(named: "TutorialBodyMeasurements.png")
            tutorialView.frame.origin.y += 18
            if self.view.frame.size.height <= 490 {
                tutorialView.frame.size.height += 60
            } else {
                tutorialView.frame.size.height -= 60
            }
            tutorialView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action:#selector(MeasureVC.hideTutorial))
            tutorialView.addGestureRecognizer(tap)
            self.view.addSubview(tutorialView)
            self.navigationController?.isNavigationBarHidden = true
        }
        date = UserDefaults.standard.object(forKey: "dateUF") as! Date
        m_tf_Weights.delegate = self
        m_tf_Chest.delegate = self
        m_tf_Arm.delegate = self
        m_tf_Waist.delegate = self
        m_tf_Leg.delegate = self

        // Setup content of view
        if editMode {
            
            measures = (try! appdel.managedObjectContext?.fetch(requestMeasures))!
            for singleMeasure in measures {
                if returnDateForm(singleMeasure.date as Date) == returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date) {
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
        m_b_PickDate.setTitle(returnDateForm(date), for: UIControlState())
        
        pickerView.setDate(UserDefaults.standard.object(forKey: "dateUF") as! Date, animated: true)
        pickerView.forBaselineLayout().setValue(UIColor.white, forKeyPath: "tintColor")
        for sub in pickerView.subviews {
            sub.setValue(UIColor.white, forKeyPath: "textColor")
            sub.setValue(UIColor.white, forKey: "tintColor")
        }
        
        pickerTitle.text = NSLocalizedString("Choose a date", comment: "Choose a date")

        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        date = UserDefaults.standard.object(forKey: "dateUF") as! Date
        m_b_PickDate.setTitle(returnDateForm(date), for: UIControlState())
        
    }
    
    // MARK: My Methods
    func hideTutorial() {
        
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
        self.navigationController?.isNavigationBarHidden = false
        UIView.transition(with: self.view, duration: 1, options: UIViewAnimationOptions.curveLinear, animations: {
            self.tutorialView.alpha = 0
            }, completion:{ finished in
                UserDefaults.standard.set(false, forKey: "tutorialBodyMeasurements")
                self.tutorialView.removeFromSuperview()
        })
        
    }

    func getCorrectString(_ amount : Double, id : Int) -> String{
        
        var amount = amount
      
        //Show as lbs
        if id == 0 && weightUnit == "lbs" {
            amount = amount *  2.20462262185
        }
        
        if id == 1 && lengthUnit == "inch" {
            amount = amount/2.54
        }
        var returnString = NSString(format:"%.2f", amount) as String
        
        if amount == 0 {
            returnString = "0"
        }
        return returnString
        
    }

    @IBAction func saveCL(_ sender: AnyObject) {
        
        var alreadyExists = true
        var savePos: Int?
        let  request = NSFetchRequest<NSFetchRequestResult>(entityName: "Dates")
        dates = (try! appdel.managedObjectContext?.fetch(request))  as! [Dates]
        
        measures = (try! appdel.managedObjectContext?.fetch(requestMeasures))!
        date = UserDefaults.standard.object(forKey: "dateUF") as! Date
        
        
        // Check if data already exists
        for i in 0 ..< dates.count {
            if(returnDateForm(dates[i].savedDate as Date) == returnDateForm(date)){
                alreadyExists = false
                savePos=i;
            }
        }
        
        //Replace date
        if alreadyExists {
            let newItem = NSEntityDescription.insertNewObject(forEntityName: "Dates", into: appdel.managedObjectContext!) as! Dates
            newItem.savedDate = Date()
        }
        
        // Save data in correct way
        if !editMode {
            if measures.count <= 0 {
                addNewMeasure()
            } else {
                let lastMeasure = measures[measures.count-1]
                if returnDateForm(lastMeasure.date as Date) != returnDateForm(Date()) {
                    addNewMeasure()
                } else {
                    addMeasure(lastMeasure)
                }
            }
        } else {
            var measurementExists = false
            if !alreadyExists {
                for singleMeasure in measures {
                    if returnDateForm(singleMeasure.date as Date) == returnDateForm(date) {
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

        let informUser = UIAlertController(title: NSLocalizedString("Saved", comment: "Saved"), message:NSLocalizedString("Your body measurements were saved", comment: "Your body measurements were saved"), preferredStyle: UIAlertControllerStyle.alert)
        informUser.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.navigationController?.popViewController(animated: true)
        }))
        
        // Fabric - Analytic tool
        Answers.logContentView(withName: "Body Measurement",
            contentType: "Saved data",
            contentId: String(stringInterpolationSegment: editMode),
            customAttributes: [:])
        
        present(informUser, animated: true, completion: nil)
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
    
    // Add measures in right units
    func addNewMeasure(){
        
        let newItem = NSEntityDescription.insertNewObject(forEntityName: "Measurements", into: appdel.managedObjectContext!) as! Measurements
        addMeasure(newItem)
        
    }
    
    func addMeasure(_ _Object: Measurements) {
        
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
    func imageResize(_ imageObj: UIImage, sizeChange:CGSize) -> UIImage {
        
        let hasAlpha = false
        let scale: CGFloat = 0.0
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
        
    }
    
    func setupPickerView() {
        
        blurView.frame = pickerBG.bounds
        blurView.translatesAutoresizingMaskIntoConstraints = false
        if !pickerBG.subviews.contains(blurView) {
            pickerBG.addSubview(blurView)
            pickerBG.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: pickerBG, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0.0))
            pickerBG.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: pickerBG, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0.0))
            pickerBG.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: pickerBG, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0.0))
            pickerBG.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: pickerBG, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0.0))
        }
        pickerBG.alpha = 0
        pickerBG.isHidden = false
        self.view.bringSubview(toFront: pickerBG)
        pickerBG.bringSubview(toFront: pickerView)
        pickerBG.bringSubview(toFront: finishButton)
        pickerBG.bringSubview(toFront: pickerTitle)
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.pickerBG.alpha = 1
            }, completion: { finished in
        })
        
    }
    
    // MARK: Textfield Methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Close Keyboard when clicking outside
        m_tf_Weights.resignFirstResponder()
        m_tf_Chest.resignFirstResponder()
        m_tf_Arm.resignFirstResponder()
        m_tf_Waist.resignFirstResponder()
        m_tf_Leg.resignFirstResponder()
        
    }
    
    
    // Move view to always show the selected textfield
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
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
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
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
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
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
        var getDecimalNumbers = (textField.text! as NSString).components(separatedBy: ".")
        
        
        if getDecimalNumbers.count > 1 && (getDecimalNumbers[1] as NSString).length > 1 && string != ""  {
            return false
        }
        let text = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let disallowedCharacterSet = CharacterSet(charactersIn: "0123456789.").inverted
        let replacementStringIsLegal = string.rangeOfCharacter(from: disallowedCharacterSet) == nil
        let resultingStringLengthIsLegal =  (getDecimalNumbers.count > 1 || string == ".") ? text.characters.count <= 6 : text.characters.count <= 3
        let scanner = Scanner(string: text)
        let resultingTextIsNumeric = scanner.scanDecimal(nil) && scanner.isAtEnd
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
        
        if iAd.isBannerLoaded{
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
    
    // Show correct background after rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if UserDefaults.standard.object(forKey: "tutorialBodyMeasurements") == nil {
            hideTutorial()
        }
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
    }
    
}
