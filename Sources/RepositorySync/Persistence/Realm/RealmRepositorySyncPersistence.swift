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
    
    @MainActor public func getDataModel(id: String) throws -> DataModelType? {
        return try read.getDataModel(id: id)
    }
    
    @MainActor public func getDataModelsAsync(getOption: PersistenceGetOption) async throws -> [DataModelType] {
        return try await getDataModelsAsync(getOption: getOption, query: nil)
    }
    
    @MainActor public func getDataModelsAsync(getOption: PersistenceGetOption, query: RealmDatabaseQuery?) async throws -> [DataModelType] {
        return try await read.getDataModelsAsync(getOption: getOption, query: query)
    }
    
    @MainActor public func getDataModelsPublisher(getOption: PersistenceGetOption) -> AnyPublisher<[DataModelType], Error> {
        return getDataModelsPublisher(getOption: getOption, query: nil)
    }
    
    @MainActor public func getDataModelsPublisher(getOption: PersistenceGetOption, query: RealmDatabaseQuery?) -> AnyPublisher<[DataModelType], Error> {
        return read.getDataModelsPublisher(getOption: getOption, query: query)
    }
}

// MARK: - Write

extension RealmRepositorySyncPersistence {
    
    @MainActor public func writeObjectsAsync(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) async throws -> [DataModelType] {
        return try await write.writeObjectsAsync(externalObjects: externalObjects, writeOption: writeOption, getOption: getOption)
    }
    
    @MainActor public func writeObjectsPublisher(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) -> AnyPublisher<[DataModelType], any Error> {
        return write.writeObjectsPublisher(externalObjects: externalObjects, writeOption: writeOption, getOption: getOption)
    }
}
