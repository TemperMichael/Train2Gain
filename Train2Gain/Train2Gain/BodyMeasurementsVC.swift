//
//  BodyMeasurementsVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 28.03.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import CoreData
import Fabric
import Crashlytics

class BodyMeasurementsVC: UIViewController {
    
    var appDelegate: AppDelegate?
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
    var date: Date?
    var editMode = false
    var lengthUnit: String?
    var measurements: [Measurements] = []
    let requestedMeasurements = NSFetchRequest<Measurements>(entityName: "Measurements")
    var weightUnit: String?
    
    // MARK: IBOutles & IBActions
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datePickerBackgroundView: UIView!
    @IBOutlet weak var datePickerButton: UIButton!
    @IBOutlet weak var datePickerTitleLabel: UILabel!
    @IBOutlet weak var measurementsArmTextField: UITextField!
    @IBOutlet weak var measurementsChestTextField: UITextField!
    @IBOutlet weak var measurementsLegTextField: UITextField!
    @IBOutlet var measurementsLengthUnitLabels: [UILabel]!
    @IBOutlet weak var measurementsWaistTextField: UITextField!
    @IBOutlet weak var measurementsWeightTextField: UITextField!
    @IBOutlet weak var measurementWeightUnitLabel: UILabel!
    @IBOutlet weak var selectDateButton: UIButton!
    
    @IBAction func saveMeasurements(_ sender: AnyObject) {
        do {
            guard let unwrappedAppDelegate = UIApplication.shared.delegate as? AppDelegate, let unwrappedManagedObjectContext = unwrappedAppDelegate.managedObjectContext, let unwrappedDate =  UserDefaults.standard.object(forKey: "dateUF") as? Date else {
                return
            }
            
            measurements = try unwrappedManagedObjectContext.fetch(requestedMeasurements)
            date = unwrappedDate
            
            saveMeasurementsCorrectly()
            
            unwrappedAppDelegate.saveContext()
            
            // Fabric - Analytic tool
            Answers.logContentView(withName: "Body Measurement",
                                   contentType: "Saved data",
                                   contentId: String(stringInterpolationSegment: editMode),
                                   customAttributes: [:])
            
            AlertFormatHelper.showInfoAlert(self, "Your body measurements were saved.")
        } catch {
            print(error)
        }
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
    
    @IBAction func showPreviousDay(_ sender: AnyObject) {
        guard let unwrappedDate = date else {
            return
        }
        date = DateFormatHelper.setDate(unwrappedDate.addingTimeInterval(-60 * 60 * 24), datePickerButton)
    }
    
    // MARK: View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        measurementsWeightTextField.delegate = self
        measurementsChestTextField.delegate = self
        measurementsArmTextField.delegate = self
        measurementsWaistTextField.delegate = self
        measurementsLegTextField.delegate = self
        
        // Setup content of view
        if editMode {
            loadSavedMeasurements()
        }
        
        for singleLabel in measurementsLengthUnitLabels {
            singleLabel.text = lengthUnit
        }
        measurementWeightUnitLabel.text = weightUnit
        
        PickerViewHelper.setupPickerView(datePicker, datePickerTitleLabel)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupView()
    }
    
    // MARK: Own Methods
    
    func setupView() {
        guard let unwrappedLengthUnit = UserDefaults.standard.object(forKey: "lengthUnit") as? String, let unwrappedWeightUnit = UserDefaults.standard.object(forKey: "weightUnit") as? String, let unwrappedDate = UserDefaults.standard.object(forKey: "dateUF") as? Date, let unwrappedAppDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        lengthUnit = unwrappedLengthUnit
        weightUnit = unwrappedWeightUnit
        appDelegate = unwrappedAppDelegate
        
        datePickerButton.setTitle(DateFormatHelper.returnDateForm(unwrappedDate), for: UIControlState())
        date = unwrappedDate
    }
    
    func getCorrectString(_ measurementValue: Double, id: Int) -> String{
        var value = measurementValue
        
        //Show as lbs
        if id == 0 && weightUnit == "lbs" {
            value = value *  2.20462262185
        }
        
        if id == 1 && lengthUnit == "inch" {
            value = value / 2.54
        }
        var returnString = NSString(format:"%.2f", value) as String
        
        if value == 0 {
            returnString = "0"
        }
        return returnString
    }
    
    // Add measures in right units
    func addNewMeasure() {
        guard let unwrappedAppDelegate = appDelegate, let unwrappedManagedObjectContext = unwrappedAppDelegate.managedObjectContext, let newItem = NSEntityDescription.insertNewObject(forEntityName: "Measurements", into: unwrappedManagedObjectContext) as? Measurements else {
            return
        }
        addMeasure(newItem)
    }
    
    func addMeasure(_ _Object: Measurements) {
        // TODO Werte  nicht formatiert gespeichert
        guard let unwrappedDate = UserDefaults.standard.object(forKey: "dateUF") as? Date else {
            return
        }
        _Object.date = unwrappedDate
        
        
        guard let weightValue = measurementsWeightTextField.text, let armValue = measurementsArmTextField.text, let chestValue = measurementsChestTextField.text, let waistValue = measurementsWaistTextField.text, let legValue = measurementsLegTextField.text else {
            return
        }
        
        print(NSDecimalNumber(string: weightValue.isEmpty ? "0" : weightValue))
        _Object.weight = NSDecimalNumber(string: weightValue.isEmpty ? "0" : weightValue)
        _Object.arm = NSDecimalNumber(string: armValue.isEmpty ? "0" : armValue)
        _Object.chest = NSDecimalNumber(string: chestValue.isEmpty ? "0" : chestValue)
        _Object.waist = NSDecimalNumber(string: waistValue.isEmpty ? "0" : waistValue)
        _Object.leg = NSDecimalNumber(string: legValue.isEmpty ? "0" : legValue)
        
        
        if weightUnit == "lbs" {
            _Object.weight.dividing(by: NSDecimalNumber(value: 2.20462262185))
        }
        
        if lengthUnit == "inch" {
            _Object.arm = _Object.arm.multiplying(by: NSDecimalNumber(value: 2.54))
            _Object.chest = _Object.chest.multiplying(by: NSDecimalNumber(value: 2.54))
            _Object.waist = _Object.waist.multiplying(by: NSDecimalNumber(value: 2.54))
            _Object.leg = _Object.leg.multiplying(by: NSDecimalNumber(value: 2.54))
        }
    }
    
    func handleReturnButtonClick(_ textField: UITextField) {
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
    
    func detectValidInput(_ textField: UITextField, _ string: String, _ range: NSRange) -> Bool {
        var getDecimalNumbers = (textField.text ?? "").components(separatedBy: ".")
        
        if getDecimalNumbers.count > 1 && (getDecimalNumbers[1] as NSString).length > 1 && string != ""  {
            return false
        }
        let text = (textField.text as NSString? ?? "").replacingCharacters(in: range, with: string)
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
    
    func loadSavedMeasurements() {
        do {
            guard let unwrappedAppDelegate = appDelegate, let unwrappedManagedObjectContext = unwrappedAppDelegate.managedObjectContext, let unwrappedDate = UserDefaults.standard.object(forKey: "dateUF") as? Date else {
                return
            }
            measurements = try unwrappedManagedObjectContext.fetch(requestedMeasurements)
            for singleMeasure in measurements {
                if DateFormatHelper.returnDateForm(singleMeasure.date as Date) == DateFormatHelper.returnDateForm(unwrappedDate) {
                    measurementsWeightTextField.text = getCorrectString(singleMeasure.weight.doubleValue,id: 0)
                    measurementsArmTextField.text = getCorrectString(singleMeasure.arm.doubleValue,id: 1)
                    measurementsLegTextField.text = getCorrectString(singleMeasure.leg.doubleValue,id: 1)
                    measurementsChestTextField.text = getCorrectString(singleMeasure.chest.doubleValue,id: 1)
                    measurementsWaistTextField.text = getCorrectString(singleMeasure.waist.doubleValue,id: 1)
                }
            }
        } catch {
            print(error)
        }
    }
    
    func saveMeasurementsCorrectly() {
        if measurements.count <= 0 {
            addNewMeasure()
        } else {
            let lastMeasure = measurements[measurements.count - 1]
            if DateFormatHelper.returnDateForm(lastMeasure.date as Date) != DateFormatHelper.returnDateForm(Date()) {
                addNewMeasure()
            } else {
                addMeasure(lastMeasure)
            }
        }
    }
    
}

// MARK: TextField

extension BodyMeasurementsVC: UITextFieldDelegate {
    
    
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            handleReturnButtonClick(textField)
        }
        return detectValidInput(textField, string, range)
    }
    
}
