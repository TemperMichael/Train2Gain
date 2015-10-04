//
//  Exercise.swift
//  Train2Gain
//
//  Created by Michael Temper on 29.03.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Exercise)
class Exercise: NSManagedObject {
    
    @NSManaged var weight: NSDecimalNumber
    @NSManaged var sets: NSNumber
    @NSManaged var doneReps: NSNumber
    @NSManaged var reps: NSNumber
    @NSManaged var name: String
    @NSManaged var dayID: String
    
    //m_weight: NSNumber, m_sets: NSNumber, m_doneReps: NSNumber, m_reps:NSNumber, m_name: String, m_dayID:String
    
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

        let entity = NSEntityDescription.entityForName("Exercise", inManagedObjectContext: appdel.managedObjectContext!)!
        self.init(entity: entity, insertIntoManagedObjectContext: appdel.managedObjectContext)
        
        self.weight = 0
        self.sets = 0
        self.doneReps = 0
        self.reps = 0
        self.name = ""
        self.dayID = ""
        
        
    }
}

