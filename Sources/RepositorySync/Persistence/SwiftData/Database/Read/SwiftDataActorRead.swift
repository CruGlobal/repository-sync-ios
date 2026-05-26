//
//  SwiftDataActorRead.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
public actor SwiftDataActorRead<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableSwiftDataObject>: ModelActor {
    
    private let mapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public let modelContainer: ModelContainer
    public let modelExecutor: ModelExecutor
    
    public init(container: ModelContainer, mapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.modelContainer = container
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: ModelContext(container))
        
        self.mapping = mapping
    }
    
    public func getDataModel(id: String) throws -> DataModelType? {
        
        let object: PersistObjectType? = try SwiftDataRead()
            .object(context: modelContext, id: id)
        
        guard let object = object else {
            return nil
        }
        
        return mapping.toDataModel(persistObject: object)
    }
    
    public func getDataModels(ids: Set<String>, sortBy: [SortDescriptor<PersistObjectType>]?) throws -> [DataModelType] {
        
        let objects: [PersistObjectType] = try SwiftDataRead()
            .objects(context: modelContext, ids: ids, sortBy: sortBy)
                
        return objects.compactMap {
            mapping.toDataModel(persistObject: $0)
        }
    }
    
    public func getDataModels(query: SwiftDatabaseQuery<PersistObjectType>?) throws -> [DataModelType] {
        
        let objects: [PersistObjectType] = try SwiftDataRead()
            .objects(context: modelContext, query: query)
        
        return objects.compactMap {
            mapping.toDataModel(persistObject: $0)
        }
    }
    
    public func getDataModels(readObjectsType: SwiftDataReadObjectsType<PersistObjectType>) throws -> [DataModelType] {
        
        let objects: [PersistObjectType] = try SwiftDataRead()
            .getObjects(context: modelContext, readObjectsType: readObjectsType)
        
        return objects.compactMap {
            mapping.toDataModel(persistObject: $0)
        }
    }
}
