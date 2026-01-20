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
public actor SwiftDataActorRead<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableSwiftDataObject> {
    
    private let container: ModelContainer
    private let executor: ModelExecutor
    
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(container: ModelContainer, dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.container = container
        self.executor = DefaultSerialModelExecutor(modelContext: ModelContext(container))
        
        self.dataModelMapping = dataModelMapping
    }
    
    public func getDataModel(id: String) async throws -> DataModelType? {
                
        let getObjectsByType = SwiftRepositorySyncGetObjects<PersistObjectType>()
        
        let persistObjects: [PersistObjectType] = try getObjectsByType.getObjects(
            context: executor.modelContext,
            getOption: .object(id: id),
            query: nil
        )
        
        guard let persistObject = persistObjects.first else {
            return nil
        }
        
        return dataModelMapping.toDataModel(persistObject: persistObject)
    }
    
    public func getDataModels(getOption: PersistenceGetOption, query: SwiftDatabaseQuery<PersistObjectType>?) async throws -> [DataModelType] {
                           
        let getObjectsByType = SwiftRepositorySyncGetObjects<PersistObjectType>()
        
        let persistObjects: [PersistObjectType] = try getObjectsByType.getObjects(
            context: executor.modelContext,
            getOption: getOption,
            query: query
        )
                
        let dataModels: [DataModelType] = persistObjects.compactMap { object in
            self.dataModelMapping.toDataModel(persistObject: object)
        }
        
        return dataModels
    }
}

@available(iOS 17.4, *)
extension SwiftDataActorRead: ModelActor {
    
    nonisolated
    public var modelContainer: ModelContainer {
        return container
    }
    
    nonisolated
    public var modelExecutor: any ModelExecutor {
        return executor
    }
}
