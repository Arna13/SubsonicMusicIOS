//
//  CoreData.swift
//  SubsonicMusic
//
//  Created by Arna13 on 14/6/23.
//

import Foundation
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    
    let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "SubsonicMusic")
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }
    }
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
}
