//
//  DoneExercise.swift
//  Train2Gain
//
//  Created by Michael Temper on 07.04.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import Foundation
import CoreData
import UIKit


@objc(DoneExercise)
class DoneExercise: NSManagedObject {
    
    @NSManaged var dayID: String
    @NSManaged var name: String
    @NSManaged var reps: NSNumber
    @NSManaged var sets: NSNumber
    @NSManaged var setCounter: NSNumber
    @NSManaged var doneReps: NSNumber
    @NSManaged var weight: NSDecimalNumber
    @NSManaged var date: NSDate
    
    convenience init() {
        
        var appdel =  UIApplication.sharedApplication().delegate as! AppDelegate
        var managedObjectContext: NSManagedObjectContext? = {
            let coordinator = appdel.persistentStoreCoordinator;
            if coordinator == nil{
                return nil
            }
            var managedObjectContext = NSManagedObjectContext()
            managedObjectContext.persistentStoreCoordinator = coordinator
            return managedObjectContext
            
            }()
        
        let entity = NSEntityDescription.entityForName("DoneExercise", inManagedObjectContext: appdel.managedObjectContext!)!
        self.init(entity: entity, insertIntoManagedObjectContext: appdel.managedObjectContext)
        
        self.weight = 0
        self.sets = 0
        self.doneReps = 0
        self.reps = 0
        self.name = ""
        self.dayID = ""
        self.setCounter = 0
        self.date = NSUserDefaults.standardUserDefaults().objectForKey("dateUF") as! NSDate
        
        
    }
    
}
