//
//  Experiment.swift
//  Experiment Go
//
//  Created by luojie on 7/17/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CoreData

//@objc(Experiment)
class Experiment: Root {
    
    struct Constants {
        static let  EntityNameKey = "Experiment"
        static let  TitleKey = "title"
        static let  BodyKey = "body"
        static let  PropertyKey = "Property"
        
    }
    
    // Insert code here to add functionality to your managed object subclass
    class func insertNewExperiment() -> Experiment! {
        let context = NSManagedObjectContext.defaultContext()
        let experiment = NSEntityDescription.insertNewObjectForEntityForName(Constants.EntityNameKey, inManagedObjectContext: context) as! Experiment
        experiment.title = "Hallo"
        return experiment
    }
    
}
