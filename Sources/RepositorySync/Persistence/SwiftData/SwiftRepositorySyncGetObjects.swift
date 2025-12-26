//
//  SwiftRepositorySyncGetObjects.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
public final class SwiftRepositorySyncGetObjects<PersistObjectType: IdentifiableSwiftDataObject> {
    
    public init() {
        
    }
    
    public func getObjects(context: ModelContext, getObjectsType: GetObjectsType, query: SwiftDatabaseQuery<PersistObjectType>?) throws -> [PersistObjectType] {
        
        let read = SwiftDataRead()
        
        let persistObjects: [PersistObjectType]
                
        switch getObjectsType {
            
        case .allObjects:
            persistObjects = try read.objects(context: context, query: query)
            
        case .object(let id):
            
            let object: PersistObjectType? = try read.object(context: context, id: id)
            
            if let object = object {
                persistObjects = [object]
            }
            else {
                persistObjects = []
            }
        }
        
        return persistObjects
    }
}
