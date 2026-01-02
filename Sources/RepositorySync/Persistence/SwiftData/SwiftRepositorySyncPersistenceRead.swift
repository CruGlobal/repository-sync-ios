//
//  SwiftRepositorySyncPersistenceRead.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData
import Combine

@available(iOS 17.4, *)
public actor SwiftRepositorySyncPersistenceRead<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableSwiftDataObject> {
    
    private let container: ModelContainer
    private let executor: ModelExecutor
    
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(container: ModelContainer, dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.container = container
        self.executor = DefaultSerialModelExecutor(modelContext: ModelContext(container))
        
        self.dataModelMapping = dataModelMapping
    }
    
    public var context: ModelContext {
        return modelContext
    }
    
    @MainActor public func getDataModel(id: String) throws -> DataModelType? {
        
        let context: ModelContext = container.mainContext
        
        let getObjectsByType = SwiftRepositorySyncGetObjects<PersistObjectType>()
        
        let persistObjects: [PersistObjectType] = try getObjectsByType.getObjects(
            context: context,
            getOption: .object(id: id),
            query: nil
        )
        
        guard let persistObject = persistObjects.first else {
            return nil
        }
        
        return dataModelMapping.toDataModel(persistObject: persistObject)
    }
    
    public func getDataModelsAsync(getOption: PersistenceGetOption, query: SwiftDatabaseQuery<PersistObjectType>?) async throws -> [DataModelType] {
                   
        let context: ModelContext = self.context
        
        let getObjectsByType = SwiftRepositorySyncGetObjects<PersistObjectType>()
        
        let persistObjects: [PersistObjectType] = try getObjectsByType.getObjects(
            context: context,
            getOption: getOption,
            query: query
        )
                
        let dataModels: [DataModelType] = persistObjects.compactMap { object in
            self.dataModelMapping.toDataModel(persistObject: object)
        }
        
        return dataModels
    }
    
    @MainActor public func getDataModelsPublisher(getOption: PersistenceGetOption, query: SwiftDatabaseQuery<PersistObjectType>?) -> AnyPublisher<[DataModelType], Error> {
        
        return Future { promise in
            
            Task {
                
                do {
                    let dataModels = try await self.getDataModelsAsync(getOption: getOption, query: query)
                    
                    promise(.success(dataModels))
                }
                catch let error {
                    
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

@available(iOS 17.4, *)
extension SwiftRepositorySyncPersistenceRead: ModelActor {
    
    nonisolated
    public var modelContainer: ModelContainer {
        return container
    }
    
    nonisolated
    public var modelExecutor: any ModelExecutor {
        return executor
    }
}
