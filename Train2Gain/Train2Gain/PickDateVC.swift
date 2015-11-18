//
//  PickDateVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 09.04.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import iAd

class PickDateVC: UIViewController, ADBannerViewDelegate{

    @IBOutlet weak var m_dp_DatePicker: UIDatePicker!
    
    @IBOutlet weak var iAd: ADBannerView!
    
    @IBOutlet weak var okButton: UIButton!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //Handle iAd
        iAd.delegate = self
        iAd.hidden = true
        
        okButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        //Set background
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)


        self.navigationItem.hidesBackButton = true
        
        m_dp_DatePicker.setDate(NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate, animated: true)
        
        m_dp_DatePicker.viewForBaselineLayout().setValue(UIColor.whiteColor(), forKeyPath: "tintColor")
        
        for sub in m_dp_DatePicker.subviews{
            sub.setValue(UIColor.whiteColor(), forKeyPath: "textColor")
            sub.setValue(UIColor.whiteColor(), forKey: "tintColor")     
        }
 
    }
    
    
   

    @IBAction func okCL(sender: AnyObject) {
       //Save date
        NSUserDefaults.standardUserDefaults().setObject(m_dp_DatePicker.date,forKey: "dateUF")
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    //Get date in a good format
    func returnDateForm(date:NSDate) -> String{
        let dateFormatter = NSDateFormatter()
        
        let theDateFormat = NSDateFormatterStyle.ShortStyle
        let theTimeFormat = NSDateFormatterStyle.NoStyle
        
        dateFormatter.dateStyle = theDateFormat
        dateFormatter.timeStyle = theTimeFormat
        
        return dateFormatter.stringFromDate(date)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    //Show correct background after rotation
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
    }
    


}
