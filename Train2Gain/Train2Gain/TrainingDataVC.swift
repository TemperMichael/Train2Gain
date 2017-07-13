//
//  TrainingDataVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 09.04.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit

import UIKit
import CoreData
import LocalAuthentication
import Fabric
import Crashlytics
import iAd

class TrainingDataVC: UIViewController, UITableViewDelegate, UITableViewDataSource, ADBannerViewDelegate {
    
    var dayIDs: [String] = []
    var doneExercises: [DoneExercise] = []
    var measurements: [Measurements] = []
    var moods: [Mood] = []
    var selectedDayDetails: [String] = []
    var selectedDoneExc: [DoneExercise] = []
    var appdel = UIApplication.shared.delegate as! AppDelegate
    var weightUnit = UserDefaults.standard.object(forKey: "weightUnit")! as! String
    var lengthUnit = UserDefaults.standard.object(forKey: "lengthUnit")! as! String
    var doneEx: [DoneExercise]!
    var tutorialView: UIImageView!
    var showTutorial2 = true
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
    let requestDoneEx = NSFetchRequest<NSFetchRequestResult>(entityName: "DoneExercise")
    
    @IBOutlet weak var m_b_prevDate: UIButton!
    @IBOutlet weak var m_b_nextDate: UIButton!
    @IBOutlet weak var m_b_PickDate: UIButton!
    @IBOutlet weak var m_L_Date: UILabel!
    @IBOutlet weak var m_L_Arm: UILabel!
    @IBOutlet weak var m_L_Chest: UILabel!
    @IBOutlet weak var m_L_Waist: UILabel!
    @IBOutlet weak var m_L_Legs: UILabel!
    @IBOutlet weak var m_L_Weight: UILabel!
    @IBOutlet weak var m_tv_DayIds: UITableView!
    @IBOutlet weak var m_L_moodName: UILabel!
    @IBOutlet weak var m_IV_moodImage: UIImageView!
    @IBOutlet weak var iAd: ADBannerView!
    
    @IBOutlet weak var pickerView: UIDatePicker!
    @IBOutlet weak var pickerTitle: UILabel!
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var pickerBG: UIView!
    @IBAction func nextDayCL(_ sender: AnyObject) {
        
        var date: Date = UserDefaults.standard.object(forKey: "dateUF") as! Date
        
        // Go to next day
        date = date.addingTimeInterval(60 * 60 * 24)
        UserDefaults.standard.set(date, forKey: "dateUF")
        viewDidAppear(true)
        
    }
    
    @IBAction func prevDayCL(_ sender: AnyObject) {
        
        var date: Date = UserDefaults.standard.object(forKey: "dateUF") as! Date
        
        // Go to prevoius day
        date = date.addingTimeInterval(-60 * 60 * 24)
        UserDefaults.standard.set(date, forKey: "dateUF")
        viewDidAppear(true)
        
    }
    
    @IBAction func finishCL(_ sender: AnyObject) {
        
        // Save date
        let date = pickerView.date
        UserDefaults.standard.set(pickerView.date,forKey: "dateUF")
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.pickerBG.alpha = 0
            }, completion: { finished in
                self.pickerBG.isHidden = true
        })
        m_b_PickDate.setTitle(returnDateForm(date), for: UIControlState())
        
        viewDidAppear(true)
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
        if UserDefaults.standard.object(forKey: "tutorialTrainingData") == nil {
            tutorialView = UIImageView(frame: self.view.frame)
            tutorialView.image = UIImage(named: "TutorialTrainingData1.png")
            tutorialView.frame.origin.y += 18
            if self.view.frame.size.height <= 490 {
                tutorialView.frame.size.height += 60
            } else {
                tutorialView.frame.size.height -= 60
            }
            tutorialView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action:#selector(TrainingDataVC.hideTutorial))
            tutorialView.addGestureRecognizer(tap)
            self.view.addSubview(tutorialView)
            self.navigationController?.isNavigationBarHidden = true
        }
        
        // Hide empty cells
        let backgroundView = UIView(frame: CGRect.zero)
        self.m_tv_DayIds.tableFooterView = backgroundView
        self.m_tv_DayIds.backgroundColor = UIColor(red: 86 / 255, green: 158 / 255, blue: 197 / 255, alpha: 0)
        selectedDoneExc = []
        
        // Remove text from back button
        let backButton = UIBarButtonItem(title: " ", style: UIBarButtonItemStyle.plain, target: self, action: nil)
        backButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Chalkduster", size: 20)!], for: UIControlState())
        navigationItem.backBarButtonItem = backButton
        m_b_PickDate.titleLabel?.text = returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date)
        m_tv_DayIds.dataSource = self
        m_tv_DayIds.delegate = self
        
        //Fabric - Analytic tool
        Answers.logContentView(withName: "Watched Training data",
            contentType: "Saved data",
            contentId: "Training data",
            customAttributes: [:])
        doneEx = (try! appdel.managedObjectContext!.fetch(requestDoneEx))  as! [DoneExercise]
        
        pickerView.setDate(UserDefaults.standard.object(forKey: "dateUF") as! Date, animated: true)
        pickerView.forBaselineLayout().setValue(UIColor.white, forKeyPath: "tintColor")
        for sub in pickerView.subviews {
            sub.setValue(UIColor.white, forKeyPath: "textColor")
            sub.setValue(UIColor.white, forKey: "tintColor")
        }
        
        pickerTitle.text = NSLocalizedString("Choose a date", comment: "Choose a date")
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        self.navigationController?.setToolbarHidden(true, animated: true)
        
    }
 
    
    // Show correct background after rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if UserDefaults.standard.object(forKey: "tutorialTrainingData") == nil {
            hideTutorial()
            if UserDefaults.standard.object(forKey: "tutorialTrainingData") == nil {
                hideTutorial()
                self.navigationController?.isNavigationBarHidden = false
            }
        }
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
    }
    
    // MARK: My Methods
    func hideTutorial() {
        
        if !showTutorial2 {
            var backgroundIMG = UIImage(named: "Background2.png")
            backgroundIMG = imageResize(backgroundIMG!, sizeChange: view.frame.size)
            self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
            self.navigationController?.isNavigationBarHidden = false
        }
        UIView.transition(with: self.view, duration: 1, options: UIViewAnimationOptions.curveLinear, animations: {
            if self.showTutorial2 {
                self.tutorialView.image = UIImage(named: "TutorialTrainingData2.png")
            } else {
                self.tutorialView.alpha = 0
            }
            }, completion:{ finished in
                if !self.showTutorial2 {
                    UserDefaults.standard.set(false, forKey: "tutorialTrainingData")
                    self.tutorialView.removeFromSuperview()
                }
                self.showTutorial2 = false
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

    // MARK: TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return dayIDs.count
        
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        selectedDayDetails.append(dayIDs[(indexPath as NSIndexPath).row])
        selectedDayDetails.append(m_L_Date.text!)
        return indexPath
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        //Save chosen exercise day
        if segue.identifier == "DayIDChosen" {
            let vc = segue.destination as! DayIDChosenTVC
            vc.selectedDayDetails = selectedDayDetails
        }
        if segue.identifier == "editSegue" {
            let vc = segue.destination as! EditDayIDVC
            vc.selectedExc = selectedDoneExc
        }
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        // Has to stand here so custom action can be used
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        //Handle swipe to single tableview row
        //Handle the deletion of an row
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: NSLocalizedString("Delete", comment: "Delete")) { (action, index) -> Void in
            let context:NSManagedObjectContext = self.appdel.managedObjectContext!
            var count = 0
            for _ in 0..<self.doneEx.count{
                if self.doneEx[count].dayID == self.dayIDs[(indexPath as NSIndexPath).row] && self.returnDateForm(self.doneEx[count].date as Date) == self.returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date) {
                    context.delete(self.doneEx[count] as NSManagedObject)
                    self.doneEx.remove(at: count)
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
            for i in 0  ..< self.doneEx.count {
                if self.doneEx[i].dayID == self.dayIDs[(indexPath as NSIndexPath).row] && self.returnDateForm(self.doneEx[i].date as Date) == self.returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date) {
                    self.selectedDoneExc.append(self.doneEx[i])
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
        cell.textLabel?.textColor = UIColor(red: 22 / 255 , green: 204 / 255, blue: 1.00 , alpha: 1.0)
        cell.textLabel?.textAlignment = .center
        cell.backgroundColor = UIColor.white
        return cell

    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        //Reset lists
        selectedDayDetails = []
        dayIDs = []
        selectedDoneExc = []
        
        var dayHasContent = false
        
        //Show date of chosen day
        m_b_PickDate.setTitle(returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date), for: UIControlState())
        
        //Hide empty cells
        let backgroundView = UIView(frame: CGRect.zero)
        
        self.m_tv_DayIds.tableFooterView = backgroundView
        
        self.m_tv_DayIds.backgroundColor = UIColor(red:86/255 ,green:158/255, blue:197/255 ,alpha:0)
        
        //Get data
        let appdel =  UIApplication.shared.delegate as! AppDelegate
        let  requestDoneEx = NSFetchRequest<NSFetchRequestResult>(entityName: "DoneExercise")
        doneExercises = (try! appdel.managedObjectContext?.fetch(requestDoneEx))  as! [DoneExercise]
        
        let  requestMeasurements = NSFetchRequest<NSFetchRequestResult>(entityName: "Measurements")
        measurements = (try! appdel.managedObjectContext?.fetch(requestMeasurements))  as! [Measurements]
        
        let  requestMood = NSFetchRequest<NSFetchRequestResult>(entityName: "Mood")
        moods = (try! appdel.managedObjectContext?.fetch(requestMood))  as! [Mood]
        
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
                            
                            dayIDExists = false;
                        }
                    }
                    if dayIDExists {
                        dayIDs.append(checkIDAmount.dayID)
                    }
                    
                    
                }
                m_L_Date.text = returnDateForm(checkIDAmount.date as Date)
            }
            
        }
        //Default text
        
        let translationWeight = NSLocalizedString("Weight", comment: "Weight")
        let translationArms = NSLocalizedString("Arms", comment: "Arms")
        let translationChest = NSLocalizedString("Chest", comment: "Chest")
        let translationWaist = NSLocalizedString("Waist", comment: "Waist")
        let translationLegs = NSLocalizedString("Legs", comment: "Legs")
        
        
        m_L_Weight.text = "\(translationWeight): ---"
        m_L_Arm.text = "\(translationArms): ---"
        m_L_Chest.text = "\(translationChest): ---"
        m_L_Waist.text = "\(translationWaist): ---"
        m_L_Legs.text = "\(translationLegs): ---"
        
        //Show data in right unit
        for checkMeasureExists in measurements {
            
            if(returnDateForm(checkMeasureExists.date as Date) ==  returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date)) {
                var weight = (checkMeasureExists.weight).doubleValue
                if weightUnit == "lbs" {
                    weight = weight * 2.20462262185
                }
                
                dayHasContent = true
                m_L_Weight.text = NSString(format:"\(translationWeight): %.2f \(weightUnit)" as NSString,weight ) as String
                
                var length = (checkMeasureExists.arm).doubleValue
                if lengthUnit == "inch" {
                    length = length/2.54
                }
                m_L_Arm.text =  NSString(format:"\(translationArms): %.2f \(lengthUnit)" as NSString,length ) as String
                
                length = (checkMeasureExists.chest).doubleValue
                if lengthUnit == "inch" {
                    length = length/2.54
                }
                m_L_Chest.text =  NSString(format:"\(translationChest): %.2f \(lengthUnit)" as NSString,length ) as String
                
                
                length = (checkMeasureExists.waist).doubleValue
                if lengthUnit == "inch" {
                    length = length/2.54
                }
                m_L_Waist.text =  NSString(format:"\(translationWaist): %.2f \(lengthUnit)" as NSString,length ) as String
                
                length = (checkMeasureExists.leg).doubleValue
                if lengthUnit == "inch" {
                    length = length/2.54
                }
                m_L_Legs.text =  NSString(format:"\(translationLegs): %.2f \(lengthUnit)" as NSString,length ) as String
            }
            
        }
        
        //Default text/mood
        m_L_moodName.text = "---"
        m_IV_moodImage.image = UIImage(named: "SmileyNormal.png")
        
        for checkMoodExists in moods{
            
            if(returnDateForm(checkMoodExists.date as Date) ==  returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date)){
                dayHasContent = true
                m_L_moodName.text = checkMoodExists.moodName
                m_IV_moodImage.image = UIImage(named: checkMoodExists.moodImagePath)
            }
            
        }
        
        m_L_Date.text = returnDateForm(UserDefaults.standard.object(forKey: "dateUF") as! Date)
        
        m_tv_DayIds.reloadData()
        
        if !dayHasContent {
            m_L_Date.text = NSLocalizedString("No entry at this date", comment: "No entry at this date")
        }
        m_tv_DayIds.separatorColor = UIColor(red:22/255 ,green:204/255, blue:1.00 ,alpha:1.0)
        
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

