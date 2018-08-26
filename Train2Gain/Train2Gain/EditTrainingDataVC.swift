//
//  EditChooserVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 31.07.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit

class EditTrainingDataVC: UIViewController {
    
    // MARK: IBOutlets & IBActions
    @IBOutlet weak var bodyMeasurementsButton: UIButton!
    @IBOutlet weak var editTitleLabel: UILabel!
    @IBOutlet weak var moodButton: UIButton!
    
    // MARK: View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Remove text from back button
        let backButton = UIBarButtonItem(title: " ", style: UIBarButtonItemStyle.plain, target: self, action: nil)
        backButton.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "Chalkduster", size: 20)!], for: UIControlState())
        navigationItem.backBarButtonItem = backButton
        
        // Set bordercolor of buttons
        bodyMeasurementsButton.layer.borderColor = UIColor.white.cgColor
        moodButton.layer.borderColor = UIColor.white.cgColor
        
        // Set title with correct chosen date
        let chosendate = UserDefaults.standard.object(forKey: "dateUF") as! Date
        
        let translationChangeDataOf = NSLocalizedString("Change data of", comment: "Change data of")
        editTitleLabel.text = "\(translationChangeDataOf) \(returnDateForm(chosendate))"
    }
    
    // MARK: Own Methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let button = sender as? UIButton {
            if button == bodyMeasurementsButton {
                let bodyMeasurementsViewController = segue.destination as! BodyMeasurementsVC
                bodyMeasurementsViewController.editMode = true
            }
            if button == moodButton {
                let moodCollectionViewController = segue.destination as! MoodCVC
                moodCollectionViewController.editMode = true
            }
        }
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
    
}
