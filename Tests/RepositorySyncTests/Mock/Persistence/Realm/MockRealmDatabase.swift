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

    public func createDatabase(directoryName: String, objects: [MockRealmObject], shouldDeleteExistingObjects: Bool) throws -> RealmDatabase {
        
        let database = try createDatabase(directoryName: directoryName)
        
        let realm: Realm = try database.openRealm()
        
        if shouldDeleteExistingObjects {
            
            let existingObjects: [MockRealmObject] = database.getObjects(realm: realm, query: nil)
            
            try database.deleteObjects(realm: realm, objects: existingObjects)
        }
        
        try database.writeObjects(realm: realm, writeClosure: { realm in
            return RealmDatabaseWrite(updateObjects: objects)
        }, updatePolicy: .modified)
        
        return database
    }
    
    public func createDatabase(directoryName: String) throws -> RealmDatabase {
        
        try _ = fileManager.createDirectoryIfNotExists(directoryUrl: getDirectory(directoryName: directoryName))
        
        let database = RealmDatabase(
            fileUrl: getFileUrl(directoryName: directoryName),
            schemaVersion: 1) { migration, oldSchemaVersion in
                
            }
        
        return database
    }
    
    public func deleteDatabase(directoryName: String) throws {
        
        try fileManager.removeUrl(url: getDirectory(directoryName: directoryName))
    }
}
