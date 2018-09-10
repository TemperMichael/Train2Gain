//
//  TrainingDataVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 09.04.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import CoreData
import LocalAuthentication
import Fabric
import Crashlytics

class TrainingDataVC: UIViewController {
    
    var appDelegate: AppDelegate?
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
    let cellIdentifier = "TrainingDataCell"
    var dayIDs: [String] = []
    var dayHasContent = false
    var doneExercises: [DoneExercise] = []
    var lengthUnit: String?
    var measurements: [Measurements] = []
    var moods: [Mood] = []
    let requestedDoneExercises = NSFetchRequest<NSFetchRequestResult>(entityName: "DoneExercise")
    var selectedDayDetails: [String] = []
    var selectedDoneExercises: [DoneExercise] = []
    var weightUnit: String?
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datePickerButton: UIButton!
    @IBOutlet weak var datePickerBackgroundView: UIView!
    @IBOutlet weak var datePickerTitleLabel: UILabel!
    @IBOutlet weak var nextDateButton: UIButton!
    @IBOutlet weak var previousDateButton: UIButton!
    @IBOutlet weak var selectDateButton: UIButton!
    @IBOutlet weak var trainingDataArmLabel: UILabel!
    @IBOutlet weak var trainingDataChestLabel: UILabel!
    @IBOutlet weak var trainingDataDateLabel: UILabel!
    @IBOutlet weak var trainingDataDayIDTableView: UITableView!
    @IBOutlet weak var trainingDataLegLabel: UILabel!
    @IBOutlet weak var trainingDataMoodImageView: UIImageView!
    @IBOutlet weak var trainingDataMoodNameLabel: UILabel!
    @IBOutlet weak var trainingDataWaistLabel: UILabel!
    @IBOutlet weak var trainingDataWeightLabel: UILabel!
    
    
    @IBAction func pickDateClicked(_ sender: AnyObject) {
        PickerViewHelper.setupPickerViewBackground(blurView, datePickerBackgroundView)
        PickerViewHelper.bringPickerToFront(datePickerBackgroundView, datePicker, selectDateButton, datePickerTitleLabel)
    }
    
    @IBAction func selectDate(_ sender: AnyObject) {
        _ = DateFormatHelper.setDate(datePicker.date, datePickerButton)
        PickerViewHelper.hidePickerView(datePickerBackgroundView)
        viewDidAppear(true)
    }
    
    @IBAction func showNextDay(_ sender: AnyObject) {
        guard let unwrappedDate = UserDefaults.standard.object(forKey: "dateUF") as? Date else {
            return
        }
        _ = DateFormatHelper.setDate(unwrappedDate.addingTimeInterval(60 * 60 * 24), datePickerButton)
        viewDidAppear(true)
    }
    
    @IBAction func showPreviousDay(_ sender: AnyObject) {
        guard let unwrappedDate = UserDefaults.standard.object(forKey: "dateUF") as? Date else {
            return
        }
        _ = DateFormatHelper.setDate(unwrappedDate.addingTimeInterval(-60 * 60 * 24), datePickerButton)
        viewDidAppear(true)
    }
    
    // MARK: View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            guard let unwrappedLengthUnit = UserDefaults.standard.object(forKey: "lengthUnit") as? String, let unwrappedWeightUnit = UserDefaults.standard.object(forKey: "weightUnit") as? String, let unwrappedAppDelegate = UIApplication.shared.delegate as? AppDelegate, let unwrappedManagedObjectContext = unwrappedAppDelegate.managedObjectContext, let unwrappedDoneExercises = try unwrappedManagedObjectContext.fetch(requestedDoneExercises)  as? [DoneExercise], let unwrappedDate = UserDefaults.standard.object(forKey: "dateUF") as? Date else {
                return
            }
            
            lengthUnit = unwrappedLengthUnit
            weightUnit = unwrappedWeightUnit
            appDelegate = unwrappedAppDelegate
            
            selectedDoneExercises = []
            
            datePickerButton.titleLabel?.text = DateFormatHelper.returnDateForm(unwrappedDate)
            trainingDataDayIDTableView.dataSource = self
            trainingDataDayIDTableView.delegate = self
            
            //Fabric - Analytic tool
            Answers.logContentView(withName: "Watched Training data",
                                   contentType: "Saved data",
                                   contentId: "Training data",
                                   customAttributes: [:])
            doneExercises = unwrappedDoneExercises
            
            PickerViewHelper.setupPickerView(datePicker, datePickerTitleLabel)
        } catch {
            print(error)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //Reset lists
        selectedDayDetails = []
        dayIDs = []
        selectedDoneExercises = []
        dayHasContent = false
        
        guard let unwrappedLengthUnit = UserDefaults.standard.object(forKey: "lengthUnit") as? String, let unwrappedWeightUnit = UserDefaults.standard.object(forKey: "weightUnit") as? String, let unwrappedAppDelegate = UIApplication.shared.delegate as? AppDelegate, let unwrappedDate = UserDefaults.standard.object(forKey: "dateUF") as? Date else {
            return
        }
        
        lengthUnit = unwrappedLengthUnit
        weightUnit = unwrappedWeightUnit
        appDelegate = unwrappedAppDelegate
        
        //Show date of chosen day
        datePickerButton.setTitle(DateFormatHelper.returnDateForm(unwrappedDate), for: UIControlState())
        
        loadTrainingData()
        
        getDoneTrainingPlans()
        
        setupMeasurementData()
        
        setupMoodData()
        
        trainingDataDateLabel.text = DateFormatHelper.returnDateForm(unwrappedDate)
        
        trainingDataDayIDTableView.reloadData()
        
        if !dayHasContent {
            trainingDataDateLabel.text = NSLocalizedString("No entry at this date", comment: "No entry at this date")
        }
        trainingDataDayIDTableView.separatorColor = UIColor(red: 37 / 255, green: 190 / 255, blue: 254 / 255, alpha: 1)
    }
    
    // MARK: Own Methods
    
    func setupDeleteAction(_ indexPath: IndexPath, _ tableView: UITableView) -> UITableViewRowAction {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: NSLocalizedString("Delete", comment: "Delete")) { (action, index) -> Void in
            guard let unwrappedAppDelegate = self.appDelegate, let unwrappedManageObjectContext = unwrappedAppDelegate.managedObjectContext, let unwrappedDate = UserDefaults.standard.object(forKey: "dateUF") as? Date else {
                return
            }
            let context = unwrappedManageObjectContext
            var count = self.doneExercises.count - 1
            for _ in 0..<self.doneExercises.count {
                if self.doneExercises[count].dayID == self.dayIDs[(indexPath as NSIndexPath).row] && DateFormatHelper.returnDateForm(self.doneExercises[count].date as Date) == DateFormatHelper.returnDateForm(unwrappedDate) {
                    context.delete(self.doneExercises[count] as NSManagedObject)
                    self.doneExercises.remove(at: count)
                }
                count = count - 1
            }
            self.dayIDs.remove(at: (indexPath as NSIndexPath).row)
            do {
                try context.save()
            } catch _ {
                print("Error delete action training data")
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        deleteAction.backgroundColor = UIColor(red: 86 / 255 , green: 158 / 255, blue: 197 / 255 , alpha: 1)
        return deleteAction
    }
    
    func setupEditAction(_ indexPath: IndexPath) -> UITableViewRowAction {
        guard let unwrappedDate = UserDefaults.standard.object(forKey: "dateUF") as? Date else {
            return UITableViewRowAction()
        }
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: NSLocalizedString("Edit", comment: "Edit")) { (action, index) -> Void in
            for i in 0  ..< self.doneExercises.count {
                if self.doneExercises[i].dayID == self.dayIDs[(indexPath as NSIndexPath).row] && DateFormatHelper.returnDateForm(self.doneExercises[i].date as Date) == DateFormatHelper.returnDateForm(unwrappedDate) {
                    self.selectedDoneExercises.append(self.doneExercises[i])
                }
            }
            self.performSegue(withIdentifier: "editSegue", sender: nil)
        }
        editAction.backgroundColor = UIColor(red: 112 / 255, green: 188 / 255, blue: 224 / 255 , alpha: 1)
        return editAction
    }
    
    func setupCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        // Set Seperator left to zero
        cell.separatorInset = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsets.zero
        cell.textLabel?.text = dayIDs[(indexPath as NSIndexPath).row]
        cell.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 18)
        cell.textLabel?.textColor = UIColor(red: 37 / 255, green: 190 / 255, blue: 254 / 255, alpha: 1)
        cell.textLabel?.textAlignment = .center
        cell.backgroundColor = UIColor.white
        return cell
    }
    
    func getDoneTrainingPlans() {
        var checkString = ""
        var checkBefore = ""
        var dayIDExists = true
        
        guard let unwrappedDate = UserDefaults.standard.object(forKey: "dateUF") as? Date else {
            return
        }
        
        for checkIDAmount in doneExercises {
            if DateFormatHelper.returnDateForm(checkIDAmount.date as Date) == DateFormatHelper.returnDateForm(unwrappedDate) {
                dayHasContent = true
                checkBefore=checkString
                checkString = checkIDAmount.dayID
                if checkString != checkBefore {
                    for checkIds in dayIDs{
                        if checkIds == checkIDAmount.dayID {
                            dayIDExists = false
                        }
                    }
                    
                    if dayIDExists {
                        dayIDs.append(checkIDAmount.dayID)
                    }
                }
                trainingDataDateLabel.text = DateFormatHelper.returnDateForm(checkIDAmount.date as Date)
            }
        }
    }
    
    func loadTrainingData() {
        let requestDoneExercises = NSFetchRequest<NSFetchRequestResult>(entityName: "DoneExercise")
        let requestMeasurements = NSFetchRequest<NSFetchRequestResult>(entityName: "Measurements")
        let requestMood = NSFetchRequest<NSFetchRequestResult>(entityName: "Mood")
        
        do {
            guard let unwrappedAppDelegate = appDelegate, let unwrappedManagedObjectContext = unwrappedAppDelegate.managedObjectContext, let unwrappedDoneExercises = try unwrappedManagedObjectContext.fetch(requestDoneExercises) as? [DoneExercise], let unwrappedMeasurements = try unwrappedManagedObjectContext.fetch(requestMeasurements) as? [Measurements], let unwrappedMoods = try unwrappedManagedObjectContext.fetch(requestMood) as? [Mood]  else {
                return
            }
            
            doneExercises = unwrappedDoneExercises
            measurements = unwrappedMeasurements
            moods = unwrappedMoods
        } catch {
            print(error)
        }
    }
    
    func setupMeasurementData() {
        //Default text
        let translationWeight = NSLocalizedString("Weight", comment: "Weight")
        let translationArms = NSLocalizedString("Arms", comment: "Arms")
        let translationChest = NSLocalizedString("Chest", comment: "Chest")
        let translationWaist = NSLocalizedString("Waist", comment: "Waist")
        let translationLegs = NSLocalizedString("Legs", comment: "Legs")
        
        trainingDataWeightLabel.text = "\(translationWeight): ---"
        trainingDataArmLabel.text = "\(translationArms): ---"
        trainingDataChestLabel.text = "\(translationChest): ---"
        trainingDataWaistLabel.text = "\(translationWaist): ---"
        trainingDataLegLabel.text = "\(translationLegs): ---"
        
        guard let unwrappedDate = UserDefaults.standard.object(forKey: "dateUF") as? Date, let unwrappedWeightUnit = weightUnit, let unwrappedLengthUnit = lengthUnit else {
            return
        }
        
        //Show data in right unit
        for checkMeasureExists in measurements {
            if DateFormatHelper.returnDateForm(checkMeasureExists.date as Date) ==  DateFormatHelper.returnDateForm(unwrappedDate) {
                var weight = (checkMeasureExists.weight).doubleValue
                if weightUnit == "lbs" {
                    weight = weight * 2.20462262185
                }
                dayHasContent = true
                trainingDataWeightLabel.text = NSString(format:"\(translationWeight): %.2f \(unwrappedWeightUnit)" as NSString, weight) as String
                
                var length = (checkMeasureExists.arm).doubleValue
                if lengthUnit == "inch" {
                    length = length / 2.54
                }
                trainingDataArmLabel.text =  NSString(format:"\(translationArms): %.2f \(unwrappedLengthUnit)" as NSString, length) as String
                
                length = (checkMeasureExists.chest).doubleValue
                if lengthUnit == "inch" {
                    length = length / 2.54
                }
                trainingDataChestLabel.text =  NSString(format:"\(translationChest): %.2f \(unwrappedLengthUnit)" as NSString, length) as String
                
                length = (checkMeasureExists.waist).doubleValue
                if lengthUnit == "inch" {
                    length = length / 2.54
                }
                trainingDataWaistLabel.text =  NSString(format:"\(translationWaist): %.2f \(unwrappedLengthUnit)" as NSString, length) as String
                
                length = (checkMeasureExists.leg).doubleValue
                if lengthUnit == "inch" {
                    length = length / 2.54
                }
                trainingDataLegLabel.text =  NSString(format:"\(translationLegs): %.2f \(unwrappedLengthUnit)" as NSString, length) as String
            }
            
        }
    }
    
    func setupMoodData() {
        trainingDataMoodNameLabel.text = "---"
        trainingDataMoodImageView.image = UIImage(named: "SmileyNormal.png")
        trainingDataMoodImageView.tintColor = UIColor(red: 37 / 255, green: 190 / 255, blue: 254 / 255, alpha: 1)
        guard let unwrappedDate = UserDefaults.standard.object(forKey: "dateUF") as? Date else {
            return
        }
        
        for checkMoodExists in moods {
            if DateFormatHelper.returnDateForm(checkMoodExists.date as Date) ==  DateFormatHelper.returnDateForm(unwrappedDate) {
                dayHasContent = true
                trainingDataMoodNameLabel.text = checkMoodExists.moodName
                trainingDataMoodImageView.image = UIImage(named: checkMoodExists.moodImagePath)
            } 
        }
    }
    
}

// MARK: TableView

extension TrainingDataVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dayIDs.count
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        selectedDayDetails.append(dayIDs[(indexPath as NSIndexPath).row])
        selectedDayDetails.append(trainingDataDateLabel.text ?? "")
        return indexPath
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Save chosen exercise day
        if segue.identifier == "DayIDChosen" {
            guard let dayIDChosenTableViewController = segue.destination as? TrainingDataDetailTVC else {
                return
            }
            dayIDChosenTableViewController.selectedDayDetails = selectedDayDetails
        }
        if segue.identifier == "editSegue" {
            guard let editDayIDViewController = segue.destination as? EditTrainingDataDetailVC else {
                return
            }
            editDayIDViewController.selectedExercise = selectedDoneExercises
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        //Handle swipe to single tableview row
        //Handle the deletion of an row
        let deleteAction = setupDeleteAction(indexPath, tableView)
        
        // Handle the changings of the selected row item
        let editAction = setupEditAction(indexPath)
        return [deleteAction, editAction]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return setupCell(tableView, indexPath)
    }
    
}

