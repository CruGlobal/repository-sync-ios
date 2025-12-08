//
//  MockRealmDatabase.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift
@testable import RepositorySync

public class MockRealmDatabase {
    
    private let fileManager: FileManager = FileManager.default
    private let defaultIds: [Int] = [0, 1, 2, 3, 4]
    
    public init() {
        
    }
    
    private func getDirectory(directoryName: String) -> URL {
        
        return fileManager.temporaryDirectory
            .appendingPathComponent(directoryName)
    }
    
    private func getFileUrl(directoryName: String) -> URL {
        
        return getDirectory(directoryName: directoryName)
            .appendingPathComponent("realm_tests")
            .appendingPathExtension("realm")
    }
    
    public func createDatabase(directoryName: String, ids: [Int]? = nil) throws -> RealmDatabase {
        
        let idsToCreate: [Int] = ids ?? defaultIds
        
        var objects: [MockRealmObject] = Array()
        
        for id in idsToCreate {
            
            objects.append(
                MockRealmObject.createObject(
                    id: String(id),
                    position: id
                )
            )
        }
        
        return try createDatabase(directoryName: directoryName, objects: objects)
    }
    
    public func createDatabase(directoryName: String, objects: [MockRealmObject]) throws -> RealmDatabase {
        
        try _ = fileManager.createDirectoryIfNotExists(directoryUrl: getDirectory(directoryName: directoryName))
        
        let database = RealmDatabase(
            fileUrl: getFileUrl(directoryName: directoryName),
            schemaVersion: 1) { migration, oldSchemaVersion in
                
            }
        
        let realm: Realm = try database.openRealm()
                
        try database.writeObjects(realm: realm, writeClosure: { realm in
            return RealmDatabaseWrite(updateObjects: objects)
        }, updatePolicy: .modified)
        
        return database
    }
    
    public func deleteDatabase(directoryName: String) throws {
        
        try fileManager.removeUrl(url: getDirectory(directoryName: directoryName))
    }
}
