//
//  InMemoryRealmDatabaseTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Testing
@testable import RepositorySync
import RealmSwift

@MainActor struct InMemoryRealmDatabaseTests {
    
    private let allObjectIds: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    
    @Test()
    func getObject0() async throws {
        
        let database = try getRealmDatabase()
        
        let id: String = "0"
        
        let object: MockRealmObject = try #require(try database.getObject(id: id))
        
        #expect(object.id == id)
    }
    
    @Test()
    func getObject1() async throws {
        
        let database = try getRealmDatabase()
        
        let id: String = "4"
        
        let object: MockRealmObject = try #require(try database.getObject(id: id))
        
        #expect(object.id == id)
    }
    
    @Test()
    func deleteAllObjects() async throws {
        
        let database = try getRealmDatabase()
        
        try database.writeObjects(writeClosure: { realm in
            let objects: [MockRealmObject] = database.getObjects(realm: realm, query: nil)
            return RealmDatabaseWrite(updateObjects: [], deleteObjects: objects)
        }, updatePolicy: .modified)
        
        let objects: [MockRealmObject] = try database.getObjects(query: nil)
        
        #expect(objects.count == 0)
    }
    
    @Test()
    func addNewObjects() async throws {
        
        let database = try getRealmDatabase()
        
        let newObjectIds: [Int] = [10, 11, 12]
        
        try database.writeObjects(writeClosure: { realm in
            let objects: [MockRealmObject] = newObjectIds.map {
                MockRealmObject.createFrom(interface: MockDataModel.createFromIntId(id: $0))
            }
            return RealmDatabaseWrite(updateObjects: objects, deleteObjects: nil)
        }, updatePolicy: .modified)
        
        let allObjectIds: [Int] = allObjectIds + newObjectIds
        
        let allObjects: [MockRealmObject] = try database.getObjects(
            query: RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: true))
        )
        
        let ids: [Int] = allObjects.compactMap {
            guard let intId = Int($0.id) else {
                return nil
            }
            return intId
        }
        
        #expect(ids == allObjectIds)
    }
}

extension InMemoryRealmDatabaseTests {
    
    @MainActor private func getRealmDatabase() throws -> RealmDatabase {
        
        let objects: [MockRealmObject] = allObjectIds.map {
            MockRealmObject.createFrom(interface: MockDataModel.createFromIntId(id: $0))
        }
        
        let realmDatabase = try InMemoryRealmDatabase()
        
        try realmDatabase.writeObjects(writeClosure: { (realm: Realm) in
            return RealmDatabaseWrite(updateObjects: objects, deleteObjects: nil)
        }, updatePolicy: .modified)
        
        return realmDatabase
    }
}
