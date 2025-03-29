//
//  ActivityItem+CoreDataProperties.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//
//

import Foundation
import CoreData


extension ActivityItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ActivityItem> {
        return NSFetchRequest<ActivityItem>(entityName: "ActivityItem")
    }

    @NSManaged public var color: String?
    @NSManaged public var name: String?
    @NSManaged public var id: UUID?

}

extension ActivityItem : Identifiable {

}
