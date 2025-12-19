//
//  RealmDatabase.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/22/23.
//  Copyright © 2023 Cru. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

open class RealmDatabase {
        
    private let writeSerialQueue: DispatchQueue = DispatchQueue(label: "realm.write.serial_queue")
    
    public let databaseConfig: RealmDatabaseConfig
        
    public init(databaseConfig: RealmDatabaseConfig) {
        
        self.databaseConfig = databaseConfig
    }
    
    public func openRealm() throws -> Realm {
        
        return try Realm(
            configuration: databaseConfig.config
        )
    }
}

// MARK: - Read

extension RealmDatabase {
    
    public func getObject<T: IdentifiableRealmObject>(id: String) throws -> T? {
        return getObject(realm: try openRealm(), id: id)
    }
    
    public func getObject<T: IdentifiableRealmObject>(realm: Realm, id: String) -> T? {
        
        let realmObject: T? = realm.object(ofType: T.self, forPrimaryKey: id)

        return realmObject
    }
    
    public func getObjects<T: IdentifiableRealmObject>(ids: [String], sortBykeyPath: SortByKeyPath? = nil) throws -> [T] {
        return getObjects(realm: try openRealm(), ids: ids, sortBykeyPath: sortBykeyPath)
    }
    
    public func getObjects<T: IdentifiableRealmObject>(realm: Realm, ids: [String], sortBykeyPath: SortByKeyPath? = nil) -> [T] {
                
        let query = RealmDatabaseQuery(
            filter: NSPredicate(format: "id IN %@", ids),
            sortByKeyPath: sortBykeyPath
        )
        
        return getObjects(realm: realm, query: query)
    }
    
    public func getObjects<T: IdentifiableRealmObject>(query: RealmDatabaseQuery?) throws -> [T] {
        return getObjects(realm: try openRealm(), query: query)
    }
    
    public func getObjects<T: IdentifiableRealmObject>(realm: Realm, query: RealmDatabaseQuery?) -> [T] {
        
        return Array(getObjectsResults(realm: realm, query: query))
    }
    
    public func getObjectsResults<T: IdentifiableRealmObject>(query: RealmDatabaseQuery?) throws -> Results<T> {
        return getObjectsResults(realm: try openRealm(), query: query)
    }
    
    public func getObjectsResults<T: IdentifiableRealmObject>(realm: Realm, query: RealmDatabaseQuery?) -> Results<T> {
        
        let results = realm.objects(T.self)
        
        if let filter = query?.filter, let sortByKeyPath = query?.sortByKeyPath {
            
            return results
                .filter(filter)
                .sorted(byKeyPath: sortByKeyPath.keyPath, ascending: sortByKeyPath.ascending)
        }
        else if let filter = query?.filter {
           
            return results
                .filter(filter)
        }
        else if let sortByKeyPath = query?.sortByKeyPath {
            return results
                .sorted(byKeyPath: sortByKeyPath.keyPath, ascending: sortByKeyPath.ascending)
        }
        
        return results
    }
}

// MARK: - Write

extension RealmDatabase {
        
    @MainActor public func writeAsync(writeClosure: @escaping ((_ realm: Realm) -> Void), completion: @escaping ((_ result: Result<Realm, Error>) -> Void)) {
                        
        let config: Realm.Configuration = self.databaseConfig.config
        
        writeSerialQueue.async {
            autoreleasepool {
                do {
                    
                    let realm: Realm = try Realm(configuration: config)
                    
                    try realm.write {
                        writeClosure(realm)
                        completion(.success(realm))
                    }
                }
                catch let error {
                    completion(.failure(error))
                }
            }
        }
    }
    
    public func writeObjects(writeClosure: ((_ realm: Realm) -> RealmDatabaseWrite), updatePolicy: Realm.UpdatePolicy, completion: ((_ realm: Realm) -> Void)? = nil) throws {
        
        try writeObjects(
            realm: try openRealm(),
            writeClosure: writeClosure,
            updatePolicy: updatePolicy,
            completion: completion
        )
    }
    
    public func writeObjects(realm: Realm, writeClosure: ((_ realm: Realm) -> RealmDatabaseWrite), updatePolicy: Realm.UpdatePolicy, completion: ((_ realm: Realm) -> Void)? = nil) throws {
        
        try realm.write {
            
            let write: RealmDatabaseWrite = writeClosure(realm)
             
            if let objectsToDelete = write.deleteObjects, objectsToDelete.count > 0 {
                realm.delete(objectsToDelete)
            }
            
            if write.updateObjects.count > 0 {
                realm.add(write.updateObjects, update: updatePolicy)
            }
            
            completion?(realm)
        }
    }
}
