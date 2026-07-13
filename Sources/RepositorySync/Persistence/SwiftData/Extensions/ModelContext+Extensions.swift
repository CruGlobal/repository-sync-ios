//
//  ModelContext+MoveToRepoSync.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/13/26.
//  Copyright © 2026 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17, *)
extension ModelContext {
    
    func insertObjects(objects: [any PersistentModel]) {
        
        guard !objects.isEmpty else {
            return
        }
        
        for object in objects {
            insert(object)
        }
    }
    
    func deleteObjects(objects: [any PersistentModel]) {
        
        guard !objects.isEmpty else {
            return
        }
        
        for object in objects {
            delete(object)
        }
    }
    
    func saveIfHasChanges() throws {
        
        guard hasChanges else {
            return
        }
        
        try save()
    }
}
