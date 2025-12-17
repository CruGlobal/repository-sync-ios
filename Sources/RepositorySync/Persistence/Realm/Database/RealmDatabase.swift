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

public final class RealmDatabase {
        
    public let config: Realm.Configuration
    public let fileUrl: URL
    
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
}

// MARK: - Read

extension RealmDatabase {
    
    public func getObject<T: IdentifiableRealmObject>(realm: Realm, id: String) -> T? {
        
        let realmObject: T? = realm.object(ofType: T.self, forPrimaryKey: id)
        
        return realmObject
    }
    
    public func getObjects<T: IdentifiableRealmObject>(realm: Realm, ids: [String], sortBykeyPath: SortByKeyPath? = nil) -> [T] {
                
        let query = RealmDatabaseQuery(
            filter: NSPredicate(format: "id IN %@", ids),
            sortByKeyPath: sortBykeyPath
        )
        
        return getObjects(realm: realm, query: query)
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
        
    public func writeObjects(realm: Realm, writeClosure: ((_ realm: Realm) -> RealmDatabaseWrite), updatePolicy: Realm.UpdatePolicy, completion: ((_ realm: Realm) -> Void)? = nil) throws {
        
        try realm.write {
            
            let write: RealmDatabaseWrite = writeClosure(realm)
             
            if write.updateObjects.count > 0 {
                realm.add(write.updateObjects, update: updatePolicy)
            }
            
            if let objectsToDelete = write.deleteObjects, objectsToDelete.count > 0 {
                realm.delete(objectsToDelete)
            }
            
            completion?(realm)
        }
    }
}

// MARK: - Delete

extension RealmDatabase {
    
    public func deleteObjects(realm: Realm, objects: [Object], completion: ((_ realm: Realm?) -> Void)? = nil) throws {
        
        guard objects.count > 0 else {
            completion?(nil)
            return
        }
        
        try realm.write {
            
            realm.delete(objects)
            
            completion?(realm)
        }
    }
}
