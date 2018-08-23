//
//  Measurements.swift
//  Train2Gain
//
//  Created by Michael Temper on 09.04.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import Foundation
import CoreData
@objc(Measurements)
class Measurements: NSManagedObject {

    @NSManaged var weight: NSDecimalNumber
    @NSManaged var chest: NSDecimalNumber
    @NSManaged var arm: NSDecimalNumber
    @NSManaged var waist: NSDecimalNumber
    @NSManaged var leg: NSDecimalNumber
    @NSManaged var date: Date

}
