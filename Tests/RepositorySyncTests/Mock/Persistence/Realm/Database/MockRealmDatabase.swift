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
    
    private static let defaultIds: [Int] = [0, 1, 2, 3, 4]
    
    static func createDatabase(ids: [Int]? = nil) throws -> RealmDatabase {
        
        let config = RealmDatabaseConfiguration(
            cacheType: .disk(fileName: UUID().uuidString, migrationBlock: { migration, oldSchemaVersion in
            // migration
        }), schemaVersion: 1)
        
        let realmDatabase = RealmDatabase(databaseConfiguration: config)
                
        let idsToCreate: [Int] = ids ?? Self.defaultIds
        
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
}
