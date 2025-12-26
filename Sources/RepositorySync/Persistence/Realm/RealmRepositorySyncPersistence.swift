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
        
        self.read = RealmRepositorySyncPersistenceRead(dataModelMapping: dataModelMapping)
        self.write = RealmRepositorySyncPersistenceWrite(read: read, asyncWrite: database.asyncWrite, dataModelMapping: dataModelMapping)
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
    
    @MainActor public func getObjectCount() throws -> Int {
        
        let realm: Realm = try database.openRealm()
        
        let results: Results<PersistObjectType> = database.read.results(realm: realm, query: nil)
        
        return results.count
    }
    
    @MainActor public func getObjectsAsync(getObjectsType: GetObjectsType) async throws -> [DataModelType] {
        
        return try await getObjectsAsync(getObjectsType: getObjectsType, query: nil)
    }
    
    @MainActor public func getObjectsAsync(getObjectsType: GetObjectsType, query: RealmDatabaseQuery?) async throws -> [DataModelType] {
        
        return try await withCheckedThrowingContinuation { continuation in
            getObjectsBackground(getObjectsType: getObjectsType, query: query) { (result: Result<[DataModelType], Error>) in
                switch result {
                case .success(let dataModels):
                    continuation.resume(returning: dataModels)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    @MainActor public func getObjectsPublisher(getObjectsType: GetObjectsType) -> AnyPublisher<[DataModelType], Error> {
        
        return getObjectsPublisher(getObjectsType: getObjectsType, query: nil)
    }
    
    @MainActor public func getObjectsPublisher(getObjectsType: GetObjectsType, query: RealmDatabaseQuery?) -> AnyPublisher<[DataModelType], Error> {
        
        return Future { promise in
            self.getObjectsBackground(getObjectsType: getObjectsType, query: query) { result in
                switch result {
                case .success(let dataModels):
                    promise(.success(dataModels))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    @MainActor private func getObjectsBackground(getObjectsType: GetObjectsType, query: RealmDatabaseQuery?, completion: @escaping ((_ result: Result<[DataModelType], Error>) -> Void)) {
        
        Task {
            do {
                
                let realm: Realm = try self.database.openRealm()
                let dataModels = try read.getObjects(realm: realm, getObjectsType: getObjectsType, query: query)
                
                await MainActor.run {
                    completion(.success(dataModels))
                }
            }
            catch let error {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Write

extension RealmRepositorySyncPersistence {
    
    @MainActor public func writeObjectsAsync(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?) async throws -> [DataModelType] {
        return try await write.writeObjectsAsync(externalObjects: externalObjects, getObjectsType: getObjectsType)
    }
    
    @MainActor public func writeObjectsPublisher(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?) -> AnyPublisher<[DataModelType], any Error> {
        return write.writeObjectsPublisher(externalObjects: externalObjects, getObjectsType: getObjectsType)
    }
}
