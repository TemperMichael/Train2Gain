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

class MoodCVC: UIViewController {
    
    var appDelegate: AppDelegate?
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
    let cellIdentifier = "MoodCell"
    var date: Date?
    var imagePaths: [String] = ["SmileyNormal.png", "SmileyNormal.png", "SmileyGood.png", "SmileyAggressive.png", "SmileyAwesome.png", "SmileySad.png", "SmileyIrritated.png", "SmileySick.png", "SmileyTired.png", "SmileyGreat.png", "SmileyStressed.png", "SmileyFantastic.png", "SmileyKO.png"]
    var moods: [Moods] = []
    var selectedIndexPath: IndexPath?
    
    // MARK: IBOutlets & IBActions
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datePickerBackgroundView: UIView!
    @IBOutlet weak var datePickerButton: UIButton!
    @IBOutlet weak var datePickerTitleLabel: UILabel!
    @IBOutlet weak var moodCollectionView: UICollectionView!
    @IBOutlet weak var selectDateButton: UIButton!
    
    @IBAction func pickDate(_ sender: AnyObject) {
        PickerViewHelper.setupPickerViewBackground(blurView, datePickerBackgroundView)
        PickerViewHelper.bringPickerToFront(datePickerBackgroundView, datePicker, selectDateButton, datePickerTitleLabel)
    }
    
    @IBAction func saveMood(_ sender: AnyObject) {
        if selectedIndexPath != nil {
            
            //Get the saved moods
            let requestMood = NSFetchRequest<NSFetchRequestResult>(entityName: "Mood")
            
            guard let unwrappedAppDelegate = appDelegate, let unwrappedManagedObjectContext = unwrappedAppDelegate.managedObjectContext, let savedDate = UserDefaults.standard.object(forKey: "dateUF") as? Date  else {
                return
            }
            
            do {
                guard  let savedMoods = try unwrappedManagedObjectContext.fetch(requestMood) as? [Mood] else {
                    return
                }
                saveMoodCorrectly(savedMoods)
            } catch {
                print(error)
            }
            
            date = savedDate
            

            //Save context
            unwrappedAppDelegate.saveContext()
            
            guard let unwrappedSelectedIndexPath = selectedIndexPath, let cell = moodCollectionView.cellForItem(at: unwrappedSelectedIndexPath) as? MoodCell else {
                return
            }
            
            //Fabric - Analytic Tool
            Answers.logContentView(withName: "Mood",
                                   contentType: "Saved data",
                                   contentId: cell.moodNameLabel.text ?? "",
                                   customAttributes: [:])
            
            AlertFormatHelper.showInfoAlert(self, "Your mood was saved.")
        }
        
    }
    
    @IBAction func selectDate(_ sender: AnyObject) {
        date = DateFormatHelper.setDate(datePicker.date, datePickerButton)
        PickerViewHelper.hidePickerView(datePickerBackgroundView)
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
    
    override func viewDidAppear(_ animated: Bool) {
        guard let savedDate = UserDefaults.standard.object(forKey: "dateUF") as? Date else {
            return
        }
        datePickerButton.setTitle(DateFormatHelper.returnDateForm(savedDate), for: UIControlState())
        date = savedDate
    }
    
    // MARK: View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate =  UIApplication.shared.delegate as? AppDelegate
        
        moodCollectionView.delegate = self
        moodCollectionView.dataSource = self
        
        setupMoods()
        PickerViewHelper.setupPickerView(datePicker, datePickerTitleLabel)
    }
    
    // MARK: Own Methods
    
    func addNewMood(){
        guard let unwrappedAppDelegate = appDelegate, let unwrappedManagedObjectContext = unwrappedAppDelegate.managedObjectContext, let newItem = NSEntityDescription.insertNewObject(forEntityName: "Mood", into: unwrappedManagedObjectContext) as? Mood else {
            return
        }
        addMood(newItem)
    }
    
    func addMood(_ _Object:Mood){
        guard let unwrappedSelectedIndexPath = selectedIndexPath, let cell = moodCollectionView.cellForItem(at: unwrappedSelectedIndexPath) as? MoodCell, let unwrappedDate = date else {
            return
        }
        _Object.date = unwrappedDate
        _Object.moodName = cell.moodNameLabel.text ?? ""
        _Object.moodImagePath = imagePaths[(unwrappedSelectedIndexPath as NSIndexPath).row + 1]
    }
    
    func setupMoods() {
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
    
    func saveMoodCorrectly(_ savedMoods: [Mood]) {
        //Either create a new mood entry or rewrite the todays one
        if savedMoods.count <= 0 {
            addNewMood()
        } else {
            let lastMeasure = savedMoods[savedMoods.count - 1]
            if DateFormatHelper.returnDateForm(lastMeasure.date) != DateFormatHelper.returnDateForm(Date()) {
                addNewMood()
            } else {
                addMood(lastMeasure)
            }
        }
    }
    
}

// MARK: CollectionView

extension MoodCVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
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
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? MoodCell else {
            return UICollectionViewCell()
        }
        cell.moodNameLabel.text = moods[(indexPath as NSIndexPath).row].moodName
        cell.moodImageView.image = moods[(indexPath as NSIndexPath).row].moodSmiley
        return cell
    }
    
}
