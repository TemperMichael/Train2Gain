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

class TrainingDataVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
    var dayIDs: [String] = []
    var doneExercises: [DoneExercise] = []
    var lengthUnit = UserDefaults.standard.object(forKey: "lengthUnit")! as! String
    var measurements: [Measurements] = []
    var moods: [Mood] = []
    let requestedDoneExercises = NSFetchRequest<NSFetchRequestResult>(entityName: "DoneExercise")
    var selectedDayDetails: [String] = []
    var selectedDoneExercises: [DoneExercise] = []
    var weightUnit = UserDefaults.standard.object(forKey: "weightUnit")! as! String

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
        setupPickerView()
    }
    
    @IBAction func selectDate(_ sender: AnyObject) {
        let date = datePicker.date
        UserDefaults.standard.set(datePicker.date,forKey: "dateUF")
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.datePickerBackgroundView.alpha = 0
        }, completion: { finished in
            self.datePickerBackgroundView.isHidden = true
        })
        datePickerButton.setTitle(returnDateForm(date), for: UIControlState())
        
        viewDidAppear(true)
    }
    
    @IBAction func showNextDay(_ sender: AnyObject) {
        var date: Date = UserDefaults.standard.object(forKey: "dateUF") as! Date
        date = date.addingTimeInterval(60 * 60 * 24)
        UserDefaults.standard.set(date, forKey: "dateUF")
        viewDidAppear(true)
    }
    
    @IBAction func showPreviousDay(_ sender: AnyObject) {
        var date: Date = UserDefaults.standard.object(forKey: "dateUF") as! Date
        date = date.addingTimeInterval(-60 * 60 * 24)
        UserDefaults.standard.set(date, forKey: "dateUF")
        viewDidAppear(true)
    }
    
    // MARK: View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set background
        var backgroundImage = UIImage(named: "Background2.png")
        backgroundImage = imageResize(backgroundImage!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundImage!)
        
        // Hide empty cells
        let backgroundView = UIView(frame: CGRect.zero)
        self.trainingDataDayIDTableView.tableFooterView = backgroundView
        self.trainingDataDayIDTableView.backgroundColor = UIColor(red: 86 / 255, green: 158 / 255, blue: 197 / 255, alpha: 0)
        selectedDoneExercises = []
        
        // Remove text from back button
        let backButton = UIBarButtonItem(title: " ", style: UIBarButtonItemStyle.plain, target: self, action: nil)
        backButton.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "Chalkduster", size: 20)!], for: UIControlState())
        navigationItem.backBarButtonItem = backButton
        datePickerButton.titleLabel?.text = returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date)
        trainingDataDayIDTableView.dataSource = self
        trainingDataDayIDTableView.delegate = self
        
        //Fabric - Analytic tool
        Answers.logContentView(withName: "Watched Training data",
            contentType: "Saved data",
            contentId: "Training data",
            customAttributes: [:])
        doneExercises = (try! appDelegate.managedObjectContext?.fetch(requestedDoneExercises))  as! [DoneExercise]
        
        datePicker.setDate(UserDefaults.standard.object(forKey: "dateUF") as! Date, animated: true)
        datePicker.forBaselineLayout().setValue(UIColor.white, forKeyPath: "tintColor")
        for sub in datePicker.subviews {
            sub.setValue(UIColor.white, forKeyPath: "textColor")
            sub.setValue(UIColor.white, forKey: "tintColor")
        }
        
        datePickerTitleLabel.text = NSLocalizedString("Choose a date", comment: "Choose a date")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
 
    
    // Show correct background after rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        var backgroundImage = UIImage(named: "Background2.png")
        backgroundImage = imageResize(backgroundImage!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundImage!)
    }
    
    // MARK: Own Methods

    // Fit background image to display size
    func imageResize(_ imageObj: UIImage, sizeChange: CGSize) -> UIImage {
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
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

    // MARK: TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dayIDs.count
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        selectedDayDetails.append(dayIDs[(indexPath as NSIndexPath).row])
        selectedDayDetails.append(trainingDataDateLabel.text!)
        return indexPath
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Save chosen exercise day
        if segue.identifier == "DayIDChosen" {
            let dayIDChosenTableViewController = segue.destination as! TrainingDataDetailTVC
            dayIDChosenTableViewController.selectedDayDetails = selectedDayDetails
        }
        if segue.identifier == "editSegue" {
            let editDayIDViewController = segue.destination as! EditTrainingDataDetailVC
            editDayIDViewController.selectedExercise = selectedDoneExercises
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        // Has to be here so custom action can be used
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        //Handle swipe to single tableview row
        //Handle the deletion of an row
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: NSLocalizedString("Delete", comment: "Delete")) { (action, index) -> Void in
            let context:NSManagedObjectContext = self.appDelegate.managedObjectContext!
            var count = self.doneExercises.count - 1
            for _ in 0..<self.doneExercises.count{
                if self.doneExercises[count].dayID == self.dayIDs[(indexPath as NSIndexPath).row] && self.returnDateForm(self.doneExercises[count].date as Date) == self.returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date) {
                    context.delete(self.doneExercises[count] as NSManagedObject)
                    self.doneExercises.remove(at: count)
                    count = count - 1
                }
            }
            self.dayIDs.remove(at: (indexPath as NSIndexPath).row)
            do {
                try context.save()
            } catch _ {
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        deleteAction.backgroundColor = UIColor(red: 86 / 255 , green: 158 / 255, blue: 197 / 255 , alpha: 1)
        

        // Handle the changings of the selected row item
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: NSLocalizedString("Edit", comment: "Edit")) { (action, index) -> Void in
            for i in 0  ..< self.doneExercises.count {
                if self.doneExercises[i].dayID == self.dayIDs[(indexPath as NSIndexPath).row] && self.returnDateForm(self.doneExercises[i].date as Date) == self.returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date) {
                    self.selectedDoneExercises.append(self.doneExercises[i])
                }
            }
            self.performSegue(withIdentifier: "editSegue", sender: nil)
        }
        editAction.backgroundColor = UIColor(red: 112 / 255, green: 188 / 255, blue: 224 / 255 , alpha: 1)
        return [deleteAction,editAction]
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrainingDataCell", for: indexPath)
        
        // Set Seperator left to zero
        cell.separatorInset = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsets.zero
        cell.textLabel?.text = dayIDs[(indexPath as NSIndexPath).row]
        cell.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 18)
        cell.textLabel?.textColor = UIColor(red: 22 / 255 , green: 204 / 255, blue: 255 / 255, alpha: 1)
        cell.textLabel?.textAlignment = .center
        cell.backgroundColor = UIColor.white
        return cell
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //Reset lists
        selectedDayDetails = []
        dayIDs = []
        selectedDoneExercises = []
        
        var dayHasContent = false
        
        //Show date of chosen day
        datePickerButton.setTitle(returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date), for: UIControlState())
        
        //Hide empty cells
        let backgroundView = UIView(frame: CGRect.zero)
        
        self.trainingDataDayIDTableView.tableFooterView = backgroundView
        
        self.trainingDataDayIDTableView.backgroundColor = UIColor(red: 86 / 255, green: 158 / 255, blue: 197 / 255,alpha: 0)
        
        let requestDoneExercises = NSFetchRequest<NSFetchRequestResult>(entityName: "DoneExercise")
        doneExercises = (try! appDelegate.managedObjectContext?.fetch(requestDoneExercises))  as! [DoneExercise]
        
        let  requestMeasurements = NSFetchRequest<NSFetchRequestResult>(entityName: "Measurements")
        measurements = (try! appDelegate.managedObjectContext?.fetch(requestMeasurements))  as! [Measurements]
        
        let  requestMood = NSFetchRequest<NSFetchRequestResult>(entityName: "Mood")
        moods = (try! appDelegate.managedObjectContext?.fetch(requestMood))  as! [Mood]
        
        var checkString = ""
        var checkBefore = ""
        var dayIDExists = true
        
        //Only get different done trainings plans
        for checkIDAmount in doneExercises {
            if(returnDateForm(checkIDAmount.date as Date) ==  returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date)) {
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
                trainingDataDateLabel.text = returnDateForm(checkIDAmount.date as Date)
            }
        }
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
        
        //Show data in right unit
        for checkMeasureExists in measurements {
            if(returnDateForm(checkMeasureExists.date as Date) ==  returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date)) {
                var weight = (checkMeasureExists.weight).doubleValue
                if weightUnit == "lbs" {
                    weight = weight * 2.20462262185
                }
                dayHasContent = true
                trainingDataWeightLabel.text = NSString(format:"\(translationWeight): %.2f \(weightUnit)" as NSString, weight) as String
                
                var length = (checkMeasureExists.arm).doubleValue
                if lengthUnit == "inch" {
                    length = length / 2.54
                }
                trainingDataArmLabel.text =  NSString(format:"\(translationArms): %.2f \(lengthUnit)" as NSString, length) as String
                
                length = (checkMeasureExists.chest).doubleValue
                if lengthUnit == "inch" {
                    length = length / 2.54
                }
                trainingDataChestLabel.text =  NSString(format:"\(translationChest): %.2f \(lengthUnit)" as NSString, length) as String
                
                
                length = (checkMeasureExists.waist).doubleValue
                if lengthUnit == "inch" {
                    length = length / 2.54
                }
                trainingDataWaistLabel.text =  NSString(format:"\(translationWaist): %.2f \(lengthUnit)" as NSString, length) as String
                
                length = (checkMeasureExists.leg).doubleValue
                if lengthUnit == "inch" {
                    length = length / 2.54
                }
                trainingDataLegLabel.text =  NSString(format:"\(translationLegs): %.2f \(lengthUnit)" as NSString, length) as String
            }
            
        }
        
        //Default text/mood
        trainingDataMoodNameLabel.text = "---"
        trainingDataMoodImageView.image = UIImage(named: "SmileyNormal.png")
        
        for checkMoodExists in moods{
            
            if(returnDateForm(checkMoodExists.date as Date) ==  returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date)){
                dayHasContent = true
                trainingDataMoodNameLabel.text = checkMoodExists.moodName
                trainingDataMoodImageView.image = UIImage(named: checkMoodExists.moodImagePath)
            }
            
        }
        
        trainingDataDateLabel.text = returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date)
        
        trainingDataDayIDTableView.reloadData()
        
        if !dayHasContent {
            trainingDataDateLabel.text = NSLocalizedString("No entry at this date", comment: "No entry at this date")
        }
        trainingDataDayIDTableView.separatorColor = UIColor(red: 22 / 255, green: 204 / 255, blue: 255 / 255,alpha: 1)
    }
    
}

