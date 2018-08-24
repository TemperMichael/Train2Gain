//
//  ExercisesTVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 27.03.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import CoreData
import iAd

class TrainingPlansTVC: UIViewController, UITableViewDelegate, UITableViewDataSource, ADBannerViewDelegate {
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var dayIDs: [String] = []
    var exercises: [Exercise] = []
    var selectedDayID: String!
    var selectedExercise: [Exercise] = []
    
    // MARK: IBOutlets & IBActions
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var iAd: ADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Handle iAd
        iAd.delegate = self
        iAd.isHidden = true
        
        // Set background
        var backgroundImage = UIImage(named: "Background2.png")
        backgroundImage = imageResize(backgroundImage!, sizeChange: view.frame.size)
        self.view.backgroundColor = UIColor(patternImage: backgroundImage!)
        
        selectedExercise = []
        
        // Remove text from the back button
        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: self, action: nil)
        backButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Heiti SC", size: 18)!], for: UIControlState())
        navigationItem.backBarButtonItem = backButton
        
        //Hide empty cells
        let backgroundView = UIView(frame: CGRect.zero)
        self.tableView.tableFooterView = backgroundView
        self.tableView.backgroundColor = UIColor(red: 22 / 255 , green: 200 / 255, blue: 255 / 255, alpha: 0)
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Set actual date
        UserDefaults.standard.set(Date(), forKey: "dateUF")
        
        // Reset lists
        dayIDs = []
        selectedExercise = []
        exercises = []
        
        // Hide empty cells
        let backgroundView = UIView(frame: CGRect.zero)
        self.tableView.tableFooterView = backgroundView
        self.tableView.backgroundColor = UIColor(red: 22 / 255, green: 200 / 255, blue: 255 / 255, alpha: 0)
        
        // Get exercises core data
        let  request = NSFetchRequest<NSFetchRequestResult>(entityName: "Exercise")
        exercises = (try! appDelegate.managedObjectContext?.fetch(request))  as! [Exercise]
        var exists = false
        
        // Check if data already exists
        for checkIDAmount in exercises {
            exists = false
            for singleDayId in dayIDs {
                if checkIDAmount.dayID == singleDayId {
                    exists = true
                }
            }
            if !exists {
                dayIDs.append(checkIDAmount.dayID)
            }
        }
        tableView.reloadData()
        tableView.separatorColor = UIColor(red: 22 / 255, green: 204 / 255, blue: 255 / 255, alpha: 1)
        
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
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Save the selected exercises for the next view
        for i in 0  ..< exercises.count {
            if exercises[i].dayID == dayIDs[(indexPath as NSIndexPath).row] {
                selectedExercise.append(exercises[i])
            }
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        // Handle swipe to single tableview row
        // Handle the deletion of an row
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: NSLocalizedString("Delete", comment: "Delete")) { (action, index) -> Void in
            let context: NSManagedObjectContext = self.appDelegate.managedObjectContext!
            var count = self.exercises.count - 1
            for _ in 0..<self.exercises.count  {
                if self.exercises[count].dayID == self.dayIDs[(indexPath as NSIndexPath).row] {
                    context.delete(self.exercises[count] as NSManagedObject)
                    self.exercises.remove(at: count)
                    count = count - 1
                }
            }
            self.dayIDs.remove(at: (indexPath as NSIndexPath).row)
            do {
                try context.save()
            } catch _ {
            }
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        deleteAction.backgroundColor = UIColor(red: 86 / 255, green: 158 / 255, blue: 197 / 255, alpha: 1)
        
        
        // Handle the changings of the selected row item
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: NSLocalizedString("Edit", comment: "Edit")) { (action, index) -> Void in
            for i in  0..<self.exercises.count {
                if self.exercises[i].dayID == self.dayIDs[(indexPath as NSIndexPath).row] {
                    self.selectedExercise.append(self.exercises[i])
                }
            }
            self.performSegue(withIdentifier: "AddExercise", sender: UITableViewRowAction())
        }
        editAction.backgroundColor = UIColor(red: 112 / 255, green: 188 / 255, blue: 224 / 255, alpha: 1)
        return [deleteAction, editAction]
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Give the next view the selected exercises
        if segue.identifier == "ExerciseChosen" {
            let vc = segue.destination as! TrainingModeVC
            vc.selectedExercise = selectedExercise
        }
        if segue.identifier == "AddExercise" {
            if let _ = sender as? UITableViewRowAction {
                let vc = segue.destination as! TrainingPlanCreationVC
                vc.editMode = true
                vc.selectedExercise = self.selectedExercise
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        // Has to be here so custom action can be used
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dayIDs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Setup cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExerciseCell", for: indexPath) 
        cell.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 18)
        cell.textLabel?.textColor = UIColor(red: 22 / 255, green: 204 / 255, blue: 255 / 255, alpha: 1)
        cell.textLabel?.text = dayIDs[(indexPath as NSIndexPath).row]
        cell.backgroundColor = UIColor.white
        
        //Set Seperator left to zero
        cell.separatorInset = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsets.zero
        return cell
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
    
    // Show correct background after rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        var backgroundImage = UIImage(named: "Background2.png")
        backgroundImage = imageResize(backgroundImage!, sizeChange: size)
        self.view.backgroundColor = UIColor(patternImage: backgroundImage!)
    }
    
}
