//
//  SwiftDataWrite.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
public final class SwiftDataWrite: Sendable {
    
    public init() {
        
    }
    
    public func objects(context: ModelContext, deleteObjects: [any IdentifiableSwiftDataObject]?, insertObjects: [any IdentifiableSwiftDataObject]?) throws {
        
        if let deleteObjects = deleteObjects, deleteObjects.count > 0 {
            for object in deleteObjects {
                context.delete(object)
            }
        }
        
        if let insertObjects = insertObjects, insertObjects.count > 0 {
            for object in insertObjects {
                context.insert(object)
            }
        }
        
        guard context.hasChanges else {
            return
        }
        
        try context.save()
    }
}
