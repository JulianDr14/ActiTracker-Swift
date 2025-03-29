//
//  ActivityLog+CoreDataProperties.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//
//

import Foundation
import CoreData


extension ActivityLog {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ActivityLog> {
        return NSFetchRequest<ActivityLog>(entityName: "ActivityLog")
    }

    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var idActivityItem: UUID?
    @NSManaged public var timeSpent: Int64

}

extension ActivityLog : Identifiable {

}
