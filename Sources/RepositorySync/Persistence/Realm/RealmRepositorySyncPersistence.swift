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
            
    public let database: RealmDatabase
    public let mapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(database: RealmDatabase, mapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.database = database
        self.mapping = mapping
    }
    
    public var databaseConfig: RealmDatabaseConfig {
        return database.databaseConfig
    }
    
    public func openRealm() throws -> Realm {
        return try databaseConfig.openRealm()
    }
    
    public func newActorRead() async throws -> RealmActorRead<DataModelType, ExternalObjectType, PersistObjectType> {
        return try await RealmActorRead(
            config: databaseConfig.config,
            mapping: mapping
        )
    }
    
    public func newActorWrite() async throws -> RealmActorWrite<DataModelType, ExternalObjectType, PersistObjectType> {
        return try await RealmActorWrite(
            config: databaseConfig.config,
            mapping: mapping
        )
    }
}

// MARK: - Observe

extension RealmRepositorySyncPersistence {
    
    @MainActor public func observeCollectionChangesPublisher() -> AnyPublisher<Void, Error> {
        
        do {
            
            let realm: Realm = try openRealm()
            
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
        
        let realm: Realm = try openRealm()
        
        let results: Results<PersistObjectType> = RealmDataRead().results(
            realm: realm,
            query: nil
        )
        
        return results.count
    }

    public func getDataModel(id: String) throws -> DataModelType? {
        
        let realm: Realm = try openRealm()
        
        let persistObjects: [PersistObjectType] = try RealmDataRead()
            .getObjects(realm: realm, readObjectsType: .object(id: id))
        
        guard let persistObject = persistObjects.first else {
            return nil
        }
        
        return mapping.toDataModel(persistObject: persistObject)
    }
    
    public func getDataModels() async throws -> [DataModelType] {
        return try await getDataModels(getOption: .allObjects)
    }
    
    public func getDataModels(getOption: PersistenceGetOption) async throws -> [DataModelType] {
        
        let readActor = try await newActorRead()
        
        return try await readActor.getDataModels(
            readObjectsType: getOption.toRealmReadObjectsType()
        )
    }
}

// MARK: - Write

extension RealmRepositorySyncPersistence {
    
    public func writeObjects(externalObjects: [ExternalObjectType]) async throws {
        
        _ = try await writeObjects(externalObjects: externalObjects, writeOption: nil, getOption: nil)
    }
    
    public func writeObjects(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) async throws -> [DataModelType] {
     
        let writeActor = try await newActorWrite()
        
        return try await writeActor.writeObjects(
            externalObjects: externalObjects,
            writeOption: writeOption,
            readObjectsType: getOption?.toRealmReadObjectsType()
        )
    }
    
    public func deleteCollection() async throws {
        
        let writeActor = try await newActorWrite()
        
        _ = try await writeActor.deleteCollection()
    }
    
    public func deleteObjectsByIds(ids: Set<String>, getOption: PersistenceGetOption?) async throws -> [DataModelType] {
        
        let writeActor = try await newActorWrite()
        
        return try await writeActor.deleteObjectsByIds(
            ids: ids,
            readObjectsType: getOption?.toRealmReadObjectsType()
        )
    }
}
