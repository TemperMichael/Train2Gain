//
//  Mood.swift
//  Train2Gain
//
//  Created by Michael Temper on 26.04.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import Foundation
import CoreData

@objc(Mood)
class Mood : NSManagedObject {

    @NSManaged var moodImagePath: String
    @NSManaged var moodName: String
    @NSManaged var date: Date

}
