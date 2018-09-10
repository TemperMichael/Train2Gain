//
//  EditTrainingDataVC.swift
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
        
        // Set bordercolor of buttons
        bodyMeasurementsButton.layer.borderColor = UIColor.white.cgColor
        moodButton.layer.borderColor = UIColor.white.cgColor
        
        // Set title with correct chosen date
        guard let chosendate = UserDefaults.standard.object(forKey: "dateUF") as? Date else {
            return
        }
        
        let translationChangeDataOf = NSLocalizedString("Change data of", comment: "Change data of")
        editTitleLabel.text = "\(translationChangeDataOf) \(DateFormatHelper.returnDateForm(chosendate))"
    }
    
    // MARK: Own Methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let button = sender as? UIButton {
            if button == bodyMeasurementsButton {
                guard let bodyMeasurementsViewController = segue.destination as? BodyMeasurementsVC else {
                    return
                }
                bodyMeasurementsViewController.editMode = true
            }
        }
    }
    
}
