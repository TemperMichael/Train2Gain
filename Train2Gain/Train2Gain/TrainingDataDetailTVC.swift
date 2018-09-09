//
//  TrainingDataDetailTVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 27.04.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import CoreData

class TrainingDataDetailTVC: UITableViewController {
    
    var doneExercises: [DoneExercise] = []
    var cellIdentifier = "TrainingDataDetailCell"
    var selectedDayDetails: [String] = []
    var setCountValues: [String] = []
    var weightUnit = ""
    
    // MARK: View Methods
    func setupView() {
        let backgroundView = UIView(frame: CGRect.zero)
        self.tableView.tableFooterView = backgroundView
        self.tableView.backgroundColor = UIColor(red: 37 / 255, green: 190 / 255, blue: 254 / 255, alpha: 1)
        self.title = "\(selectedDayDetails[0])"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        weightUnit = UserDefaults.standard.object(forKey: "weightUnit") as? String ?? ""
        
        setupView()
        setupDoneTrainingData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        guard let unwrappedAppDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        unwrappedAppDelegate.rollBackContext()
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TrainingDataDetailCell else {
            return UITableViewCell()
        }
        setupCell(indexPath, cell)
        return cell
    }
    
    // MARK: Own Methods
    
    func setupDoneTrainingData() {
        guard let unwrappedAppDelegate =  UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let requestDoneExercises = NSFetchRequest<NSFetchRequestResult>(entityName: "DoneExercise")
        do {
            guard let savedDoneExercises = try unwrappedAppDelegate.managedObjectContext?.fetch(requestDoneExercises) as? [DoneExercise] else {
                return
            }
            var checkString = ""
            var checkBefore = ""
            var setCounter = 0
            
            // Get done exercises of this day
            for singleExercise in savedDoneExercises {
                checkBefore = checkString
                if singleExercise.dayID == selectedDayDetails[0] && DateFormatHelper.returnDateForm(singleExercise.date) == selectedDayDetails [1] {
                    checkString = singleExercise.name
                    doneExercises.append(singleExercise)
                    if checkString == checkBefore {
                        setCountValues.append("\(setCounter)")
                        setCounter += 1
                    } else {
                        setCountValues.append("1")
                        setCounter = 2
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    func setupCell(_ indexPath: IndexPath, _ cell: TrainingDataDetailCell) {
        // Calculation for actual chosen unit
        var weight = (doneExercises[(indexPath as NSIndexPath).row].weight).doubleValue
        if weightUnit == "lbs" {
            weight = weight * 2.20462262185
        }
        
        cell.trainingDataTrainingPlanNameLabel.text = doneExercises[(indexPath as NSIndexPath).row].name
        cell.trainingDataRepsLabel.text = "\(doneExercises[(indexPath as NSIndexPath).row].reps)"
        cell.trainingDataDoneRepsLabel.text = "\(doneExercises[(indexPath as NSIndexPath).row].doneReps)"
        cell.trainingDataWeightLabel.text = NSString(format: "%.2f", weight) as String
        
        if weight < 1000 {
            cell.trainingDataWeightLabel.text = NSString(format: "%.2f",weight) as String
        } else if weight < 10000 {
            cell.trainingDataWeightLabel.text = NSString(format: "%.1f", weight) as String
        } else {
            cell.trainingDataWeightLabel.text = NSString(format: "%.0f", weight) as String
        }
        
        if weight == 0 {
            cell.trainingDataWeightLabel.text = "0"
        }
        
        let translationSet = NSLocalizedString("Set", comment: "Set")
        cell.trainingDataSetLabel.text = "\(setCountValues[(indexPath as NSIndexPath).row]).\(translationSet)"
        cell.trainingDataWeightUnitLabel.text = weightUnit
        
        //Set seperators to the left side
        cell.separatorInset = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsets.zero
    }
    
}
