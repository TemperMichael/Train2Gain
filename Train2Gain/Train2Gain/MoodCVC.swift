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

class MoodCVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var appdel = UIApplication.shared.delegate as! AppDelegate
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
    var date: Date!
    var editMode = false
    var imagePaths: [String] = ["SmileyNormal.png", "SmileyNormal.png", "SmileyGood.png", "SmileyAggressive.png", "SmileyAwesome.png", "SmileySad.png", "SmileyIrritated.png", "SmileySick.png", "SmileyTired.png", "SmileyGreat.png", "SmileyStressed.png", "SmileyFantastic.png", "SmileyKO.png"]
    var moods: [Moods] = []
    let reuseIdentifier = "MoodCell"
    var selectedIndexPath: IndexPath?
    
    // MARK: IBOutlets & IBActions
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datePickerBackground: UIView!
    @IBOutlet weak var datePickerButton: UIButton!
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var moodCollectionView: UICollectionView!
    @IBOutlet weak var pickerTitleLabel: UILabel!
    
    @IBAction func pickDate(_ sender: AnyObject) {
        setupPickerView()
    }
    
    @IBAction func saveMood(_ sender: AnyObject) {
        if selectedIndexPath != nil {
            //Check if today an mood was already chosen to rewrite it if it already exists
            var alreadyExists = true
            
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
            let cell = moodCollectionView.cellForItem(at: selectedIndexPath!) as! MoodCell
            
            //Fabric - Analytic Tool
            Answers.logContentView(withName: "Mood",
                                   contentType: "Saved data",
                                   contentId: cell.moodNameLabel.text!,
                                   customAttributes: [:])
            
            present(informUser, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func selectedDate(_ sender: AnyObject) {
        // Save date
        date = datePicker.date
        UserDefaults.standard.set(datePicker.date,forKey: "dateUF")
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.datePickerBackground.alpha = 0
        }, completion: { finished in
            self.datePickerBackground.isHidden = true
        })
        datePickerButton.setTitle(returnDateForm(date), for: UIControlState())
    }
    
    @IBAction func showNextDay(_ sender: AnyObject) {
        //Go to next day
        date = date.addingTimeInterval(60 * 60 * 24)
        UserDefaults.standard.set(date , forKey: "dateUF")
        datePickerButton.setTitle(returnDateForm(date), for: UIControlState())
    }
    
    @IBAction func showPreviousDay(_ sender: AnyObject) {
        //Go to prevoius day
        date = date.addingTimeInterval(-60 * 60 * 24)
        UserDefaults.standard.set(date, forKey: "dateUF")
        datePickerButton.setTitle(returnDateForm(date), for: UIControlState())
    }
    
    override func viewDidAppear(_ animated: Bool) {
        date = UserDefaults.standard.object(forKey: "dateUF") as! Date
        datePickerButton.setTitle(returnDateForm(date), for: UIControlState())
    }
    
    // MARK: View methods
    fileprivate func setupMoods() {
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        moodCollectionView.delegate = self
        moodCollectionView.dataSource = self
        
        setupMoods()
        
        datePicker.setDate(UserDefaults.standard.object(forKey: "dateUF") as! Date, animated: true)
        datePicker.forBaselineLayout().setValue(UIColor.white, forKeyPath: "tintColor")
        for sub in datePicker.subviews {
            sub.setValue(UIColor.white, forKeyPath: "textColor")
            sub.setValue(UIColor.white, forKey: "tintColor")
        }
        pickerTitleLabel.text = NSLocalizedString("Choose a date", comment: "Choose a date")
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
        cell.moodNameLabel.text = moods[(indexPath as NSIndexPath).row].moodName
        cell.moodImageView.image = moods[(indexPath as NSIndexPath).row].moodSmiley
        return cell
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
        let cell = moodCollectionView.cellForItem(at: selectedIndexPath!) as! MoodCell
        _Object.date = date
        _Object.moodName = cell.moodNameLabel.text!
        _Object.moodImagePath = imagePaths[(selectedIndexPath! as NSIndexPath).row + 1]
    }
    
    func setupPickerView() {
        blurView.frame = datePickerBackground.bounds
        blurView.translatesAutoresizingMaskIntoConstraints = false
        if !datePickerBackground.subviews.contains(blurView) {
            datePickerBackground.addSubview(blurView)
            datePickerBackground.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: datePickerBackground, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0.0))
            datePickerBackground.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: datePickerBackground, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0.0))
            datePickerBackground.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: datePickerBackground, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0.0))
            datePickerBackground.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: datePickerBackground, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0.0))
        }
        datePickerBackground.alpha = 0
        datePickerBackground.isHidden = false
        self.view.bringSubview(toFront: datePickerBackground)
        datePickerBackground.bringSubview(toFront: datePicker)
        datePickerBackground.bringSubview(toFront: finishButton)
        datePickerBackground.bringSubview(toFront: pickerTitleLabel)
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.datePickerBackground.alpha = 1
        }, completion: { finished in
        })
    }
    
}
