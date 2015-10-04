//
//  AddExerciseVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 29.03.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import CoreData
import iAd

class AddExerciseVC: UIViewController, UITextFieldDelegate, ADBannerViewDelegate{
    
    @IBOutlet weak var m_tf_ListName: UITextField!
    @IBOutlet weak var m_tf_Reps: UITextField!
    @IBOutlet weak var m_tf_Sets: UITextField!
    @IBOutlet weak var m_tf_Name: UITextField!
    
    // @IBOutlet weak var previousExButton: UIBarButtonItem!
    
    @IBOutlet weak var previousExButton: UIButton!
    
    @IBOutlet weak var iAd: ADBannerView!
    
    // @IBOutlet weak var deleteExButton: UIBarButtonItem!
    
    @IBOutlet weak var deleteExButton: UIButton!
    
    // @IBOutlet weak var nextExButton: UIBarButtonItem!
    
    @IBOutlet weak var nextExButton: UIButton!
    
    //  @IBOutlet weak var addExButton: UIBarButtonItem!
    
    @IBOutlet weak var addExButton: UIButton!
    
    var exercises : [[String]] = [["","",""]]
    var dayId : String = ""
    var userPos : Int = 0
    var deleteOn : Bool = false
    
    var appdel =  UIApplication.sharedApplication().delegate as! AppDelegate
    
    var editMode = false
    var editDayIDSaver = ""
    
    var selectedExc : [Exercise] = []
    var tutorialView:UIImageView!
    
    
    //--------------------------------------------------------
    // View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        iAd.delegate = self
        iAd.hidden = true
        
        if(NSUserDefaults.standardUserDefaults().objectForKey("tutorialAddExercise") == nil){
            self.view.backgroundColor = UIColor(red: 25/255, green: 165/255, blue: 1, alpha: 1)
            tutorialView = UIImageView(frame: self.view.frame)
            
            tutorialView.image = UIImage(named: "TutorialAddExercise.png")
            tutorialView.frame.origin.y += 18
            if(self.view.frame.size.height <= 490){
                tutorialView.frame.size.height -= 10
            }else{
                tutorialView.frame.size.height -= 60
            }

            tutorialView.userInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action:"hideTutorial")
            tutorialView.addGestureRecognizer(tap)
            self.view.addSubview(tutorialView)
            self.navigationController?.navigationBarHidden = true
            
        }else{
            let bgSize = CGSize(width: view.frame.width, height: view.frame.height)
            var backgroundIMG = UIImage(named: "Background2.png")
            backgroundIMG = imageResize(backgroundIMG!, sizeChange: bgSize)
            self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)


        }

        //Set delegates of textfields
        m_tf_Reps.delegate = self
        m_tf_Sets.delegate = self
        m_tf_Name.delegate = self
        m_tf_ListName.delegate = self
        
        //Setup background
        
        
        //self.navigationController?.setToolbarHidden(false, animated: true)
        
        //Setup buttons
        if(editMode){
            self.title = "Edit Training plan"
            editDayIDSaver = selectedExc[0].dayID
            var currentName = ""
            var prevName = ""
            var first = true
            
            for singleEx in selectedExc{
                
                prevName = currentName
                currentName = singleEx.name
                
                if(prevName != currentName){
                    if(first){
                        exercises[userPos] = [singleEx.name,"\(singleEx.reps)","\(singleEx.sets)"]
                        m_tf_ListName.text = singleEx.dayID
                        first = false
                    }else{
                        exercises.append([singleEx.name,"\(singleEx.reps)","\(singleEx.sets)"])
                    }
                    m_tf_Name.text = exercises[userPos][0]
                    m_tf_Reps.text = exercises[userPos][1]
                    m_tf_Sets.text = exercises[userPos][2]
                }
                
                
                
                
            }
            
        }
        if(exercises.count <= 1){
            deleteExButton.enabled = false
            
            
            nextExButton.enabled = false
            nextExButton.setTitle("", forState: UIControlState.Normal)
        }
        
        
        previousExButton.enabled = false
        previousExButton.setTitle("", forState: UIControlState.Normal)
        
    }
    
    
    func hideTutorial(){
        let bgSize = CGSize(width: view.frame.width, height: view.frame.height - 50)
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: bgSize)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)

        
        self.navigationController?.navigationBarHidden = false
        UIView.transitionWithView(self.view, duration: 1, options: UIViewAnimationOptions.CurveLinear, animations: {
            self.tutorialView.alpha = 0;
            
            }, completion:{ finished in
                 NSUserDefaults.standardUserDefaults().setObject(false, forKey: "tutorialAddExercise")
                self.tutorialView.removeFromSuperview()
        })
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: true)
        
    }
    
    
    //--------------------------------------------------------
    //Click Listener
    //Add a new exercise
    @IBAction func AddExButtonCL(sender: AnyObject) {
        if(allFilled()){
            
            exercises[userPos] = [m_tf_Name.text!,m_tf_Reps.text!,m_tf_Sets.text!]
            exercises.insert(["","",""], atIndex: userPos+1)
            filterSpecificView(false)
            clearDetails()
            
        }
    }
    //Delte actual exercise
    @IBAction func deleteExButtonCL(sender: AnyObject) {
        
        let  request = NSFetchRequest(entityName: "Exercise")
        var exercisesCD = (try! appdel.managedObjectContext?.executeFetchRequest(request))  as! [Exercise]
        /*
        if(editMode){
            for singleExCD in exercisesCD{
                if((singleExCD.dayID == m_tf_ListName.text || singleExCD.dayID == editDayIDSaver) && singleExCD.name == exercises[userPos][0]){
                   
                    appdel.managedObjectContext!.deleteObject(singleExCD as NSManagedObject)
                }
            }
        }
*/
        exercises.removeAtIndex(userPos)
        deleteOn = true
        
        
     
        if (userPos > 0){
            filterSpecificView(true)
        }else{
            filterSpecificView(false)
        }
        
    }
    
    
    //Show previous exercise
    @IBAction func previousExButtonCL(sender: AnyObject) {
        exercises[userPos] = [m_tf_Name.text!,m_tf_Reps.text!,m_tf_Sets.text!]
        filterSpecificView(true)
    }
    //Show next exercise
    @IBAction func nextExButtonCL(sender: AnyObject) {
        exercises[userPos] = [m_tf_Name.text!,m_tf_Reps.text!,m_tf_Sets.text!]
        filterSpecificView(false)
        
    }
    
    @IBAction func saveClickListener(sender: AnyObject) {
        //Save all created exercises
        if(allFilled()){
            dayId = m_tf_ListName.text!
            exercises[userPos] = [m_tf_Name.text!,m_tf_Reps.text!,m_tf_Sets.text!]
            
                        var managedObjectContext: NSManagedObjectContext? = {
                let coordinator = self.appdel.persistentStoreCoordinator;
                if coordinator == nil{
                    return nil
                }
                var managedObjectContext = NSManagedObjectContext()
                managedObjectContext.persistentStoreCoordinator = coordinator
                return managedObjectContext
                
                }()
            
            
                let  request = NSFetchRequest(entityName: "Exercise")
                var exercisesCD = (try! appdel.managedObjectContext?.executeFetchRequest(request))  as! [Exercise]
                
            var exists = false
            var i = 0;
            if(editMode){
                for singleExCD in exercisesCD{
                    if(singleExCD.dayID == editDayIDSaver){
                        print("DONE");
                        appdel.managedObjectContext!.deleteObject(singleExCD as NSManagedObject)
                    }
                }
            }
            appdel.saveContext()
            
            for checkCells in self.exercises{
               // if(!editMode){
                let newItem = NSEntityDescription.insertNewObjectForEntityForName("Exercise", inManagedObjectContext: appdel.managedObjectContext!) as! Exercise
                newItem.dayID = dayId
                print(checkCells[0])
                newItem.name = checkCells[0]
                newItem.reps = Int(checkCells[1])!
                newItem.sets = Int(checkCells[2])!
               /*
                }else{
                    exists = false
                    for singleExCD in exercisesCD{
                        if(singleExCD.dayID == dayId || singleExCD.dayID == editDayIDSaver){
                            if(singleExCD.name == checkCells[0]){
                            singleExCD.reps = checkCells[1].toInt()!
                            singleExCD.sets = checkCells[2].toInt()!
                                if(singleExCD.dayID == editDayIDSaver){
                                    singleExCD.dayID = dayId
                                }
                                exists = true
                            }
                        }
                    }
                    
                    if(!exists){
                    let newItem = NSEntityDescription.insertNewObjectForEntityForName("Exercise", inManagedObjectContext: appdel.managedObjectContext!) as! Exercise
                    newItem.dayID = dayId
                    newItem.name = checkCells[0]
                    newItem.reps = checkCells[1].toInt()!
                    newItem.sets = checkCells[2].toInt()!
                        
                        
                 //   appdel.managedObjectContext.
                    
                      
                      
                    }
                }*/
                appdel.saveContext();
                
            }
           
            
            
            var informUser = UIAlertController(title: "Saved", message:"Your training plan was saved", preferredStyle: UIAlertControllerStyle.Alert)
            informUser.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.navigationController?.popViewControllerAnimated(true)
                
                
            }))
            
            presentViewController(informUser, animated: true, completion: nil)
            
            
            
            
            
            
        }
        
        
    }
    
    //--------------------------------------------------------
    // Own Methods
    
    //Fit background image to display size
    func imageResize (imageObj:UIImage, sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
    }
    
    //Check if everything was entered
    func allFilled() -> Bool{
        var check = true;
        
        if(m_tf_ListName.text == ""){
            m_tf_ListName.backgroundColor = UIColor(red:218/255 ,green:52/255, blue:60/255 ,alpha:1.0)
            m_tf_ListName.placeholder = "Enter something!"
            check = false
        }
        if(m_tf_Reps.text == ""){
            m_tf_Reps.backgroundColor = UIColor(red:218/255 ,green:52/255, blue:60/255 ,alpha:1.0)
            m_tf_Reps.placeholder = "Enter sth.!"
            check = false
        }
        
        if(m_tf_Name.text == ""){
            m_tf_Name.backgroundColor = UIColor(red:218/255 ,green:52/255, blue:60/255 ,alpha:1.0)
            m_tf_Name.placeholder = "Enter sth.!"
            check = false
        }
        
        if(m_tf_Sets.text == ""){
            m_tf_Sets.backgroundColor = UIColor(red:218/255 ,green:52/255, blue:60/255 ,alpha:1.0)
            m_tf_Sets.placeholder = "Enter sth.!"
            check = false
        }
        return check
        
    }
    
    func clearDetails(){
        m_tf_Name.text = ""
        m_tf_Reps.text = ""
        m_tf_Sets.text = ""
    }
    
    func filterSpecificView(animationDirection: Bool){
        if(deleteOn || allFilled()){
            dayId = m_tf_ListName.text!
            for _view in self.view.subviews{
                if let view = _view as? UIView{
                    if( view.tag == 123){
                        
                        //Start animation
                        slideIn(1, completionDelegate: _view,direction: animationDirection)
                        //Load in next exercise
                        if(deleteOn && !animationDirection){
                            userPos = 0
                        }
                        m_tf_Name.text = exercises[userPos][0]
                        m_tf_Reps.text = exercises[userPos][1]
                        m_tf_Sets.text = exercises[userPos][2]
                        
                        //Enable/Disable buttons
                        if(userPos > 0){
                            previousExButton.enabled = true
                            previousExButton.setTitle("<", forState: UIControlState.Normal)
                            deleteExButton.enabled = true
                        }else{
                            previousExButton.enabled = false
                            previousExButton.setTitle("", forState: UIControlState.Normal)
                            
                        }
                        
                        if(exercises.count <= 1){
                            deleteExButton.enabled = false
                        }
                        if(userPos+1 < exercises.count){
                            
                            nextExButton.enabled = true
                            nextExButton.setTitle(">", forState: UIControlState.Normal)
                        }else{
                            nextExButton.enabled = false
                            nextExButton.setTitle("", forState: UIControlState.Normal)
                        }
                        
                        
                    }
                }
            }
            deleteOn = false
        }
    }
    
    
    //--------------------------------------------------------
    // Keyboard methods
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        //Close Keyboard when clicking outside
        m_tf_Name.resignFirstResponder()
        m_tf_Sets.resignFirstResponder()
        m_tf_Reps.resignFirstResponder()
        m_tf_ListName.resignFirstResponder()
    }
    
    
    
    func textFieldDidBeginEditing(textField: UITextField) {
        //Push up view to see what you are actual entering
        switch(textField){
        case m_tf_Reps:
            self.view.frame.origin.y -= 80
            break;
        case m_tf_Sets:
            self.view.frame.origin.y -= 80
            break;
        case m_tf_Name:
            self.view.frame.origin.y -= 20
            
            break;
        default: break;
        }
        
    }
    
    
    func textFieldDidEndEditing(textField: UITextField) {
        //Put view back down after entering in text fields
        switch(textField){
        case m_tf_Reps:
            self.view.frame.origin.y += 80
            break;
        case m_tf_Sets:
            self.view.frame.origin.y += 80
            break;
        case m_tf_Name:
            self.view.frame.origin.y += 20
            break;
        default: break;
        }
        
        
    }
    
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        //Jump to next textfield by clicking on "next" button
        if(string == "\n"){
            textField.endEditing(true)
            switch (textField){
            case m_tf_ListName:
                
                m_tf_Name.becomeFirstResponder()
                break;
                
            case m_tf_Name:
                m_tf_Sets.becomeFirstResponder()
                break;
            default:
                break;
                
            }
            return true
        }
        
        textField.backgroundColor = UIColor.whiteColor()
        textField.placeholder = ""
        var myCharacterSet : NSCharacterSet?
        let text = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        
        //Setup input settings
        let newLength = textField.text!.characters.count + string.characters.count - range.length
        var back = 0
        if(textField == m_tf_Reps){
            back = 2
            
            if (newLength <= back && ((Int(text) > 0 && Int(text) < 100) || text == "")) {
                return true
            } else {
                return false
            }
        }else if(textField == m_tf_Sets){
            back = 1
            if (newLength <= back && ((Int(text) > 0 && Int(text) < 10) || text == "")) {
                return true
            } else {
                return false
            }
            
        }else{
            back = 13
        }
        return newLength <= back
        
    }
    
    //--------------------------------------------------------
    //Animation
    
    
    func slideIn(duration: NSTimeInterval = 1.0, completionDelegate: AnyObject? = nil, direction:Bool) {
        m_tf_Name.backgroundColor = UIColor.whiteColor()
        m_tf_Sets.backgroundColor = UIColor.whiteColor()
        m_tf_Reps.backgroundColor = UIColor.whiteColor()
        // Create a CATransition animation
        let slideInTransition = CATransition()
        
        // Set its callback delegate to the completionDelegate that was provided (if any)
        if let delegate: AnyObject = completionDelegate {
            slideInTransition.delegate = delegate
        }
        
        // Customize the animation's properties
        slideInTransition.type = kCATransitionMoveIn
        if(direction){
            userPos--
            slideInTransition.subtype = kCATransitionFromLeft
        }else{
            userPos++
            slideInTransition.subtype = kCATransitionFromRight
        }
        slideInTransition.duration = duration
        slideInTransition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        slideInTransition.fillMode = kCAFillModeRemoved
        
        // Add the animation to the View's layer
        (completionDelegate as! UIView).layer.addAnimation(slideInTransition, forKey: "slideInTransition")
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
