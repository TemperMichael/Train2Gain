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

class BodyMeasurementsVC: UIViewController, UITextFieldDelegate, ADBannerViewDelegate {
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
    var date: Date!
    var dates: [Dates] = []
    var editMode = false
    var lengthUnit = UserDefaults.standard.object(forKey: "lengthUnit")! as! String
    var measurements: [Measurements] = []
    let requestedMeasurements = NSFetchRequest<Measurements>(entityName: "Measurements")
    var weightUnit = UserDefaults.standard.object(forKey: "weightUnit")! as! String
    
    // MARK: IBOutles & IBActions
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datePickerBackgroundView: UIView!
    @IBOutlet weak var datePickerButton: UIButton!
    @IBOutlet weak var datePickerTitleLabel: UILabel!
    @IBOutlet weak var iAd: ADBannerView!
    @IBOutlet weak var measurementsArmTextField: UITextField!
    @IBOutlet weak var measurementsChestTextField: UITextField!
    @IBOutlet weak var measurementsLegTextField: UITextField!
    @IBOutlet var measurementsLengthUnitLabels: [UILabel]!
    @IBOutlet weak var measurementsWaistTextField: UITextField!
    @IBOutlet weak var measurementsWeightTextField: UITextField!
    @IBOutlet weak var measurementWeightUnitLabel: UILabel!
    @IBOutlet weak var selectDateButton: UIButton!
    
    @IBAction func saveMeasurements(_ sender: AnyObject) {
        
        var alreadyExists = true
        let  request = NSFetchRequest<NSFetchRequestResult>(entityName: "Dates")
        dates = (try! appDelegate.managedObjectContext?.fetch(request))  as! [Dates]
        
        measurements = (try! appDelegate.managedObjectContext?.fetch(requestedMeasurements))!
        date = UserDefaults.standard.object(forKey: "dateUF") as! Date
        
        
        // Check if data already exists
        for i in 0 ..< dates.count {
            if(returnDateForm(dates[i].savedDate as Date) == returnDateForm(date)){
                alreadyExists = false
            }
        }
        
        //Replace date
        if alreadyExists {
            let newItem = NSEntityDescription.insertNewObject(forEntityName: "Dates", into: appDelegate.managedObjectContext!) as! Dates
            newItem.savedDate = Date()
        }
        
        // Save data in correct way
        if !editMode {
            if measurements.count <= 0 {
                addNewMeasure()
            } else {
                let lastMeasure = measurements[measurements.count-1]
                if returnDateForm(lastMeasure.date as Date) != returnDateForm(Date()) {
                    addNewMeasure()
                } else {
                    addMeasure(lastMeasure)
                }
            }
        } else {
            var measurementExists = false
            if !alreadyExists {
                for singleMeasure in measurements {
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
        
        appDelegate.saveContext()
        
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
    
    @IBAction func showPreviousDay(_ sender: AnyObject) {
        date = date.addingTimeInterval(-60 * 60 * 24)
        UserDefaults.standard.set(date, forKey: "dateUF")
        datePickerButton.setTitle(returnDateForm(date), for: UIControlState())
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
        
        date = UserDefaults.standard.object(forKey: "dateUF") as! Date
        measurementsWeightTextField.delegate = self
        measurementsChestTextField.delegate = self
        measurementsArmTextField.delegate = self
        measurementsWaistTextField.delegate = self
        measurementsLegTextField.delegate = self
        
        // Setup content of view
        if editMode {
            measurements = (try! appDelegate.managedObjectContext?.fetch(requestedMeasurements))!
            for singleMeasure in measurements {
                if returnDateForm(singleMeasure.date as Date) == returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date) {
                    measurementsWeightTextField.text = getCorrectString(singleMeasure.weight.doubleValue,id: 0)
                    measurementsArmTextField.text = getCorrectString(singleMeasure.arm.doubleValue,id: 1)
                    measurementsLegTextField.text = getCorrectString(singleMeasure.leg.doubleValue,id: 1)
                    measurementsChestTextField.text = getCorrectString(singleMeasure.chest.doubleValue,id: 1)
                    measurementsWaistTextField.text = getCorrectString(singleMeasure.waist.doubleValue,id: 1)
                }
            }
        }
        for singleLabel in measurementsLengthUnitLabels {
            singleLabel.text = lengthUnit
        }
        measurementWeightUnitLabel.text = weightUnit
        datePickerButton.setTitle(returnDateForm(date), for: UIControlState())
        
        datePicker.setDate(UserDefaults.standard.object(forKey: "dateUF") as! Date, animated: true)
        datePicker.forBaselineLayout().setValue(UIColor.white, forKeyPath: "tintColor")
        for subview in datePicker.subviews {
            subview.setValue(UIColor.white, forKeyPath: "textColor")
            subview.setValue(UIColor.white, forKey: "tintColor")
        }
        
        datePickerTitleLabel.text = NSLocalizedString("Choose a date", comment: "Choose a date")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        date = UserDefaults.standard.object(forKey: "dateUF") as! Date
        datePickerButton.setTitle(returnDateForm(date), for: UIControlState())
    }
    
    // MARK: Own Methods
    
    func getCorrectString(_ amount: Double, id: Int) -> String{
        var amount = amount
        
        //Show as lbs
        if id == 0 && weightUnit == "lbs" {
            amount = amount *  2.20462262185
        }
        
        if id == 1 && lengthUnit == "inch" {
            amount = amount / 2.54
        }
        var returnString = NSString(format:"%.2f", amount) as String
        
        if amount == 0 {
            returnString = "0"
        }
        return returnString
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
        let newItem = NSEntityDescription.insertNewObject(forEntityName: "Measurements", into: appDelegate.managedObjectContext!) as! Measurements
        addMeasure(newItem)
    }
    
    func addMeasure(_ _Object: Measurements) {
        // TODO Werte  nicht formatiert gespeichert
        var value : Double!
        _Object.date = date
        value = (measurementsWeightTextField.text! as NSString).doubleValue
        if weightUnit == "lbs" {
            value = value / 2.20462262185
        }
        _Object.weight = NSDecimalNumber(string: !measurementsWeightTextField.text!.isEmpty ? "\(value)" : "0")
        value = (measurementsArmTextField.text! as NSString).doubleValue
        if lengthUnit == "inch" {
            value = value * 2.54
        }
        _Object.arm = NSDecimalNumber(string: !measurementsArmTextField.text!.isEmpty ? "\(value)" : "0")
        value = (measurementsChestTextField.text! as NSString).doubleValue
        if lengthUnit == "inch" {
            value = value * 2.54
        }
        _Object.chest = NSDecimalNumber(string: !measurementsChestTextField.text!.isEmpty ? "\(value)" : "0")
        value = (measurementsWaistTextField.text! as NSString).doubleValue
        if lengthUnit == "inch" {
            value = value * 2.54
        }
        _Object.waist = NSDecimalNumber(string: !measurementsWaistTextField.text!.isEmpty ? "\(value)" : "0")
        value = (measurementsLegTextField.text! as NSString).doubleValue
        if lengthUnit == "inch" {
            value = value * 2.54
        }
        _Object.leg = NSDecimalNumber(string: !measurementsLegTextField.text!.isEmpty ? "\(value)" : "0")
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
    
    // MARK: Textfield Methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Close Keyboard when clicking outside
        measurementsWeightTextField.resignFirstResponder()
        measurementsChestTextField.resignFirstResponder()
        measurementsArmTextField.resignFirstResponder()
        measurementsWaistTextField.resignFirstResponder()
        measurementsLegTextField.resignFirstResponder()
    }
    
    
    // Move view to always show the selected textfield
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case measurementsArmTextField:
            self.view.frame.origin.y -= 80
        case measurementsWaistTextField:
            self.view.frame.origin.y -= 150
        case measurementsLegTextField:
            self.view.frame.origin.y -= 150
        default :
            print("Error textfield")
        }
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case measurementsArmTextField:
            self.view.frame.origin.y += 80
        case measurementsWaistTextField:
            self.view.frame.origin.y += 150
        case measurementsLegTextField:
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
            case measurementsWeightTextField:
                measurementsChestTextField.becomeFirstResponder()
            case measurementsChestTextField:
                measurementsArmTextField.becomeFirstResponder()
            case measurementsArmTextField:
                measurementsWaistTextField.becomeFirstResponder()
            case measurementsWaistTextField:
                measurementsLegTextField.becomeFirstResponder()
            case measurementsLegTextField:
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
        let resultingStringLengthIsLegal =  (getDecimalNumbers.count > 1 || string == ".") ? text.count <= 6 : text.count <= 3
        let scanner = Scanner(string: text)
        let resultingTextIsNumeric = scanner.scanDecimal(nil) && scanner.isAtEnd
        if text.count == 0 || (replacementStringIsLegal &&
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
    
    // Show correct background after rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        var backgroundImage = UIImage(named: "Background2.png")
        backgroundImage = imageResize(backgroundImage!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundImage!)
    }
    
}
