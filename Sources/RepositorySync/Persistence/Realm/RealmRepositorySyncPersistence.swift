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
    public let readActor: RealmActorRead<DataModelType, ExternalObjectType, PersistObjectType>
    public let writeActor: RealmActorWrite<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(database: RealmDatabase, mapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) async throws {
        
        self.database = database
        self.mapping = mapping

        readActor = try await RealmActorRead(config: database.config, mapping: mapping)
        writeActor = try await RealmActorWrite(config: database.config, mapping: mapping)
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
        
        let results: Results<PersistObjectType> = RealmDataRead().results(
            realm: realm,
            query: nil
        )
        
        return results.count
    }

    public func getDataModel(id: String) throws -> DataModelType? {
        
        let realm: Realm = try database.openRealm()
        
        let persistObjects: [PersistObjectType] = try RealmDataRead()
            .getObjects(realm: realm, readObjectsType: .object(id: id))
        
        guard let persistObject = persistObjects.first else {
            return nil
        }
        
        return mapping.toDataModel(persistObject: persistObject)
    }
    
    public func getDataModelsAsync(getOption: PersistenceGetOption) async throws -> [DataModelType] {
        
        return try await readActor
            .getDataModels(readObjectsType: getOption.toRealmReadObjectsType())
    }
}

// MARK: - Write

extension RealmRepositorySyncPersistence {
    
    public func writeObjectsAsync(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) async throws -> [DataModelType] {
     
        return try await writeActor.writeObjects(
            externalObjects: externalObjects,
            writeOption: writeOption,
            readObjectsType: getOption?.toRealmReadObjectsType()
        )
    }
}
