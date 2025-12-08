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
import Combine

public final class RealmDatabase {
    
    private let backgroundQueue: DispatchQueue = DispatchQueue(label: "realm.background_queue")
    private let config: Realm.Configuration
    private let fileUrl: URL
    
    public init(fileName: String, schemaVersion: UInt64, migrationBlock: @escaping MigrationBlock) {
        
        fileUrl = URL(fileURLWithPath: RLMRealmPathForFile(fileName), isDirectory: false)
        
        config = Realm.Configuration(
            fileURL: fileUrl,
            schemaVersion: schemaVersion,
            migrationBlock: migrationBlock
        )
        
        _ = checkForUnsupportedFileFormatVersionAndDeleteRealmFilesIfNeeded(config: config)
    }
    
    public init(fileUrl: URL, schemaVersion: UInt64, migrationBlock: @escaping MigrationBlock) {
        
        self.fileUrl = fileUrl
        
        config = Realm.Configuration(
            fileURL: fileUrl,
            schemaVersion: schemaVersion,
            migrationBlock: migrationBlock
        )
        
        _ = checkForUnsupportedFileFormatVersionAndDeleteRealmFilesIfNeeded(config: config)
    }

    private func checkForUnsupportedFileFormatVersionAndDeleteRealmFilesIfNeeded(config: Realm.Configuration) -> Error? {
        
        do {
            _ = try Realm(configuration: config)
        }
        catch let realmConfigError as NSError {
            
            if realmConfigError.code == Realm.Error.unsupportedFileFormatVersion.rawValue {
                
                do {
                    _ = try Realm.deleteFiles(for: config)
                }
                catch let deleteFilesError {
                    return deleteFilesError
                }
            }
            else {
                return realmConfigError
            }
        }
        
        return nil
    }
    
    public func openRealm() throws -> Realm {
        
        return try Realm(configuration: config)
    }
    
    public func background(async: @escaping ((_ realm: Realm) -> Void)) {
        
        backgroundQueue.async {
            autoreleasepool {
                
                let realm: Realm
               
                do {
                    realm = try Realm(configuration: self.config)
                }
                catch let error {
                    assertionFailure("RealmDatabase: Did fail to initialize background realm with error: \(error.localizedDescription) ")
                    realm = try! Realm(configuration: self.config)
                }
                
                async(realm)
            }
        }
    }
}

// MARK: - Read

extension RealmDatabase {
    
    public func getObject<T: IdentifiableRealmObject>(realm: Realm, id: String) -> T? {
        
        let realmObject: T? = realm.object(ofType: T.self, forPrimaryKey: id)
        
        return realmObject
    }
    
    public func getObjects<T: IdentifiableRealmObject>(realm: Realm, ids: [String], sortBykeyPath: SortByKeyPath? = nil) -> [T] {
        
        let query = RealmDatabaseQuery(
            filter: getObjectsByIdsFilter(ids: ids),
            sortByKeyPath: sortBykeyPath
        )
        
        return getObjects(realm: realm, query: query)
    }
    
    private func getObjectsByIdsFilter(ids: [String]) -> NSPredicate {
        return NSPredicate(format: "id IN %@", ids)
    }

    public func getObjects<T: IdentifiableRealmObject>(realm: Realm, query: RealmDatabaseQuery?) -> [T] {
        
        return Array(getObjectsResults(realm: realm, query: query))
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
        
    public func writeObjectsPublisher(writeClosure: @escaping ((_ realm: Realm) -> RealmDatabaseWrite), updatePolicy: Realm.UpdatePolicy) -> AnyPublisher<Void, Error> {
        
        return Future { promise in
            
            self.background { realm in
                
                do {
                    
                    try self.writeObjects(
                        realm: realm,
                        writeClosure: writeClosure,
                        updatePolicy: updatePolicy
                    )
                    
                    promise(.success(Void()))
                }
                catch let error {
                    
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func writeObjects(realm: Realm, writeClosure: ((_ realm: Realm) -> RealmDatabaseWrite), updatePolicy: Realm.UpdatePolicy) throws {
        
        try realm.write {
            
            let realmDatabaseWrite: RealmDatabaseWrite = writeClosure(realm)
                        
            if realmDatabaseWrite.updateObjects.count > 0 {
                realm.add(realmDatabaseWrite.updateObjects, update: updatePolicy)
            }
            
            if let objectsToDelete = realmDatabaseWrite.deleteObjects, objectsToDelete.count > 0 {
                realm.delete(objectsToDelete)
            }
        }
    }
}

// MARK: - Delete

extension RealmDatabase {
    
    public func deleteObjects(realm: Realm, objects: [Object]) throws {
        
        guard objects.count > 0 else {
            return
        }
        
        try realm.write {
            realm.delete(objects)
        }
    }
}
