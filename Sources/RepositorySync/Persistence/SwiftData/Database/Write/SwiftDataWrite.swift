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
    
    public func context(context: ModelContext, writeObjects: WriteSwiftObjects) throws {
        
        if let deleteObjects = writeObjects.deleteObjects, deleteObjects.count > 0 {
            for object in deleteObjects {
                context.delete(object)
            }
        }
        
        if let insertObjects = writeObjects.insertObjects, insertObjects.count > 0 {
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
