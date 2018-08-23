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

class MoodCVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, ADBannerViewDelegate {
    
    var editMode = false
    var date: Date!
    var appdel = UIApplication.shared.delegate as! AppDelegate
    var moods: [Moods] = []
    var selectedIndexPath: IndexPath?
    var imagePaths: [String] = ["SmileyNormal.png", "SmileyNormal.png", "SmileyGood.png", "SmileyAggressive.png", "SmileyAwesome.png", "SmileySad.png", "SmileyIrritated.png", "SmileySick.png", "SmileyTired.png", "SmileyGreat.png", "SmileyStressed.png", "SmileyFantastic.png", "SmileyKO.png"]
    var tutorialView: UIImageView!
    let reuseIdentifier = "MoodCell"
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
    
    // MARK: IBOutlets & IBActions
    @IBOutlet weak var cvc: UICollectionView!
    @IBOutlet weak var m_b_PickDate: UIButton!
    @IBOutlet weak var iAd: ADBannerView!
    @IBOutlet weak var pickerView: UIDatePicker!
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var pickerTitle: UILabel!
    

    override func viewDidAppear(_ animated: Bool) {
        date = UserDefaults.standard.object(forKey: "dateUF") as! Date
        m_b_PickDate.setTitle(returnDateForm(date), for: UIControlState())
    }
    

    @IBOutlet weak var pickerBG: UIView!

    @IBAction func SaveCL(_ sender: AnyObject) {
        
        if selectedIndexPath != nil {
            
            //Check if today an mood was already chosen to rewrite it if it already exists
            var alreadyExists = true
            var savePos: Int?
            
            //Get the saved moods
            let  requestMood = NSFetchRequest<NSFetchRequestResult>(entityName: "Mood")
            var savedMoods = (try! appdel.managedObjectContext?.fetch(requestMood))  as! [Mood]
            let  request = NSFetchRequest<NSFetchRequestResult>(entityName: "Dates")
            
            //Get dates where something was saved
            var dates = (try! appdel.managedObjectContext?.fetch(request))  as! [Dates]
            date = UserDefaults.standard.object(forKey: "dateUF") as! Date
            
            //Check if data already exists
            for i in 0 ..< dates.count {
                if returnDateForm(dates[i].savedDate) == returnDateForm(date) {
                    alreadyExists = false
                    savePos = i;
                }
            }
            
            //Rewrite date
            if alreadyExists {
                let newItem = NSEntityDescription.insertNewObject(forEntityName: "Dates", into: appdel.managedObjectContext!) as! Dates
                newItem.savedDate = Date()
            }
            
            
            if !editMode {
                //Either create a new mood entry or rewrite the todays one
                if savedMoods.count <= 0 {
                    addNewMood()
                } else {
                    let lastMeasure = savedMoods[savedMoods.count-1]
                    if returnDateForm(lastMeasure.date) != returnDateForm(Date()) {
                        addNewMood()
                    } else {
                        addMood(lastMeasure)
                    }
                }
            } else {
                var moodExists = false
                if !alreadyExists {
                    for singleMood in savedMoods{
                        if returnDateForm(singleMood.date) == returnDateForm(date) {
                            moodExists = true
                            addMood(singleMood)
                        }
                    }
                }
                if !moodExists {
                    addNewMood()
                }
            }
            
            //Save context
            appdel.saveContext()
            
            // Go one view back
            let informUser = UIAlertController(title: NSLocalizedString("Saved", comment: "Saved"), message:NSLocalizedString("Your mood was saved", comment: "Your mood was saved"), preferredStyle: UIAlertControllerStyle.alert)
            informUser.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.default, handler: { (action) -> Void in
                self.navigationController?.popViewController(animated: true)
            }))
            let cell = cvc.cellForItem(at: selectedIndexPath!) as! MoodCell;
            
            //Fabric - Analytic Tool
            Answers.logContentView(withName: "Mood",
                contentType: "Saved data",
                contentId: cell.m_L_moodName.text!,
                customAttributes: [:])
            
            present(informUser, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func nextDayCL(_ sender: AnyObject) {
        
        //Go to next day
        date = date.addingTimeInterval(60 * 60 * 24)
        UserDefaults.standard.set(date , forKey: "dateUF")
        m_b_PickDate.setTitle(returnDateForm(date), for: UIControlState())
        
    }
    
    @IBAction func prevDayCL(_ sender: AnyObject) {
        
        //Go to prevoius day
        date = date.addingTimeInterval(-60 * 60 * 24)
        UserDefaults.standard.set(date, forKey: "dateUF")
        m_b_PickDate.setTitle(returnDateForm(date), for: UIControlState())
        
    }

    @IBAction func pickDateClicked(_ sender: AnyObject) {
        
        setupPickerView()
        
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
    
    // MARK: View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Handle iAd
        iAd.delegate = self
        iAd.isHidden = true
        
        //Show Tutorial
        if UserDefaults.standard.object(forKey: "tutorialMoods") == nil {
            tutorialView = UIImageView(frame: self.view.frame)
            
            tutorialView.image = UIImage(named: "TutorialMood.png")
            tutorialView.frame.origin.y += 15
            
            if self.view.frame.size.height <= 490 {
                tutorialView.frame.size.height += 60
            } else {
                tutorialView.frame.size.height -= 60
            }
            
            tutorialView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(MoodCVC.hideTutorial))
            tutorialView.addGestureRecognizer(tap)
            self.view.addSubview(tutorialView)
            self.navigationController?.isNavigationBarHidden = true
        }
        
        cvc.delegate = self
        cvc.dataSource = self
        
        //Setup smileys for mood collection view
        moods.append(Moods(_moodName: NSLocalizedString("Normal", comment: "Normal"), _moodSmileyString: "SmileyNormal.png"))
        moods.append(Moods(_moodName: NSLocalizedString("Good", comment: "Good"), _moodSmileyString: "SmileyGood.png"))
        moods.append(Moods(_moodName: NSLocalizedString("Agressiv", comment: "Agressiv"), _moodSmileyString: "SmileyAggressive.png"))
        moods.append(Moods(_moodName: NSLocalizedString("Awesome", comment: "Awesome"), _moodSmileyString: "SmileyAwesome.png"))
        moods.append(Moods(_moodName: NSLocalizedString("Sad", comment: "Sad"), _moodSmileyString: "SmileySad.png"))
        moods.append(Moods(_moodName: NSLocalizedString("Irritated", comment: "Irritated"), _moodSmileyString: "SmileyIrritated.png"))
        moods.append(Moods(_moodName: NSLocalizedString("Sick", comment: "Sick"), _moodSmileyString: "SmileySick.png"))
        moods.append(Moods(_moodName: NSLocalizedString("Tired", comment: "Tired"), _moodSmileyString: "SmileyTired.png"))
        moods.append(Moods(_moodName: NSLocalizedString("Great", comment: "Great"), _moodSmileyString: "SmileyGreat.png"))
        moods.append(Moods(_moodName: NSLocalizedString("Stressed", comment: "Stressed"), _moodSmileyString: "SmileyStressed.png"))
        moods.append(Moods(_moodName: NSLocalizedString("Fantastic", comment: "Fantastic"), _moodSmileyString: "SmileyFantastic.png"))
        moods.append(Moods(_moodName: NSLocalizedString("K.O.", comment: "K.O."), _moodSmileyString: "SmileyKO.png"))
        
        pickerView.setDate(UserDefaults.standard.object(forKey: "dateUF") as! Date, animated: true)
            pickerView.forBaselineLayout().setValue(UIColor.white, forKeyPath: "tintColor")
        for sub in pickerView.subviews {
            sub.setValue(UIColor.white, forKeyPath: "textColor")
            sub.setValue(UIColor.white, forKey: "tintColor")
        }
        
        pickerTitle.text = NSLocalizedString("Choose a date", comment: "Choose a date")
        
    }
    


    //Hide tutorial by rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if UserDefaults.standard.object(forKey: "tutorialMoods") == nil {
            hideTutorial()
        }
        
    }
    
    // MARK: CollectionView
    // Save selected mood by index
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        selectedIndexPath = indexPath
        
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return moods.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MoodCell
        cell.m_L_moodName.text = moods[(indexPath as NSIndexPath).row].moodName
        cell.m_IV_moodSmiley.image = moods[(indexPath as NSIndexPath).row].moodSmiley
        return cell
        
    }

    // MARK: My Methods
    func hideTutorial(){
        
        self.navigationController?.isNavigationBarHidden = false
        UIView.transition(with: self.view, duration: 1, options: UIViewAnimationOptions.curveLinear, animations: {
            self.tutorialView.alpha = 0;
            }, completion: { finished in
                UserDefaults.standard.set(false, forKey: "tutorialMoods")
                self.tutorialView.removeFromSuperview()
        })
        
    }
    
    //Get the date in a good format
    func returnDateForm(_ date: Date) -> String{
        
        let dateFormatter = DateFormatter()
        let theDateFormat = DateFormatter.Style.short
        let theTimeFormat = DateFormatter.Style.none
        dateFormatter.dateStyle = theDateFormat
        dateFormatter.timeStyle = theTimeFormat
        return dateFormatter.string(from: date)
        
    }
   
    func addNewMood(){
        
        let newItem = NSEntityDescription.insertNewObject(forEntityName: "Mood", into: appdel.managedObjectContext!) as! Mood
        addMood(newItem)
        
    }
    
    func addMood(_ _Object:Mood){
        
        let cell = cvc.cellForItem(at: selectedIndexPath!) as! MoodCell;
        _Object.date = date
        _Object.moodName = cell.m_L_moodName.text!
        _Object.moodImagePath = imagePaths[(selectedIndexPath! as NSIndexPath).row+1]
        
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
    
    func layoutAnimated(_ animated : Bool) {
        
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
