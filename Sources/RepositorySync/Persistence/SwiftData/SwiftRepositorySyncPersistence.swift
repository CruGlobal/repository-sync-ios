//
//  SwiftRepositorySyncPersistence.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData
import Combine

@available(iOS 17.4, *)
public final class SwiftRepositorySyncPersistence<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableSwiftDataObject>: Persistence {
    
    private let collectionObserver: SwiftDataCollectionObserver<PersistObjectType> = SwiftDataCollectionObserver()
    private let read: SwiftRepositorySyncPersistenceRead<DataModelType, ExternalObjectType, PersistObjectType>
    private let write: SwiftRepositorySyncPersistenceWrite<DataModelType, ExternalObjectType, PersistObjectType>
    
    public let database: SwiftDatabase
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(database: SwiftDatabase, dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.database = database
        self.dataModelMapping = dataModelMapping
                
        self.read = SwiftRepositorySyncPersistenceRead(container: database.container.modelContainer, dataModelMapping: dataModelMapping)
        self.write = SwiftRepositorySyncPersistenceWrite(container: database.container.modelContainer, dataModelMapping: dataModelMapping)
    }
}

// MARK: - Observe

@available(iOS 17.4, *)
extension SwiftRepositorySyncPersistence {
    
    @MainActor public func observeCollectionChangesPublisher() -> AnyPublisher<Void, Error> {
        
        return collectionObserver
            .observeCollectionChangesPublisher(database: database)
            .eraseToAnyPublisher()
    }
}

// MARK: Read

@available(iOS 17.4, *)
extension SwiftRepositorySyncPersistence {
    
    public func getObjectCount() throws -> Int {
        
        let context: ModelContext = database.openContext()
        
        return try database
            .read.objectCount(
                context: context,
                query: SwiftDatabaseQuery<PersistObjectType>(
                    fetchDescriptor: FetchDescriptor<PersistObjectType>()
                )
            )
    }
    
    @MainActor public func getDataModel(id: String) throws -> DataModelType? {
        return try read.getDataModel(id: id)
    }
    
    @MainActor public func getDataModelsAsync(getOption: PersistenceGetOption) async throws -> [DataModelType] {
        return try await getDataModelsAsync(getOption: getOption, query: nil)
    }
    
    @MainActor public func getDataModelsAsync(getOption: PersistenceGetOption, query: SwiftDatabaseQuery<PersistObjectType>?) async throws -> [DataModelType] {
        return try await read.getDataModelsAsync(getOption: getOption, query: query)
    }
    
    @MainActor public func getDataModelsPublisher(getOption: PersistenceGetOption) -> AnyPublisher<[DataModelType], Error> {
        return getDataModelsPublisher(getOption: getOption, query: nil)
    }
    
    @MainActor public func getDataModelsPublisher(getOption: PersistenceGetOption, query: SwiftDatabaseQuery<PersistObjectType>?) -> AnyPublisher<[DataModelType], Error> {
        return read.getDataModelsPublisher(getOption: getOption, query: query)
    }
}

// MARK: - Write

@available(iOS 17.4, *)
extension SwiftRepositorySyncPersistence {

    @MainActor public func writeObjectsAsync(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) async throws -> [DataModelType] {
        return try await write.writeObjectsAsync(externalObjects: externalObjects, writeOption: writeOption, getOption: getOption)
    }
    
    @MainActor public func writeObjectsPublisher(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) -> AnyPublisher<[DataModelType], any Error> {
        return write.writeObjectsPublisher(externalObjects: externalObjects, writeOption: writeOption, getOption: getOption)
    }
}
