//
//  TrainingPlansVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 27.03.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import CoreData

class TrainingPlansVC: UIViewController {
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var dayIDs: [String] = []
    var savedExercises: [Exercise] = []
    var selectedDayID: String!
    var selectedExercises: [Exercise] = []
    var trainingPlanCell = "TrainingPlanCell"
    
    // MARK: IBOutlets & IBActions
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        selectedExercises = []
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Set actual date
        UserDefaults.standard.set(Date(), forKey: "dateUF")
        
        // Reset lists
        dayIDs = []
        selectedExercises = []
        savedExercises = []
        
        setupDayIds()
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Give the next view the selected exercises
        if segue.identifier == "TrainingPlanChosen" {
            let trainingModeViewController = segue.destination as! TrainingModeVC
            trainingModeViewController.selectedExercise = selectedExercises
        }
        if segue.identifier == "AddTrainingPlan" {
            if let _ = sender as? UITableViewRowAction {
                let trainingPlanCreationViewController = segue.destination as! TrainingPlanCreationVC
                trainingPlanCreationViewController.editMode = true
                trainingPlanCreationViewController.selectedExercise = self.selectedExercises
            }
        }
    }
    
    // MARK: Own Methods

    func setupDayIds() {
        // Get exercises core data
        let  request = NSFetchRequest<NSFetchRequestResult>(entityName: "Exercise")
        savedExercises = (try! appDelegate.managedObjectContext?.fetch(request))  as! [Exercise]
        var alreadyExists = false
        
        // Check if data already exists
        for checkIDAmount in savedExercises {
            alreadyExists = false
            for singleDayId in dayIDs {
                if checkIDAmount.dayID == singleDayId {
                    alreadyExists = true
                }
            }
            if !alreadyExists {
                dayIDs.append(checkIDAmount.dayID)
            }
        }
    }
    
    func prepareSelectedExercises(_ indexPath: IndexPath) {
        for i in 0  ..< savedExercises.count {
            if savedExercises[i].dayID == dayIDs[(indexPath as NSIndexPath).row] {
                selectedExercises.append(savedExercises[i])
            }
        }
    }
    
    func setupDeleteAction(_ indexPath: IndexPath) -> UITableViewRowAction {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: NSLocalizedString("Delete", comment: "Delete")) { (action, index) -> Void in
            let context: NSManagedObjectContext = self.appDelegate.managedObjectContext!
            var count = self.savedExercises.count - 1
            for _ in 0..<self.savedExercises.count  {
                if self.savedExercises[count].dayID == self.dayIDs[(indexPath as NSIndexPath).row] {
                    context.delete(self.savedExercises[count] as NSManagedObject)
                    self.savedExercises.remove(at: count)
                    count = count - 1
                }
            }
            self.dayIDs.remove(at: (indexPath as NSIndexPath).row)
            do {
                try context.save()
            } catch _ {
                print("Error save context training plans")
            }
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        deleteAction.backgroundColor = UIColor(red: 86 / 255, green: 158 / 255, blue: 197 / 255, alpha: 1)
        return deleteAction
    }
    
    func setupEditAction(_ indexPath: IndexPath) -> UITableViewRowAction {
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: NSLocalizedString("Edit", comment: "Edit")) { (action, index) -> Void in
            for i in  0..<self.savedExercises.count {
                if self.savedExercises[i].dayID == self.dayIDs[(indexPath as NSIndexPath).row] {
                    self.selectedExercises.append(self.savedExercises[i])
                }
            }
            self.performSegue(withIdentifier: "AddTrainingPlan", sender: UITableViewRowAction())
        }
        editAction.backgroundColor = UIColor(red: 112 / 255, green: 188 / 255, blue: 224 / 255, alpha: 1)
        return editAction
    }
    
    func setupCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: trainingPlanCell, for: indexPath)
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
    
}

// MARK: TableView

extension TrainingPlansVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        prepareSelectedExercises(indexPath)
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        // Handle swipe to single tableview row
        // Handle the deletion of an row
        let deleteAction = setupDeleteAction(indexPath)
        
        // Handle the changings of the selected row item
        let editAction = setupEditAction(indexPath)
        return [deleteAction, editAction]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dayIDs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return setupCell(tableView, indexPath)
    }
    
}
