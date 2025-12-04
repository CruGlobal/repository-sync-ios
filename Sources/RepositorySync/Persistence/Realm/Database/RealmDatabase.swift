//
//  RealmDatabase.swift
//  RepositorySync
//
//  Created by Levi Eggert on 3/20/20.
//  Copyright © 2020 Cru. All rights reserved.
//

import Foundation
import RealmSwift
import Combine

open class RealmDatabase {
    
    private let databaseConfiguration: RealmDatabaseConfiguration
    private let config: Realm.Configuration
    private let realmInstanceCreator: RealmInstanceCreator
    
    public init(databaseConfiguration: RealmDatabaseConfiguration, realmInstanceCreationType: RealmInstanceCreationType = .alwaysCreatesANewRealmInstance) {
        
        self.databaseConfiguration = databaseConfiguration
        config = databaseConfiguration.toRealmConfig()
        realmInstanceCreator = RealmInstanceCreator(config: config, creationType: realmInstanceCreationType)
        
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
    
    public func openRealm() -> Realm {
        
        return realmInstanceCreator.createRealm()
    }
    
    public func background(async: @escaping ((_ realm: Realm) -> Void)) {
        
        realmInstanceCreator.createBackgroundRealm(async: async)
    }
}

// MARK: - Get Objects

extension RealmDatabase {
    
    public func getObject<T: IdentifiableRealmObject>(id: String) -> T? {
          
        let realm: Realm = openRealm()
        
        return getObject(realm: realm, id: id)
    }
    
    public func getObject<T: IdentifiableRealmObject>(realm: Realm, id: String) -> T? {
        
        let realmObject: T? = realm.object(ofType: T.self, forPrimaryKey: id)
        
        return realmObject
    }
    
    public func getObjects<T: IdentifiableRealmObject>(query: RealmDatabaseQuery?) -> [T] {
        
        return getObjects(realm: openRealm(), query: query)
    }
    
    public func getObjects<T: IdentifiableRealmObject>(realm: Realm, query: RealmDatabaseQuery?) -> [T] {
        
        return Array(getObjectsResults(realm: realm, query: query))
    }
    
    public func getObjectsResults<T: IdentifiableRealmObject>(query: RealmDatabaseQuery?) -> Results<T> {
        
        return getObjectsResults(realm: openRealm(), query: query)
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

// MARK: - Write Objects

extension RealmDatabase {
    
    public func writeObjects(writeClosure: ((_ realm: Realm) -> [IdentifiableRealmObject]), updatePolicy: Realm.UpdatePolicy, shouldAddObjectsToRealm: Bool = true) throws {
        
        try writeObjects(realm: openRealm(), writeClosure: writeClosure, updatePolicy: updatePolicy)
    }
    
    public func writeObjectsPublisher(writeClosure: @escaping ((_ realm: Realm) -> [IdentifiableRealmObject]), updatePolicy: Realm.UpdatePolicy, shouldAddObjectsToRealm: Bool = true) -> AnyPublisher<Void, Error> {
        
        return Future { promise in
            
            self.background { realm in
                
                do {
                    
                    try self.writeObjects(realm: realm, writeClosure: writeClosure, updatePolicy: updatePolicy)
                    
                    promise(.success(Void()))
                }
                catch let error {
                    
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func writeObjects(realm: Realm, writeClosure: ((_ realm: Realm) -> [IdentifiableRealmObject]), updatePolicy: Realm.UpdatePolicy, shouldAddObjectsToRealm: Bool = true) throws {
        
        try realm.write {
            
            let objects: [IdentifiableRealmObject] = writeClosure(realm)
            
            if shouldAddObjectsToRealm {
                
                realm.add(objects, update: updatePolicy)
            }
        }
    }
}

// MARK: - Delete Objects

extension RealmDatabase {
    
    public func deleteObjects(objects: [Object]) throws {
        
        try deleteObjects(realm: openRealm(), objects: objects)
    }
    
    public func deleteObjects(realm: Realm, objects: [Object]) throws {
        
        try realm.write {
            realm.delete(objects)
        }
    }
    
    public func deleteAllObjects() throws {
        
        let realm: Realm = openRealm()
        
        try deleteAllObjects(realm: realm)
    }
    
    public func deleteAllObjects(realm: Realm) throws {
        
        try realm.write {
            realm.deleteAll()
        }
    }
}
