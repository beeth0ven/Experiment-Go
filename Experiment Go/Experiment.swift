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
    class func insertNewExperimentInManagedObjectContext(managedObjectContext: NSManagedObjectContext) -> Experiment? {
        
        let experiment = NSEntityDescription.insertNewObjectForEntityForName(Constants.EntityNameKey, inManagedObjectContext: managedObjectContext) as! Experiment
        
        
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        //        newManagedObject.setValue(NSDate(), forKey: "timeStamp")
        
        // Save the context.
        do {
            try managedObjectContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
        return experiment
        
    }
    
}
