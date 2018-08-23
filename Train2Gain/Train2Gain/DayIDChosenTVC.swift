//
//  DayIDChosenTVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 27.04.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import CoreData

class DayIDChosenTVC: UITableViewController {
    
    var selectedDayDetails: [String] = []
    var doneExercises: [DoneExercise] = []
    var setCountValues: [String] = []
    var weightUnit = UserDefaults.standard.object(forKey: "weightUnit")! as! String
    
    // MARK: View Methods
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Set background
        let backgroundView = UIView(frame: CGRect.zero)
        self.tableView.tableFooterView = backgroundView
        self.tableView.backgroundColor = UIColor(red: 22 / 255, green: 200 / 255, blue: 1.00, alpha: 1)
        
        let appdel =  UIApplication.shared.delegate as! AppDelegate
        let requestDoneEx = NSFetchRequest<NSFetchRequestResult>(entityName: "DoneExercise")
        let doneEx = (try! appdel.managedObjectContext?.fetch(requestDoneEx)) as! [DoneExercise]
        self.title = "\(selectedDayDetails[0])"
        var checkString = ""
        var checkBefore = ""
        var counter = 2
        
        // Get done exercises of this day
        for singleEx in doneEx {
            checkBefore = checkString
            if singleEx.dayID == selectedDayDetails[0] && returnDateForm(singleEx.date) == selectedDayDetails [1] {
                checkString = singleEx.name
                doneExercises.append(singleEx)
                if checkString == checkBefore {
                   setCountValues.append("\(counter)")
                    counter += 1;
                } else {
                    setCountValues.append("1")
                    counter = 2
                }
            }
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        let appdel =  UIApplication.shared.delegate as! AppDelegate
        appdel.rollBackContext()
        
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return doneExercises.count
        
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "OwnCell", for: indexPath) as! DayIDChosenCell
        var weight = (doneExercises[(indexPath as NSIndexPath).row].weight).doubleValue
        
        // Calculation for actual chosen unit
        if weightUnit == "lbs" {
            weight = weight * 2.20462262185
        }
        
        // Setup cells
        cell.m_L_Name.text = doneExercises[(indexPath as NSIndexPath).row].name
        cell.m_L_Reps.text = "\(doneExercises[(indexPath as NSIndexPath).row].reps)"
        cell.m_L_DoneReps.text = "\(doneExercises[(indexPath as NSIndexPath).row].doneReps)"
        cell.m_L_Weight.text = NSString(format: "%.2f", weight) as String
        
        if weight < 1000 {
             cell.m_L_Weight.text = NSString(format: "%.2f",weight) as String
        } else if weight < 10000 {
            cell.m_L_Weight.text = NSString(format: "%.1f", weight) as String
        } else {
           cell.m_L_Weight.text = NSString(format: "%.0f", weight) as String
        }
        if weight == 0 {
            cell.m_L_Weight.text = "0"
        }
        
        let translationSet = NSLocalizedString("Set", comment: "Set")
        cell.m_L_setCount.text = "\(setCountValues[(indexPath as NSIndexPath).row]).\(translationSet)"
        cell.m_L_WeightUnit.text = weightUnit
        
        //Set seperators to the left side
        cell.separatorInset = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsets.zero
        return cell
        
    }
    
    // MARK: My Methods
    // Get the date in a good format
    func returnDateForm(_ date:Date) -> String{
        
        let dateFormatter = DateFormatter()
        let theDateFormat = DateFormatter.Style.short
        let theTimeFormat = DateFormatter.Style.none
        dateFormatter.dateStyle = theDateFormat
        dateFormatter.timeStyle = theTimeFormat
        return dateFormatter.string(from: date)
        
    }
}
