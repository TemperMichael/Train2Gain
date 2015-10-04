//
//  MoodCVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 26.04.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import CoreData
import Fabric
import Crashlytics
import iAd

let reuseIdentifier = "MoodCell"

class MoodCVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, ADBannerViewDelegate{
    
    var editMode = false
    
    var date : NSDate!

    @IBOutlet weak var cvc: UICollectionView!
    
    @IBOutlet weak var m_b_PickDate: UIButton!
    
    @IBOutlet weak var iAd: ADBannerView!
    
    //Get App Delegate
    var appdel =  UIApplication.sharedApplication().delegate as! AppDelegate
    
    var moods:[Moods] = []
    
    var selectedIndexPath:NSIndexPath?
    
    var imagePaths:[String] = ["SmileyNormal.png","SmileyNormal.png","SmileyGood.png","SmileyAggressive.png","SmileyAwesome.png","SmileySad.png","SmileyIrritated.png","SmileySick.png","SmileyTired.png","SmileyGreat.png","SmileyStressed.png","SmileyFantastic.png","SmileyKO.png"]
    
    var tutorialView:UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        iAd.delegate = self
        iAd.hidden = true
        
        if(NSUserDefaults.standardUserDefaults().objectForKey("tutorialMoods") == nil){
            tutorialView = UIImageView(frame: self.view.frame)
           
            tutorialView.image = UIImage(named: "TutorialMood.png")
             tutorialView.frame.origin.y += 15
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
        
        cvc.delegate = self
        cvc.dataSource = self
        
        //Setup smileys for mood collection view
        moods.append(Moods(_moodName: "Normal", _moodSmileyString: "SmileyNormal.png"))
        moods.append(Moods(_moodName: "Good", _moodSmileyString: "SmileyGood.png"))
        moods.append(Moods(_moodName: "Agressiv", _moodSmileyString: "SmileyAggressive.png"))
        moods.append(Moods(_moodName: "Awesome", _moodSmileyString: "SmileyAwesome.png"))
        moods.append(Moods(_moodName: "Sad", _moodSmileyString: "SmileySad.png"))
        moods.append(Moods(_moodName: "Irritated", _moodSmileyString: "SmileyIrritated.png"))
        moods.append(Moods(_moodName: "Sick", _moodSmileyString: "SmileySick.png"))
        moods.append(Moods(_moodName: "Tired", _moodSmileyString: "SmileyTired.png"))
        moods.append(Moods(_moodName: "Great", _moodSmileyString: "SmileyGreat.png"))
        moods.append(Moods(_moodName: "Stressed", _moodSmileyString: "SmileyStressed.png"))
        moods.append(Moods(_moodName: "Fantastic", _moodSmileyString: "SmileyFantastic.png"))
        moods.append(Moods(_moodName: "K.O.", _moodSmileyString: "SmileyKO.png"))
        
    }
    
    func hideTutorial(){
      
            self.navigationController?.navigationBarHidden = false
        UIView.transitionWithView(self.view, duration: 1, options: UIViewAnimationOptions.CurveLinear, animations: {
            self.tutorialView.alpha = 0;
            
            }, completion:{ finished in
               NSUserDefaults.standardUserDefaults().setObject(false, forKey: "tutorialMoods")
            self.tutorialView.removeFromSuperview()
            })
       
    }
    
    override func viewDidAppear(animated: Bool) {
        date = NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate
        m_b_PickDate.setTitle(returnDateForm(date), forState: UIControlState.Normal)
    }
    
    
    @IBAction func SaveCL(sender: AnyObject) {
        
        
        if(selectedIndexPath != nil){
            
           
            var managedObjectContext: NSManagedObjectContext? = {
                let coordinator = self.appdel.persistentStoreCoordinator;
                if coordinator == nil{
                    return nil
                }
                let managedObjectContext = NSManagedObjectContext()
                managedObjectContext.persistentStoreCoordinator = coordinator
                return managedObjectContext
                
                }()
            
            //Check if today an mood was already chosen to rewrite it if it already exists
            var alreadyExists = true
            var savePos : Int?
            
            
            //Get the saved moods
            let  requestMood = NSFetchRequest(entityName: "Mood")
            var savedMoods = (try! appdel.managedObjectContext?.executeFetchRequest(requestMood))  as! [Mood]
            
            
            
                let  request = NSFetchRequest(entityName: "Dates")
                //Get dates where something was saved
                var dates = (try! appdel.managedObjectContext?.executeFetchRequest(request))  as! [Dates]
            
            
            
           
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
            //Either create a new mood entry or rewrite the todays one
            if(savedMoods.count <= 0){
                addNewMood()
            }else{
                let lastMeasure = savedMoods[savedMoods.count-1]
                if(returnDateForm(lastMeasure.date) != returnDateForm(NSDate())){
                    addNewMood()
                }else{
                    addMood(lastMeasure)
                }
            }
            }else{
                var moodExists = false
                if(!alreadyExists){
                for singleMood in savedMoods{
                    if(returnDateForm(singleMood.date) == returnDateForm(date)){
                        moodExists = true
                        addMood(singleMood)
                    }
                }
                }
                
                if(!moodExists){
                    addNewMood()
                }
                
            }
            
            //Save context
            appdel.saveContext()
            
            //Go one view back
            
            let informUser = UIAlertController(title: "Saved", message:"Your mood was saved", preferredStyle: UIAlertControllerStyle.Alert)
            informUser.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.navigationController?.popViewControllerAnimated(true)
                
                
            }))
            
            let cell = cvc.cellForItemAtIndexPath(selectedIndexPath!) as! MoodCell;

            Answers.logContentViewWithName("Mood",
                contentType: "Saved data",
                contentId: cell.m_L_moodName.text!,
                customAttributes: [:])
            
            presentViewController(informUser, animated: true, completion: nil)
            
            
        }
        
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
    

    
    
    //Get the date in a good format
    func returnDateForm(date:NSDate) -> String{
        let dateFormatter = NSDateFormatter()
        
        let theDateFormat = NSDateFormatterStyle.ShortStyle
        let theTimeFormat = NSDateFormatterStyle.NoStyle
        
        dateFormatter.dateStyle = theDateFormat
        dateFormatter.timeStyle = theTimeFormat
        
        return dateFormatter.stringFromDate(date)
    }
    
    //Add mood to core data
    
    func addNewMood(){
         let newItem = NSEntityDescription.insertNewObjectForEntityForName("Mood", inManagedObjectContext: appdel.managedObjectContext!) as! Mood
        addMood(newItem)
    }
    
    
    func addMood(_Object:Mood){
       
        let cell = cvc.cellForItemAtIndexPath(selectedIndexPath!) as! MoodCell;
       
        _Object.date = date
        
        _Object.moodName = cell.m_L_moodName.text!
        _Object.moodImagePath = imagePaths[selectedIndexPath!.row+1]
        
        
    }
    
    //Save selected mood by index
     func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! MoodCell;
        selectedIndexPath = indexPath
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
     func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    
     func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return moods.count
    }
    
     func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! MoodCell
        
        cell.m_L_moodName.text = moods[indexPath.row].moodName
        cell.m_IV_moodSmiley.image = moods[indexPath.row].moodSmiley
        
        return cell
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
