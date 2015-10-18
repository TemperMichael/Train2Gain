//
//  ExercisesTVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 27.03.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import CoreData
import iAd

class ExercisesTVC: UIViewController ,UITableViewDelegate, UITableViewDataSource, ADBannerViewDelegate{
    
   
    
    var exercises:[Exercise] = []
    var appdel = UIApplication.sharedApplication().delegate as! AppDelegate
    var selectedExc: [Exercise] = []
    var dayIDs : [String] = []
    
    var selectedDayID : String!
    
    var tutorialView:UIImageView!
    
    @IBOutlet weak var tableView: UITableView!
  
    @IBOutlet weak var iAd: ADBannerView!
    
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        iAd.delegate = self
        iAd.hidden = true
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        if(NSUserDefaults.standardUserDefaults().objectForKey("tutorialTrainingPlans") == nil){
            //self.view.backgroundColor = UIColor(red: 0, green: 183/255, blue: 1, alpha: 1)
            tutorialView = UIImageView(frame: self.view.frame)
            
            tutorialView.image = UIImage(named: "TutorialTrainingPlans.png")
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

        
             selectedExc = []
        //Remove text from the back button
        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self, action: nil)
        backButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Heiti SC", size: 18)!], forState: UIControlState.Normal)
        navigationItem.backBarButtonItem = backButton
        
        
        //Hide empty cells
        let backgroundView = UIView(frame: CGRectZero)
        self.tableView.tableFooterView = backgroundView
        self.tableView.backgroundColor = UIColor(red:22/255 ,green:200/255, blue:1.00 ,alpha: 0)
        
        
        tableView.delegate = self
        tableView.dataSource = self
        
       
        
    }
    
    func hideTutorial(){
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)

        
        self.navigationController?.navigationBarHidden = false
        UIView.transitionWithView(self.view, duration: 1, options: UIViewAnimationOptions.CurveLinear, animations: {
            self.tutorialView.alpha = 0;
            
            }, completion:{ finished in
                   NSUserDefaults.standardUserDefaults().setObject(false, forKey: "tutorialTrainingPlans")
                
                self.tutorialView.removeFromSuperview()
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
    
 

    
    override func viewDidAppear(animated: Bool) {
        
        //Set actual date
        NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: "dateUF")
        
        //Reset lists
        dayIDs = []
        selectedExc = []
        exercises = []
        
        
        //Hide empty cells
        let backgroundView = UIView(frame: CGRectZero)
        self.tableView.tableFooterView = backgroundView
        self.tableView.backgroundColor = UIColor(red:22/255 ,green:200/255, blue:1.00 ,alpha: 0)
        
        
        
        //Get exercises core data
        let  request = NSFetchRequest(entityName: "Exercise")
        exercises = (try! appdel.managedObjectContext?.executeFetchRequest(request))  as! [Exercise]
        
        
        
        //Get strings for tabeview
        var checkString = ""
        var checkBefore = ""

        var exists = false
        
        for checkIDAmount in exercises {
           exists = false
            for singleDayId in dayIDs{
             
                if(checkIDAmount.dayID == singleDayId){
                    exists = true
                }
            }
            
            if(!exists){
                 dayIDs.append(checkIDAmount.dayID)
            }
           
        }
        
        tableView.reloadData()
        
        tableView.separatorColor = UIColor(red:22/255 ,green:204/255, blue:1.00 ,alpha:1.0)
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    //--------------------------------------------------
    //TableView Methods
     func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    
    }
    
     func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        //Save the selected exercises for the next view
        for(var i = 0 ; i < exercises.count ; i++){
            if(exercises[i].dayID == dayIDs[indexPath.row]){
                selectedExc.append(exercises[i])
            }
        }
        return indexPath
        
    }
    
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Delete") { (action, index) -> Void in
            
            let context:NSManagedObjectContext = self.appdel.managedObjectContext!
            
            for(var i = 0; i < self.exercises.count ; i++){
                
                if(self.exercises[i].dayID == self.dayIDs[indexPath.row]){
                    context.deleteObject(self.exercises[i] as NSManagedObject)
                    self.exercises.removeAtIndex(i)
                    
                    i--;
                }
            }
            
            self.dayIDs.removeAtIndex(indexPath.row)
            
            do {
                try context.save()
            } catch _ {
            }
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            

            
        }
        deleteAction.backgroundColor = UIColor(red:86/255 ,green:158/255, blue:197/255 ,alpha:1)
        
        
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Edit") { (action, index) -> Void in
          
           
            for(var i = 0 ; i < self.exercises.count ; i++){
                if(self.exercises[i].dayID == self.dayIDs[indexPath.row]){

                    self.selectedExc.append(self.exercises[i])
                    
                }
            }
              self.performSegueWithIdentifier("AddExercise", sender: UITableViewRowAction())
            
        }
        
        editAction.backgroundColor = UIColor(red:112/255 ,green:188/255, blue:224/255 ,alpha:1)
        
        
        return [deleteAction,editAction]
        
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //Give the next view the selected exercises
        if(segue.identifier == "ExerciseChosen"){
           
            
            let vc = segue.destinationViewController as! ExerciseChosenVC
            vc.clickedExc = selectedExc
        }
        
    
        if(segue.identifier == "AddExercise"){
            
           
            if let editAction = sender as? UITableViewRowAction{
               let vc = segue.destinationViewController as! AddExerciseVC
                vc.editMode = true

                vc.selectedExc = self.selectedExc
                
            }
        }
        
    }
    
     func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
     func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dayIDs.count
    }
    
    
     func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ExerciseCell", forIndexPath: indexPath) 
        cell.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 18)
        cell.textLabel?.textColor = UIColor(red:22/255 ,green:204/255, blue:1.00 ,alpha:1.0)
        cell.textLabel?.text = dayIDs[indexPath.row]
        cell.backgroundColor = UIColor.whiteColor()
       
        
        
        //Set Seperator left to zero
        cell.separatorInset = UIEdgeInsetsZero
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsetsZero
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

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)

    }
    
    
}
