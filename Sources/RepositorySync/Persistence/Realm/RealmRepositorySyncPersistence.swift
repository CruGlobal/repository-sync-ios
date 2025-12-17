//
//  RealmRepositorySyncPersistence.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/3/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift
import Combine

public final class RealmRepositorySyncPersistence<DataModelType, ExternalObjectType, PersistObjectType: IdentifiableRealmObject>: Persistence {
    
    private let writeSerialQueue: DispatchQueue = DispatchQueue(label: "realm.write.serial_queue")
    
    public let database: RealmDatabase
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(database: RealmDatabase, dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.database = database
        self.dataModelMapping = dataModelMapping
    }
    
    private func writeBackgroundRealm(async: @escaping ((_ result: Result<Realm, Error>) -> Void)) {
        
        let config: Realm.Configuration = database.config
        
        writeSerialQueue.async {
            autoreleasepool {
                               
                do {
                    let realm: Realm = try Realm(configuration: config)
                    async(.success(realm))
                }
                catch let error {
                    async(.failure(error))
                }
            }
        }
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
        
        let results: Results<PersistObjectType> = database.getObjectsResults(realm: realm, query: nil)
        
        return results.count
    }
    
    public func getObjectsPublisher(getObjectsType: GetObjectsType) -> AnyPublisher<[DataModelType], Error> {
        
        // TODO: Can this be done in the background? ~Levi
        
        return Future { promise in
         
            do {
             
                let dataModels: [DataModelType] = try self.getObjects(getObjectsType: getObjectsType)
                promise(.success(dataModels))
            }
            catch let error {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func getObjects(getObjectsType: GetObjectsType) throws -> [DataModelType] {
        
        // TODO: Can this be done in the background? ~Levi
        
        let realm: Realm = try database.openRealm()
        
        return getObjects(realm: realm, getObjectsType: getObjectsType)
    }
    
    private func getObjects(realm: Realm, getObjectsType: GetObjectsType) -> [DataModelType] {
        
        // TODO: Can this be done in the background? ~Levi
        
        let persistObjects: [PersistObjectType]
                
        switch getObjectsType {
            
        case .allObjects:
            persistObjects = database.getObjects(realm: realm, query: nil)
            
        case .object(let id):
            
            let object: PersistObjectType? = database.getObject(realm: realm, id: id)
            
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
        
        // TODO: Can this be done in the background? ~Levi
        
        let dataModels: [DataModelType] = persistObjects.compactMap { object in
            self.dataModelMapping.toDataModel(persistObject: object)
        }
        
        return dataModels
    }
}

// MARK: - Write

extension RealmRepositorySyncPersistence {
    
    @MainActor private func writeObjectsAsync(writeClosure: @escaping ((_ realm: Realm) -> RealmDatabaseWrite), updatePolicy: Realm.UpdatePolicy, completion: @escaping ((_ realm: Realm?, _ error: Error?) -> Void)) {
        
        let database: RealmDatabase = self.database
        
        writeBackgroundRealm { result in
            
            switch result {
            
            case .success(let realm):
                
                do {
                                    
                    try database.writeObjects(
                        realm: realm,
                        writeClosure: writeClosure,
                        updatePolicy: updatePolicy,
                        completion: { (realm: Realm) in
                            completion(realm, nil)
                        }
                    )
                }
                catch let error {
                    completion(nil, error)
                }
            
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    @MainActor public func writeObjectsPublisher(externalObjects: [ExternalObjectType], deleteObjectsNotFoundInExternalObjects: Bool, getObjectsType: GetObjectsType) -> AnyPublisher<[DataModelType], any Error> {
        
        return Future { promise in
            
            self.writeObjectsAsync(writeClosure: { (realm: Realm) in
                
                var objectsToAdd: [PersistObjectType] = Array()
                
                var objectsToRemove: [PersistObjectType]
                
                if deleteObjectsNotFoundInExternalObjects {
                    // store all objects in the collection.
                    objectsToRemove = self.database.getObjects(realm: realm, query: nil)
                }
                else {
                    objectsToRemove = Array()
                }
                
                for externalObject in externalObjects {

                    guard let persistObject = self.dataModelMapping.toPersistObject(externalObject: externalObject) else {
                        continue
                    }
                    
                    objectsToAdd.append(persistObject)
                    
                    // added persist object can be removed from this list so it won't be deleted from the database.
                    if deleteObjectsNotFoundInExternalObjects, let index = objectsToRemove.firstIndex(where: { $0.id == persistObject.id }) {
                        objectsToRemove.remove(at: index)
                    }
                }
                
                return RealmDatabaseWrite(updateObjects: objectsToAdd, deleteObjects: objectsToRemove)
                
            }, updatePolicy: .modified, completion: { (realm: Realm?, error: Error?) in
                
                let dataModels: [DataModelType]
                
                if let realm = realm {
                    dataModels = self.getObjects(realm: realm, getObjectsType: getObjectsType)
                }
                else {
                    dataModels = Array()
                }
                
                DispatchQueue.main.async {
                    if let error = error {
                        promise(.failure(error))
                    }
                    else {
                        promise(.success(dataModels))
                    }
                }
            })
            
        }
        .eraseToAnyPublisher()
    }
}
