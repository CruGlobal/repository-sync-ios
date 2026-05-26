//
//  SwiftDataActorWrite.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
public actor SwiftDataActorWrite<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableSwiftDataObject>: ModelActor {
        
    private let mapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
        
    public let modelContainer: ModelContainer
    public let modelExecutor: ModelExecutor
    
    public init(container: ModelContainer, mapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.modelContainer = container
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: ModelContext(container))
        
        self.mapping = mapping
    }
    
    private func readObjects(readObjectsType: SwiftDataReadObjectsType<PersistObjectType>?) throws -> [DataModelType] {
        
        guard let readObjectsType = readObjectsType else {
            return Array()
        }
        
        let objects: [PersistObjectType] = try SwiftDataRead()
            .getObjects(context: modelContext, readObjectsType: readObjectsType)
        
        return objects.compactMap {
            mapping.toDataModel(persistObject: $0)
        }
    }
    
    public func addObjects(externalObjects: [ExternalObjectType], readObjectsType: SwiftDataReadObjectsType<PersistObjectType>? = nil) throws -> [DataModelType] {
        
        guard !externalObjects.isEmpty else {
            return try readObjects(readObjectsType: readObjectsType)
        }
        
        let objects: [PersistObjectType] = externalObjects.compactMap {
            mapping.toPersistObject(externalObject: $0)
        }
        
        for object in objects {
            modelContext.insert(object)
        }
        
        guard modelContext.hasChanges else {
            return try readObjects(readObjectsType: readObjectsType)
        }
        
        try modelContext.save()

        return try readObjects(readObjectsType: readObjectsType)
    }
    
    public func deleteObjectsByIds(ids: Set<String>, readObjectsType: SwiftDataReadObjectsType<PersistObjectType>? = nil) throws -> [DataModelType] {
        
        guard !ids.isEmpty else {
            return try readObjects(readObjectsType: readObjectsType)
        }
        
        let objects: [PersistObjectType] = try SwiftDataRead()
            .getObjects(context: modelContext, readObjectsType: .objectsByIds(ids: ids, sortBy: nil))
        
        return try deleteObjects(objects: objects, readObjectsType: readObjectsType)
    }
    
    public func deleteObjects(readObjectsType: SwiftDataReadObjectsType<PersistObjectType>? = nil) throws -> [DataModelType] {
        
        let objects: [PersistObjectType] = try SwiftDataRead()
            .getObjects(context: modelContext, readObjectsType: .allObjects)
        
        return try deleteObjects(objects: objects, readObjectsType: readObjectsType)
    }
    
    private func deleteObjects(objects: [PersistObjectType], readObjectsType: SwiftDataReadObjectsType<PersistObjectType>?) throws -> [DataModelType] {
        
        for object in objects {
            modelContext.delete(object)
        }
        
        guard modelContext.hasChanges else {
            return try readObjects(readObjectsType: readObjectsType)
        }
        
        try modelContext.save()
        
        return try readObjects(readObjectsType: readObjectsType)
    }
    
    public func writeObjects(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, readObjectsType: SwiftDataReadObjectsType<PersistObjectType>? = nil) throws -> [DataModelType] {
     
        var objectIdsToDelete: Set<String> = Set()
        
        if let writeOption = writeOption {
            
            switch writeOption {
            case .deleteObjectsNotInExternal:
                objectIdsToDelete = try getAllObjectIds()
            }
        }
        
        var objectsToInsert: [PersistObjectType] = Array()
        
        for externalObject in externalObjects {
            
            guard let dataModel = mapping.toPersistObject(externalObject: externalObject) else {
                continue
            }
            
            objectIdsToDelete.remove(dataModel.id)
            
            objectsToInsert.append(dataModel)
        }
        
        if !objectIdsToDelete.isEmpty {
            
            let objectsToDelete: [PersistObjectType] = try SwiftDataRead()
                .getObjects(context: modelContext, readObjectsType: .objectsByIds(ids: objectIdsToDelete, sortBy: nil))
            
            for object in objectsToDelete {
                modelContext.delete(object)
            }
        }
        
        if !objectsToInsert.isEmpty {
            for object in objectsToInsert {
                modelContext.insert(object)
            }
        }
        
        guard modelContext.hasChanges else {
            return try readObjects(readObjectsType: readObjectsType)
        }
        
        try modelContext.save()
        
        return try readObjects(readObjectsType: readObjectsType)
    }
    
    private func getAllObjectIds() throws -> Set<String> {
        
        let objects: [PersistObjectType] = try SwiftDataRead().objects(context: modelContext, query: nil)
        
        return Set(objects.map {
            $0.id
        })
    }
}
