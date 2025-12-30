//
//  RealmRepositorySyncPersistence.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift
import Combine

public final class RealmRepositorySyncPersistence<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableRealmObject>: Persistence {
        
    private let read: RealmRepositorySyncPersistenceRead<DataModelType, ExternalObjectType, PersistObjectType>
    private let write: RealmRepositorySyncPersistenceWrite<DataModelType, ExternalObjectType, PersistObjectType>
    
    public let database: RealmDatabase
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(database: RealmDatabase, dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.database = database
        self.dataModelMapping = dataModelMapping
        
        self.read = RealmRepositorySyncPersistenceRead(database: database, dataModelMapping: dataModelMapping)
        self.write = RealmRepositorySyncPersistenceWrite(asyncWrite: database.asyncWrite, dataModelMapping: dataModelMapping)
    }
}

// MARK: - Observe

extension RealmRepositorySyncPersistence {
    
    @MainActor public func observeCollectionChangesPublisher() -> AnyPublisher<Void, Error> {
        
        do {
            
            let realm: Realm = try database.openRealm()
            
            return realm
                .objects(PersistObjectType.self)
                .objectWillChange
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        catch let error {
            
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
}

// MARK: Read

extension RealmRepositorySyncPersistence {
    
    public func getObjectCount() throws -> Int {
        
        let realm: Realm = try database.openRealm()
        
        let results: Results<PersistObjectType> = database.read.results(realm: realm, query: nil)
        
        return results.count
    }
    
    public func getPersistedObject(id: String) throws -> PersistObjectType? {
        return database.read.object(realm: try database.openRealm(), id: id)
    }
    
    public func getPersistedObjects() throws -> [PersistObjectType] {
        return try getPersistedObjects(query: nil)
    }
    
    public func getPersistedObjects(query: RealmDatabaseQuery?) throws -> [PersistObjectType] {
        return database.read.objects(realm: try database.openRealm(), query: query)
    }
    
    public func getPersistedObjects(ids: [String]) throws -> [PersistObjectType] {
        return try getPersistedObjects(ids: ids, sortBy: nil)
    }
    
    public func getPersistedObjects(ids: [String], sortBy: SortByKeyPath?) throws -> [PersistObjectType] {
        return database.read.objects(realm: try database.openRealm(), ids: ids, sortBykeyPath: sortBy)
    }
    
    @MainActor public func getObjectsAsync(getObjectsType: GetObjectsType) async throws -> [DataModelType] {
        
        return try await getObjectsAsync(getObjectsType: getObjectsType, query: nil)
    }
    
    @MainActor public func getObjectsAsync(getObjectsType: GetObjectsType, query: RealmDatabaseQuery?) async throws -> [DataModelType] {
        return try await read.getObjectsAsync(getObjectsType: getObjectsType, query: query)
    }
    
    @MainActor public func getObjectsPublisher(getObjectsType: GetObjectsType) -> AnyPublisher<[DataModelType], Error> {
        return getObjectsPublisher(getObjectsType: getObjectsType, query: nil)
    }
    
    @MainActor public func getObjectsPublisher(getObjectsType: GetObjectsType, query: RealmDatabaseQuery?) -> AnyPublisher<[DataModelType], Error> {
        return read.getObjectsPublisher(getObjectsType: getObjectsType, query: query)
    }
}

// MARK: - Write

extension RealmRepositorySyncPersistence {
    
    @MainActor public func writeObjectsAsync(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getObjectsType: GetObjectsType?) async throws -> [DataModelType] {
        return try await write.writeObjectsAsync(externalObjects: externalObjects, writeOption: writeOption, getObjectsType: getObjectsType)
    }
    
    @MainActor public func writeObjectsPublisher(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getObjectsType: GetObjectsType?) -> AnyPublisher<[DataModelType], any Error> {
        return write.writeObjectsPublisher(externalObjects: externalObjects, writeOption: writeOption, getObjectsType: getObjectsType)
    }
}
