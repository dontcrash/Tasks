//File: Order+CoreDataProperties.swift
//Project: PizzaRestaurantApp

//Created at 31.12.19 by BLCKBIRDS
//Visit www.BLCKBIRDS.com for more.
//

import Foundation
import CoreData


extension Task: Identifiable {

    @nonobjc public class func taskFetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var id: String
    @NSManaged public var title: String
    @NSManaged public var summary: String
    @NSManaged public var due: Date
    @NSManaged public var done: Bool
    @NSManaged public var manual: Bool

}
