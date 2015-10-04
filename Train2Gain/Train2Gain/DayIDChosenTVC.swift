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
    
    var selectedDayDetails : [String] = []
    var doneExercises : [DoneExercise] = []
    var setCountValues : [String] = []
    
    var weightUnit: String! = NSUserDefaults.standardUserDefaults().objectForKey("weightUnit")! as! String


   
       override func viewDidLoad() {
        super.viewDidLoad()
        let backgroundView = UIView(frame: CGRectZero)
        self.tableView.tableFooterView = backgroundView
        self.tableView.backgroundColor = UIColor(red:22/255 ,green:200/255, blue:1.00 ,alpha: 1)
       
              let appdel =  UIApplication.sharedApplication().delegate as! AppDelegate
        let  requestDoneEx = NSFetchRequest(entityName: "DoneExercise")
        let doneEx = (try! appdel.managedObjectContext?.executeFetchRequest(requestDoneEx))  as! [DoneExercise]
        
        self.title = "\(selectedDayDetails[0])"
      
        var checkString = ""
        var checkBefore = ""
        var counter = 2;
        
        //Get done exercises of this day
        for singleEx in doneEx{
            checkBefore=checkString
            if(singleEx.dayID == selectedDayDetails[0] && returnDateForm(singleEx.date) == selectedDayDetails [1]){
                checkString = singleEx.name
                
                doneExercises.append(singleEx)
                
                if(checkString == checkBefore){
                   setCountValues.append("\(counter)")
                    counter++;
                }else{
                    setCountValues.append("1")

                    counter = 2
                }
                
            }
        }
      
        
    }
    
    override func viewDidDisappear(animated: Bool) {
         let appdel =  UIApplication.sharedApplication().delegate as! AppDelegate
        appdel.rollBackContext()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return doneExercises.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("OwnCell", forIndexPath: indexPath) as! DayIDChosenCell
    
        var weight = (doneExercises[indexPath.row].weight).doubleValue
        
        //Calculation for actual chosen unit
        if(weightUnit == "lbs"){
            weight = weight * 2.20462262185
        }
        //Setup cells
        cell.m_L_Name.text = doneExercises[indexPath.row].name
        cell.m_L_Reps.text = "\(doneExercises[indexPath.row].reps)"
        cell.m_L_DoneReps.text = "\(doneExercises[indexPath.row].doneReps)"
        cell.m_L_Weight.text = NSString(format: "%.2f",weight) as String
        
        if(weight<1000){
             cell.m_L_Weight.text = NSString(format: "%.2f",weight) as String
        }else if(weight < 10000){
            cell.m_L_Weight.text = NSString(format: "%.1f",weight) as String
        }else{
            
           cell.m_L_Weight.text = NSString(format: "%.0f",weight) as String
        }
        
        if(weight == 0){
            
            cell.m_L_Weight.text = "0"
        }
        cell.m_L_setCount.text = "\(setCountValues[indexPath.row]).Set"
        cell.m_L_WeightUnit.text = weightUnit
        
        //Set seperators to the left side
        cell.separatorInset = UIEdgeInsetsZero
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsetsZero
        
        
        return cell
    }
    
    //Get the date in a good format
    func returnDateForm(date:NSDate) -> String{
        
        let dateFormatter = NSDateFormatter()
        
        let theDateFormat = NSDateFormatterStyle.ShortStyle
        let theTimeFormat = NSDateFormatterStyle.NoStyle
        
        dateFormatter.dateStyle = theDateFormat
        dateFormatter.timeStyle = theTimeFormat
        
        return dateFormatter.stringFromDate(date)
    }
    
}
