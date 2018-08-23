//
//  PickDateVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 09.04.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import iAd

class PickDateVC: UIViewController, ADBannerViewDelegate {

    // MARK: IBOutlets & IBActions
    @IBOutlet weak var m_dp_DatePicker: UIDatePicker!
    @IBOutlet weak var iAd: ADBannerView!
    @IBOutlet weak var okButton: UIButton!
    
    @IBAction func okCL(_ sender: AnyObject) {
        
        // Save date
        UserDefaults.standard.set(m_dp_DatePicker.date,forKey: "dateUF")
        self.navigationController?.popViewController(animated: true)
        
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Handle iAd
        iAd.delegate = self
        iAd.isHidden = true
        okButton.layer.borderColor = UIColor.white.cgColor
        
        // Set background
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        self.navigationItem.hidesBackButton = true
        m_dp_DatePicker.setDate(UserDefaults.standard.object(forKey: "dateUF") as! Date, animated: true)
        m_dp_DatePicker.forBaselineLayout().setValue(UIColor.white, forKeyPath: "tintColor")
        for sub in m_dp_DatePicker.subviews {
            sub.setValue(UIColor.white, forKeyPath: "textColor")
            sub.setValue(UIColor.white, forKey: "tintColor")     
        }
 
    }

    //Get date in a good format
    func returnDateForm(_ date: Date) -> String {
        
        let dateFormatter = DateFormatter()
        let theDateFormat = DateFormatter.Style.short
        let theTimeFormat = DateFormatter.Style.none
        dateFormatter.dateStyle = theDateFormat
        dateFormatter.timeStyle = theTimeFormat
        return dateFormatter.string(from: date)
        
    }
    
    // Fit background image to display size
    func imageResize(_ imageObj: UIImage, sizeChange: CGSize) -> UIImage {
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
        
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
    
    // Show correct background after rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
    }
}
