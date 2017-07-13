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
    
    
    convenience init() {
        
        let appdel =  UIApplication.shared.delegate as! AppDelegate
        var managedObjectContext: NSManagedObjectContext? = {
            let coordinator = appdel.persistentStoreCoordinator;
            if coordinator == nil{
                return nil
            }
            let managedObjectContext = NSManagedObjectContext()
            managedObjectContext.persistentStoreCoordinator = coordinator
            return managedObjectContext
            
            }()

        let entity = NSEntityDescription.entity(forEntityName: "Exercise", in: appdel.managedObjectContext!)!
        self.init(entity: entity, insertInto: appdel.managedObjectContext)
        
        self.weight = 0
        self.sets = 0
        self.doneReps = 0
        self.reps = 0
        self.name = ""
        self.dayID = ""
        
        
    }
}

