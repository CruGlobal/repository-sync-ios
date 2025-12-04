//
//  MockRealmDatabase.swift
//  RepositorySync
//
//  Created by Levi Eggert on 3/20/20.
//  Copyright © 2020 Cru. All rights reserved.
//

import Foundation
import RealmSwift
@testable import RepositorySync

class MockRealmDatabase {
    
    private let fileManager: FileManager = FileManager.default
    private let defaultIds: [Int] = [0, 1, 2, 3, 4]
    
    init() {
        
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
    
    func createDatabase(directoryName: String, ids: [Int]? = nil) throws -> RealmDatabase {
        
        try _ = fileManager.createDirectoryIfNotExists(directoryUrl: getDirectory(directoryName: directoryName))
        
        let config = RealmDatabaseConfiguration(
            cacheType: .disk(fileLocation: .fileUrl(url: getFileUrl(directoryName: directoryName)), migrationBlock: { migration, oldSchemaVersion in
            // migration
        }), schemaVersion: 1)
        
        let realmDatabase = RealmDatabase(databaseConfiguration: config)
                
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
        
        try realmDatabase.deleteAllObjects()
        
        try realmDatabase.writeObjects(writeClosure: { realm in
            return objects
        }, updatePolicy: .modified)
        
        return realmDatabase
    }
    
    func deleteDatabase(directoryName: String) throws {
        
        try fileManager.removeUrl(url: getDirectory(directoryName: directoryName))
    }
}
