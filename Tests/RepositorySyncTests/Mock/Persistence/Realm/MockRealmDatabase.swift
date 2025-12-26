//
//  MockRealmDatabase.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
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
        
        try database.write.objects(
            realm: try database.openRealm(),
            writeClosure: { (realm: Realm) in
                
                let existingObjects: [MockRealmObject] = shouldDeleteExistingObjects ? database.read.objects(realm: realm, query: nil) : Array()
                
                return WriteRealmObjects(
                    deleteObjects: existingObjects,
                    addObjects: objects
                )
            },
            updatePolicy: .modified
        )
        
        return database
    }
    
    public func createDatabase(directoryName: String) throws -> RealmDatabase {
        
        try _ = fileManager.createDirectoryIfNotExists(directoryUrl: getDirectory(directoryName: directoryName))
        
        let databaseConfig = RealmDatabaseConfig(
            fileUrl: getFileUrl(directoryName: directoryName),
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                
            }
        )
        
        let database = RealmDatabase(
            databaseConfig: databaseConfig
        )
        
        return database
    }
    
    public func deleteDatabase(directoryName: String) throws {
        
        try fileManager.removeUrl(url: getDirectory(directoryName: directoryName))
    }
}
