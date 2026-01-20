//
//  SwiftRepositorySyncPersistenceWriteOnContext.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData
import Combine

@available(iOS 17.4, *)
public final class SwiftRepositorySyncPersistenceWriteOnContext<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableSwiftDataObject>: Sendable {
    
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
                
        self.dataModelMapping = dataModelMapping
    }
    
    public func write(context: ModelContext, externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) throws -> [DataModelType] {
        
        var objectsToDelete: [PersistObjectType] = Array()
        var objectsToInsert: [PersistObjectType] = Array()
        
        if let writeOption = writeOption {
            
            switch writeOption {
            case .deleteObjectsNotInExternal:
                objectsToDelete = try SwiftDataRead().objects(context: context, query: nil)
            }
        }
        
        for externalObject in externalObjects {
            
            guard let persistObject = dataModelMapping.toPersistObject(externalObject: externalObject) else {
                continue
            }
            
            if let index = objectsToDelete.firstIndex(where: { $0.id == persistObject.id }) {
                objectsToDelete.remove(at: index)
            }
            
            objectsToInsert.append(persistObject)
        }
        
//        try context.transaction {
//            
//            if objectsToDelete.count > 0 {
//                for object in objectsToDelete {
//                    context.delete(object)
//                }
//            }
//            
//            if objectsToInsert.count > 0 {
//                for object in objectsToInsert {
//                    context.insert(object)
//                }
//            }
//        }
        
        if objectsToDelete.count > 0 {
            for object in objectsToDelete {
                context.delete(object)
            }
        }
        
        if objectsToInsert.count > 0 {
            for object in objectsToInsert {
                context.insert(object)
            }
        }
        
        if context.hasChanges {
            try context.save()
        }
        
        guard let getOption = getOption else {
            return Array()
        }
                
        let getObjectsByType = SwiftRepositorySyncGetObjects<PersistObjectType>()
        
        let getObjects: [PersistObjectType] = try getObjectsByType.getObjects(
            context: context,
            getOption: getOption,
            query: nil
        )
        
        let dataModels: [DataModelType] = getObjects.compactMap { object in
            dataModelMapping.toDataModel(persistObject: object)
        }
        
        return dataModels
    }
}
