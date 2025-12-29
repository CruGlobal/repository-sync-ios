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
    
    public func getPersistedObject(id: String) throws -> PersistObjectType? {
        return try database.read.object(context: database.openContext(), id: id)
    }
    
    public func getPersistedObjects(query: SwiftDatabaseQuery<PersistObjectType>?) throws -> [PersistObjectType] {
        return try database.read.objects(context: database.openContext(), query: query)
    }
    
    public func getPersistedObjects(ids: [String], sortBy: [SortDescriptor<PersistObjectType>]?) throws -> [PersistObjectType] {
        return try database.read.objects(context: database.openContext(), ids: ids, sortBy: sortBy)
    }
    
    @MainActor public func getObjectsAsync(getObjectsType: GetObjectsType) async throws -> [DataModelType] {
        return try await getObjectsAsync(getObjectsType: getObjectsType, query: nil)
    }
    
    @MainActor public func getObjectsAsync(getObjectsType: GetObjectsType, query: SwiftDatabaseQuery<PersistObjectType>?) async throws -> [DataModelType] {
        return try await read.getObjectsAsync(getObjectsType: getObjectsType, query: query)
    }
    
    @MainActor public func getObjectsPublisher(getObjectsType: GetObjectsType) -> AnyPublisher<[DataModelType], Error> {
        return getObjectsPublisher(getObjectsType: getObjectsType, query: nil)
    }
    
    @MainActor public func getObjectsPublisher(getObjectsType: GetObjectsType, query: SwiftDatabaseQuery<PersistObjectType>?) -> AnyPublisher<[DataModelType], Error> {
        return read.getObjectsPublisher(getObjectsType: getObjectsType, query: query)
    }
}

// MARK: - Write

@available(iOS 17.4, *)
extension SwiftRepositorySyncPersistence {

    @MainActor public func writeObjectsAsync(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getObjectsType: GetObjectsType?) async throws -> [DataModelType] {
        return try await write.writeObjectsAsync(externalObjects: externalObjects, writeOption: writeOption, getObjectsType: getObjectsType)
    }
    
    @MainActor public func writeObjectsPublisher(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getObjectsType: GetObjectsType?) -> AnyPublisher<[DataModelType], any Error> {
        return write.writeObjectsPublisher(externalObjects: externalObjects, writeOption: writeOption, getObjectsType: getObjectsType)
    }
}
