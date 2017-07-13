//
//  EditChooserVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 31.07.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import iAd

class EditChooserVC: UIViewController, ADBannerViewDelegate {

    @IBOutlet weak var bmButton: UIButton!
    @IBOutlet weak var moodButton: UIButton!
    @IBOutlet weak var changeLabel: UILabel!
    @IBOutlet weak var iAd: ADBannerView!
    
    // MARK: View Methods
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Handle iAd
        iAd.delegate = self
        iAd.isHidden = true
        
        // Remove text from back button
        let backButton = UIBarButtonItem(title: " ", style: UIBarButtonItemStyle.plain, target: self, action: nil)
        backButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Chalkduster", size: 20)!], for: UIControlState())
        navigationItem.backBarButtonItem = backButton

        // Set bordercolor of buttons
        bmButton.layer.borderColor = UIColor.white.cgColor
        moodButton.layer.borderColor = UIColor.white.cgColor
        
        // Set title with correct chosen date
        let chosendate = UserDefaults.standard.object(forKey: "dateUF") as! Date
        
        let translationChangeDataOf = NSLocalizedString("Change data of", comment: "Change data of")
        changeLabel.text = "\(translationChangeDataOf) \(returnDateForm(chosendate))"
        
        // Set background
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)

    }
    
    
    // Show correct background after rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
    }
    
    // MARK: My Methods
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
        
        if let btn = sender as? UIButton {
            if btn == bmButton {
             let vc = segue.destination as! MeasureVC
                vc.editMode = true
            }
            if btn == moodButton {
                let cvc = segue.destination as! MoodCVC
                cvc.editMode = true
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
    func bannerViewDidLoadAd(_ banner: ADBannerView!) {
        
        self.layoutAnimated(true)
        
    }
    
    func bannerView(_ banner: ADBannerView!, didFailToReceiveAdWithError error: Error!) {
        
        self.layoutAnimated(true)
        
    }
    
    func bannerViewActionShouldBegin(_ banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        
        return true
        
    }
    
    func layoutAnimated(_ animated: Bool) {

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
