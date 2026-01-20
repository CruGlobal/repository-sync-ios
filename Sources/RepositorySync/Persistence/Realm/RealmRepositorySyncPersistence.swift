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
    
    public func getObjectCount() throws -> Int {
        
        let realm: Realm = try database.openRealm()
        
        let results: Results<PersistObjectType> = database.read.results(
            realm: realm,
            query: nil
        )
        
        return results.count
    }
    
    @available(*, deprecated)
    public func getDataModelNonThrowing(id: String) -> DataModelType? {
        
        do {
            return try getDataModel(id: id)
        }
        catch _ {
            return nil
        }
    }
    
    public func getDataModel(id: String) throws -> DataModelType? {
        
        let realm: Realm = try database.openRealm()
        
        let getObjectsByType = RealmRepositorySyncGetObjects<PersistObjectType>()
        
        let persistObjects: [PersistObjectType] = try getObjectsByType.getObjects(
            realm: realm,
            getOption: .object(id: id),
            query: nil
        )
        
        guard let persistObject = persistObjects.first else {
            return nil
        }
        
        return dataModelMapping.toDataModel(persistObject: persistObject)
    }
    
    public func getDataModelsAsync(getOption: PersistenceGetOption) async throws -> [DataModelType] {
            
        return try await getDataModelsAsync(getOption: getOption, query: nil)
    }
    
    public func getDataModelsAsync(getOption: PersistenceGetOption, query: RealmDatabaseQuery?) async throws -> [DataModelType] {
            
        return try await withCheckedThrowingContinuation { continuation in
            getDataModelsAsyncClosure(getOption: getOption, query: query) { (result: Result<[DataModelType], Error>) in
                switch result {
                case .success(let dataModels):
                    continuation.resume(returning: dataModels)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func getDataModelsAsyncClosure(getOption: PersistenceGetOption, query: RealmDatabaseQuery?, completion: @escaping ((_ result: Result<[DataModelType], Error>) -> Void)) {
            
        DispatchQueue.global().async {
            
            do {
                
                let realm: Realm = try self.database.openRealm()
                
                let getObjectsByType = RealmRepositorySyncGetObjects<PersistObjectType>()
                
                let persistObjects: [PersistObjectType] = try getObjectsByType.getObjects(
                    realm: realm,
                    getOption: getOption,
                    query: query
                )

                let dataModels: [DataModelType] = persistObjects.compactMap { object in
                    self.dataModelMapping.toDataModel(persistObject: object)
                }
                
                completion(.success(dataModels))
            }
            catch let error {
                completion(.failure(error))
            }
        }
    }
    
    @available(*, deprecated)
    public func getDataModelsPublisher(getOption: PersistenceGetOption) -> AnyPublisher<[DataModelType], Error> {
        return getDataModelsPublisher(getOption: getOption, query: nil)
    }
    
    @available(*, deprecated)
    public func getDataModelsPublisher(getOption: PersistenceGetOption, query: RealmDatabaseQuery?) -> AnyPublisher<[DataModelType], Error> {
        
        return Future { promise in
            self.getDataModelsAsyncClosure(getOption: getOption, query: query, completion: { (result: Result<[DataModelType], Error>) in
                
                switch result {
                case .success(let dataModels):
                    promise(.success(dataModels))
                case .failure(let error):
                    promise(.failure(error))
                }
            })
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Write

extension RealmRepositorySyncPersistence {
    
    public func writeObjectsAsync(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) async throws -> [DataModelType] {
            
        return try await withCheckedThrowingContinuation { continuation in
            self.writeObjectsAsyncClosure(externalObjects: externalObjects, writeOption: writeOption, getOption: getOption) { result in
                switch result {
                case .success(let dataModels):
                    continuation.resume(returning: dataModels)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func writeObjectsAsyncClosure(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?, completion: @escaping ((_ result: Result<[DataModelType], Error>) -> Void)) {
     
        database.write.async(writeAsync: { (realm: Realm) in
            
            do {
                
                var objectsToDelete: [PersistObjectType] = Array()
                var objectsToInsert: [PersistObjectType] = Array()
                
                if let writeOption = writeOption {
                    
                    switch writeOption {
                    case .deleteObjectsNotInExternal:
                        objectsToDelete = RealmDataRead().objects(realm: realm, query: nil)
                    }
                }
                
                for externalObject in externalObjects {
                    
                    guard let dataModel = self.dataModelMapping.toPersistObject(externalObject: externalObject) else {
                        continue
                    }
                    
                    if let index = objectsToDelete.firstIndex(where: { $0.id == dataModel.id }) {
                        objectsToDelete.remove(at: index)
                    }
                    
                    objectsToInsert.append(dataModel)
                }

                if objectsToDelete.count > 0 {
                    for object in objectsToDelete {
                        realm.delete(object)
                    }
                }
                
                if objectsToInsert.count > 0 {
                    for object in objectsToInsert {
                        realm.add(object, update: .modified)
                    }
                }
                
                guard let getOption = getOption else {
                    completion(.success(Array()))
                    return
                }
                  
                let getObjectsByType = RealmRepositorySyncGetObjects<PersistObjectType>()
                
                let getObjects: [PersistObjectType] = try getObjectsByType.getObjects(
                    realm: realm,
                    getOption: getOption,
                    query: nil
                )
                
                let dataModels: [DataModelType] = getObjects.compactMap { object in
                    self.dataModelMapping.toDataModel(persistObject: object)
                }
                
                completion(.success(dataModels))
            }
            catch let error {
                
                completion(.failure(error))
            }
            
        }, writeError: { (error: Error) in
            
            completion(.failure(error))
        })
    }
    
    @available(*, deprecated)
    public func writeObjectsPublisher(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) -> AnyPublisher<[DataModelType], Error> {
                        
        return Future { promise in
            
            self.writeObjectsAsyncClosure(
                externalObjects: externalObjects,
                writeOption: writeOption,
                getOption: getOption,
                completion: { (result: Result<[DataModelType], Error>) in
                    
                    switch result {
                    case .success(let dataModels):
                        promise(.success(dataModels))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            )
        }
        .eraseToAnyPublisher()
    }
}
