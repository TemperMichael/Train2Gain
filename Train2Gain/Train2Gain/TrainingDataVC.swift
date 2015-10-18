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
    
    var dayIDs :[String] = []
    
    var doneExercises : [DoneExercise] = []
    
    var measurements : [Measurements] = []
    
    var moods : [Mood] = []
    
    var selectedDayDetails : [String] = []
    
    var  selectedDoneExc : [DoneExercise] = []
    
     var appdel = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var weightUnit: String! = NSUserDefaults.standardUserDefaults().objectForKey("weightUnit")! as! String
    
    var lengthUnit:String! = NSUserDefaults.standardUserDefaults().objectForKey("lengthUnit")! as! String
    
    let  requestDoneEx = NSFetchRequest(entityName: "DoneExercise")
    var doneEx:[DoneExercise]!
    
    var tutorialView:UIImageView!
    
    var showTutorial2 = true;

    
    @IBAction func nextDayCL(sender: AnyObject) {
        
        var date : NSDate = NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate
        //Go to next day
        date = date.dateByAddingTimeInterval(60*60*24)
        NSUserDefaults.standardUserDefaults().setObject(date ,forKey: "dateUF")

        viewDidAppear(true)
        
    }
    
    @IBAction func prevDayCL(sender: AnyObject) {
        
        var date : NSDate = NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate
        //Go to prevoius day
        date = date.dateByAddingTimeInterval(-60*60*24)
        NSUserDefaults.standardUserDefaults().setObject(date ,forKey: "dateUF")
        
        viewDidAppear(true)
    
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        iAd.delegate = self
        iAd.hidden = true
        
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        if(NSUserDefaults.standardUserDefaults().objectForKey("tutorialTrainingData") == nil){
            //self.view.backgroundColor = UIColor(red: 0, green: 183/255, blue: 1, alpha: 1)
            
            tutorialView = UIImageView(frame: self.view.frame)
            
            tutorialView.image = UIImage(named: "TutorialTrainingData1.png")
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
        
    
        //Hide empty cells
        let backgroundView = UIView(frame: CGRectZero)
        
        self.m_tv_DayIds.tableFooterView = backgroundView
        
        self.m_tv_DayIds.backgroundColor = UIColor(red:86/255 ,green:158/255, blue:197/255 ,alpha:0)

        selectedDoneExc = []
        //Remove text from back button
        let backButton = UIBarButtonItem(title: " ", style: UIBarButtonItemStyle.Plain, target: self, action: nil)
        backButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Chalkduster", size: 20)!], forState: UIControlState.Normal)
        navigationItem.backBarButtonItem = backButton
        
        m_b_PickDate.titleLabel?.text = returnDateForm(NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate)
 
        m_tv_DayIds.dataSource = self
        m_tv_DayIds.delegate = self
        
        Answers.logContentViewWithName("Watched Training data",
            contentType: "Saved data",
            contentId: "Training data",
            customAttributes: [:])

        
        doneEx = (try! appdel.managedObjectContext?.executeFetchRequest(requestDoneEx))  as! [DoneExercise]
    }
    
    func hideTutorial(){
     
        
        if !showTutorial2{
            var backgroundIMG = UIImage(named: "Background2.png")
            backgroundIMG = imageResize(backgroundIMG!, sizeChange: view.frame.size)
            self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)

            self.navigationController?.navigationBarHidden = false
        }
        
            UIView.transitionWithView(self.view, duration: 1, options: UIViewAnimationOptions.CurveLinear, animations: {
                if self.showTutorial2{
                
                    self.tutorialView.image = UIImage(named: "TutorialTrainingData2.png")
                   
                }else{
                    self.tutorialView.alpha = 0
                }
                
                }, completion:{ finished in
                    
                    if !self.showTutorial2{
                           NSUserDefaults.standardUserDefaults().setObject(false, forKey: "tutorialTrainingData")
                    self.tutorialView.removeFromSuperview()
                    }
                    self.showTutorial2 = false
            })
        
        }
    
        
    
    
    
    //Fit background image to display size
    func imageResize (imageObj:UIImage, sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: true)
        
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return dayIDs.count
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        
        selectedDayDetails.append(dayIDs[indexPath.row]);
        selectedDayDetails.append(m_L_Date.text!);
        
        return indexPath
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //Save chosen exercise day
        if(segue.identifier == "DayIDChosen"){
            let vc = segue.destinationViewController as! DayIDChosenTVC
            vc.selectedDayDetails = selectedDayDetails
            
        }
        
        if(segue.identifier == "editSegue"){
            let vc = segue.destinationViewController as! EditDayIDVC
            vc.selectedExc = selectedDoneExc
        }
        
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        //Has to stand here so custom action can be used
    }
 
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Delete") { (action, index) -> Void in
            let context:NSManagedObjectContext = self.appdel.managedObjectContext!
            
           
            
            
            for(var i = 0; i < self.doneEx.count ; i++){
                
                if(self.doneEx[i].dayID == self.dayIDs[indexPath.row] && self.returnDateForm(self.doneEx[i].date) == self.returnDateForm(NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate)){
                    
                    
                    context.deleteObject(self.doneEx[i] as NSManagedObject)
                    self.doneEx.removeAtIndex(i)
                    
                    i--;
                }
            }
            
            self.dayIDs.removeAtIndex(indexPath.row)
            
            do {
                try context.save()
            } catch _ {
            }
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)

        }
        deleteAction.backgroundColor = UIColor(red:86/255 ,green:158/255, blue:197/255 ,alpha:1)
        
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Edit") { (action, index) -> Void in
          //  tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            
            for(var i = 0 ; i < self.doneEx.count ; i++){
                if(self.doneEx[i].dayID == self.dayIDs[indexPath.row] && self.returnDateForm(self.doneEx[i].date) == self.returnDateForm(NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate)){
                    self.selectedDoneExc.append(self.doneEx[i])
                }
            }
            
            self.performSegueWithIdentifier("editSegue", sender: nil)

        }
        
         editAction.backgroundColor = UIColor(red:112/255 ,green:188/255, blue:224/255 ,alpha:1)
        
        return [deleteAction,editAction]
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("TrainingDataCell", forIndexPath: indexPath) 
        
        //Set Seperator left to zero
        cell.separatorInset = UIEdgeInsetsZero
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsetsZero
        
        cell.textLabel?.text = dayIDs[indexPath.row]
        
        cell.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 18)
        cell.textLabel?.textColor = UIColor(red:22/255 ,green:204/255, blue:1.00 ,alpha:1.0)
        cell.textLabel?.textAlignment = .Center
        cell.backgroundColor = UIColor.whiteColor()
        
        return cell
    }
    
    override func viewDidAppear(animated: Bool) {
        //Reset lists
        selectedDayDetails = []
         dayIDs = []
        
        selectedDoneExc = []
        var dayHasContent = false
        //Show date of chosen day
        m_b_PickDate.setTitle(returnDateForm(NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate), forState: UIControlState.Normal)
        
        //Hide empty cells
        let backgroundView = UIView(frame: CGRectZero)
        
        self.m_tv_DayIds.tableFooterView = backgroundView
        
        self.m_tv_DayIds.backgroundColor = UIColor(red:86/255 ,green:158/255, blue:197/255 ,alpha:0)
       
        //Get data
        let appdel =  UIApplication.sharedApplication().delegate as! AppDelegate
        let  requestDoneEx = NSFetchRequest(entityName: "DoneExercise")
        doneExercises = (try! appdel.managedObjectContext?.executeFetchRequest(requestDoneEx))  as! [DoneExercise]
        
        let  requestMeasurements = NSFetchRequest(entityName: "Measurements")
        measurements = (try! appdel.managedObjectContext?.executeFetchRequest(requestMeasurements))  as! [Measurements]
        
        let  requestMood = NSFetchRequest(entityName: "Mood")
        moods = (try! appdel.managedObjectContext?.executeFetchRequest(requestMood))  as! [Mood]
        
        var checkString = ""
        var checkBefore = ""
        var dayIDExists = true
        for checkIDAmount in doneExercises {
            
            if(returnDateForm(checkIDAmount.date) ==  returnDateForm(NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate)){
                dayHasContent = true
                checkBefore=checkString
                
                
                checkString = checkIDAmount.dayID
                if(checkString != checkBefore){
                    
                    for checkIds in dayIDs{
                        
                        
                        if(checkIds == checkIDAmount.dayID){
                            
                            dayIDExists = false;
                        }
                    }
                    if(dayIDExists){
                        dayIDs.append(checkIDAmount.dayID)
                    }
                    
                    
                }
                m_L_Date.text = returnDateForm(checkIDAmount.date)
            }
            
        }
        //Default text
        m_L_Weight.text = "Weight: ---"
        m_L_Arm.text = "Arms: ---"
        m_L_Chest.text = "Chest: ---"
        m_L_Waist.text = "Waist: ---"
        m_L_Legs.text = "Legs: ---"
        
        //Show data in right unit
        for checkMeasureExists in measurements {
            
            if(returnDateForm(checkMeasureExists.date) ==  returnDateForm(NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate)){
                var weight = (checkMeasureExists.weight).doubleValue
                if(weightUnit == "lbs"){
                    weight = weight * 2.20462262185
                }
                
                dayHasContent = true
                m_L_Weight.text = NSString(format:"Weight: %.2f \(weightUnit)",weight ) as String
                
                var length = (checkMeasureExists.arm).doubleValue
                if(lengthUnit == "inch"){
                    length = length/2.54
                }
                m_L_Arm.text =  NSString(format:"Arms: %.2f \(lengthUnit)",length ) as String
                
                length = (checkMeasureExists.chest).doubleValue
                if(lengthUnit == "inch"){
                    length = length/2.54
                }
                m_L_Chest.text =  NSString(format:"Chest: %.2f \(lengthUnit)",length ) as String
                
                
                length = (checkMeasureExists.waist).doubleValue
                if(lengthUnit == "inch"){
                    length = length/2.54
                }
                m_L_Waist.text =  NSString(format:"Waist: %.2f \(lengthUnit)",length ) as String
                
                length = (checkMeasureExists.leg).doubleValue
                if(lengthUnit == "inch"){
                    length = length/2.54
                }
                m_L_Legs.text =  NSString(format:"Legs: %.2f \(lengthUnit)",length ) as String
            }
            
        }
        //Default text/mood
        m_L_moodName.text = "---"
        m_IV_moodImage.image = UIImage(named: "SmileyNormal.png")
        
        for checkMoodExists in moods{
            
            if(returnDateForm(checkMoodExists.date) ==  returnDateForm(NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate)){
                dayHasContent = true
                m_L_moodName.text = checkMoodExists.moodName
                m_IV_moodImage.image = UIImage(named: checkMoodExists.moodImagePath)
            }
            
        }
        
        m_L_Date.text = returnDateForm(NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate)
        
        m_tv_DayIds.reloadData()
        
        let  requestDates = NSFetchRequest(entityName: "Measurements")
        
        if(!dayHasContent){
            m_L_Date.text = "No entry at this date"
        }
        m_tv_DayIds.separatorColor = UIColor(red:22/255 ,green:204/255, blue:1.00 ,alpha:1.0)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        returnDateForm(NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate)
        
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
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
         if(NSUserDefaults.standardUserDefaults().objectForKey("tutorialTrainingData") == nil){
             hideTutorial()
           if(NSUserDefaults.standardUserDefaults().objectForKey("tutorialTrainingData") == nil){
                hideTutorial()
            
            self.navigationController?.navigationBarHidden = false
            }
        }
        
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
    }
    

    
}

