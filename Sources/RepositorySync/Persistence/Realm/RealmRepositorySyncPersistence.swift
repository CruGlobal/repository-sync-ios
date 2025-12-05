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
    
    public let database: RealmDatabase
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(database: RealmDatabase, dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.database = database
        self.dataModelMapping = dataModelMapping
    }
}

// MARK: - Observe

extension RealmRepositorySyncPersistence {
    
    public func observeCollectionChangesPublisher() -> AnyPublisher<Void, Error> {
        
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
        
        let results: Results<PersistObjectType> = try database.getObjectsResults(query: nil)
        
        return results.count
    }
    
    public func getObject(id: String) throws -> DataModelType? {
        
        let realmObject: PersistObjectType? = try database.getObject(id: id)
        
        guard let realmObject = realmObject, let dataModel = dataModelMapping.toDataModel(persistObject: realmObject) else {
            return nil
        }
        
        return dataModel
    }
    
    public func getObjects() throws -> [DataModelType] {
        
        return try getObjects(query: nil)
    }
    
    public func getObjects(query: RealmDatabaseQuery? = nil) throws -> [DataModelType] {
        
        let objects: [PersistObjectType] = try database.getObjects(query: query)
        
        let dataModels: [DataModelType] = objects.compactMap { object in
            self.dataModelMapping.toDataModel(persistObject: object)
        }
        
        return dataModels
    }
    
    public func getObjects(ids: [String]) throws -> [DataModelType] {
                
        let objects: [PersistObjectType] = try database.getObjects(ids: ids)
        
        let dataModels: [DataModelType] = objects.compactMap { object in
            self.dataModelMapping.toDataModel(persistObject: object)
        }
        
        return dataModels
    }
}

// MARK: - Write

extension RealmRepositorySyncPersistence {
    
    public func writeObjectsPublisher(writeClosure: @escaping (() -> [ExternalObjectType]), deleteObjectsNotFoundInExternalObjects: Bool) -> AnyPublisher<Void, any Error> {
        
        return Future { promise in
            
            self.database.background { realm in
                
                do {
                    
                    try realm.write {
                        
                        let externalObjects: [ExternalObjectType] = writeClosure()
                        
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
                        
                        realm.add(objectsToAdd, update: .modified)
                       
                        if objectsToRemove.count > 0 {
                            realm.delete(objectsToRemove)
                        }
                        
                        promise(.success(Void()))
                    }
                }
                catch let error {
                    
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
