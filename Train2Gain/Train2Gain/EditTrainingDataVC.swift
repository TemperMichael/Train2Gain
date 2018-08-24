//
//  EditChooserVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 31.07.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import iAd

class EditTrainingDataVC: UIViewController, ADBannerViewDelegate {
    
    @IBOutlet weak var bodyMeasurementsButton: UIButton!
    @IBOutlet weak var editTitleLabel: UILabel!
    @IBOutlet weak var iAd: ADBannerView!
    @IBOutlet weak var moodButton: UIButton!
    
    // MARK: View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Handle iAd
        iAd.delegate = self
        iAd.isHidden = true
        
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
        
        // Set background
        var backgroundImage = UIImage(named: "Background2.png")
        backgroundImage = imageResize(backgroundImage!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundImage!)
    }
    
    // Show correct background after rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        var backgroundImage = UIImage(named: "Background2.png")
        backgroundImage = imageResize(backgroundImage!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundImage!)
    }
    
    // MARK: Own Methods
    // Resize background image to fit in view
    func imageResize(_ imageObj: UIImage, sizeChange: CGSize) -> UIImage {
        let hasAlpha = false
        let scale: CGFloat = 0.0
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
    }
    
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
    
    // MARK: iAd
    func bannerViewDidLoadAd(_ banner: ADBannerView) {
        self.layoutAnimated(true)
    }
    
    func bannerView(_ banner: ADBannerView, didFailToReceiveAdWithError error: Error) {
        self.layoutAnimated(true)
    }
    
    func bannerViewActionShouldBegin(_ banner: ADBannerView, willLeaveApplication willLeave: Bool) -> Bool {
        return true
    }
    
    func layoutAnimated(_ animated: Bool) {
        if iAd.isBannerLoaded {
            iAd.isHidden = false
            UIView.animate(withDuration: animated ? 0.25 : 0.0, animations: {
                self.iAd.alpha = 1
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
