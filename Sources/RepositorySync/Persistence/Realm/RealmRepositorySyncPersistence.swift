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
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(database: RealmDatabase, dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.database = database
        self.dataModelMapping = dataModelMapping
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
    
    @MainActor private func getObjectsBackground(getObjectsType: GetObjectsType, query: RealmDatabaseQuery?, completion: @escaping ((_ result: Result<[DataModelType], Error>) -> Void)) {
        
        DispatchQueue.global().async {
            do {
                let realm: Realm = try self.database.openRealm()
                let dataModels: [DataModelType] = self.getObjects(realm: realm, getObjectsType: getObjectsType, query: query)
                DispatchQueue.main.async {
                    completion(.success(dataModels))
                }
            }
            catch let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
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

    private func getObjects(realm: Realm, getObjectsType: GetObjectsType, query: RealmDatabaseQuery?) -> [DataModelType] {
                
        // TODO: Should an error be thrown if GetObjectsType is other than all and query is provided? ~Levi
        
        let persistObjects: [PersistObjectType]
                
        switch getObjectsType {
            
        case .allObjects:
            persistObjects = database.read.objects(realm: realm, query: query)
            
        case .object(let id):
            
            let object: PersistObjectType? = database.read.object(realm: realm, id: id)
            
            if let object = object {
                persistObjects = [object]
            }
            else {
                persistObjects = []
            }
        }
        
        return mapPersistObjects(persistObjects: persistObjects)
    }
    
    public func mapPersistObjects(persistObjects: [PersistObjectType]) -> [DataModelType] {
                
        let dataModels: [DataModelType] = persistObjects.compactMap { object in
            self.dataModelMapping.toDataModel(persistObject: object)
        }
        
        return dataModels
    }
}

// MARK: - Write

extension RealmRepositorySyncPersistence {
    
    @MainActor private func writeObjectsBackground(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?, completion: @escaping ((_ result: Result<[DataModelType], Error>) -> Void)) {
                
        self.database.asyncWrite.objects(writeClosure: { (realm: Realm) in
            
            var objectsToAdd: [PersistObjectType] = Array()
                                    
            for externalObject in externalObjects {

                guard let persistObject = self.dataModelMapping.toPersistObject(externalObject: externalObject) else {
                    continue
                }
                
                objectsToAdd.append(persistObject)
            }
            
            if objectsToAdd.count > 0 {
                realm.add(objectsToAdd, update: .modified)
            }
            
        }, completion: { (result: Result<Realm, Error>) in
            
            switch result {
            
            case .success(let realm):
                
                let dataModels: [DataModelType]
                
                if let getObjectsType = getObjectsType {
                    dataModels = self.getObjects(realm: realm, getObjectsType: getObjectsType, query: nil)
                }
                else {
                    dataModels = Array()
                }
                
                DispatchQueue.main.async {
                    completion(.success(dataModels))
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        })
    }
    
    @MainActor public func writeObjectsAsync(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?) async throws -> [DataModelType] {
        
        return try await withCheckedThrowingContinuation { continuation in
            writeObjectsBackground(externalObjects: externalObjects, getObjectsType: getObjectsType) { (result: Result<[DataModelType], Error>) in
                switch result {
                case .success(let dataModels):
                    continuation.resume(returning: dataModels)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    @MainActor public func writeObjectsPublisher(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?) -> AnyPublisher<[DataModelType], any Error> {
                
        return Future { promise in
            
            self.writeObjectsBackground(externalObjects: externalObjects, getObjectsType: getObjectsType) { result in
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
}
