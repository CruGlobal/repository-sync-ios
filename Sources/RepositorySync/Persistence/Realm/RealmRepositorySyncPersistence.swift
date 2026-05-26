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
            
    public let databaseConfig: RealmDatabaseConfig
    public let mapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    public let readActor: RealmActorRead<DataModelType, ExternalObjectType, PersistObjectType>
    public let writeActor: RealmActorWrite<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(databaseConfig: RealmDatabaseConfig, mapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) async throws {
        
        self.databaseConfig = databaseConfig
        self.mapping = mapping

        readActor = try await RealmActorRead(config: databaseConfig.config, mapping: mapping)
        writeActor = try await RealmActorWrite(config: databaseConfig.config, mapping: mapping)
    }
}

// MARK: - Observe

extension RealmRepositorySyncPersistence {
    
    @MainActor public func observeCollectionChangesPublisher() -> AnyPublisher<Void, Error> {
        
        do {
            
            let realm: Realm = try databaseConfig.openRealm()
            
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
        
        let realm: Realm = try databaseConfig.openRealm()
        
        let results: Results<PersistObjectType> = RealmDataRead().results(
            realm: realm,
            query: nil
        )
        
        return results.count
    }

    public func getDataModel(id: String) throws -> DataModelType? {
        
        let realm: Realm = try databaseConfig.openRealm()
        
        let persistObjects: [PersistObjectType] = try RealmDataRead()
            .getObjects(realm: realm, readObjectsType: .object(id: id))
        
        guard let persistObject = persistObjects.first else {
            return nil
        }
        
        return mapping.toDataModel(persistObject: persistObject)
    }
    
    public func getDataModels(getOption: PersistenceGetOption) async throws -> [DataModelType] {
        
        return try await readActor
            .getDataModels(readObjectsType: getOption.toRealmReadObjectsType())
    }
}

// MARK: - Write

extension RealmRepositorySyncPersistence {
    
    public func writeObjects(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) async throws -> [DataModelType] {
     
        return try await writeActor.writeObjects(
            externalObjects: externalObjects,
            writeOption: writeOption,
            readObjectsType: getOption?.toRealmReadObjectsType()
        )
    }
}
