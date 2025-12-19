//
//  RealmDatabaseTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Testing
@testable import RepositorySync
import RealmSwift
import Combine

@Suite(.serialized)
struct RealmDatabaseTests {
        
    private let allObjectIds: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        
    @Test()
    func getObjectById() async throws {
        
        let database = try getSharedDatabase()
                
        let object: MockRealmObject? = try database.getObject(id: "0")
                
        #expect(object != nil)
    }
    
    @Test()
    func getObjectsByIds() async throws {
        
        let database = try getSharedDatabase()
                
        let ids: [String] = ["6", "4", "2"]
        
        let objects: [MockRealmObject] = try database.getObjects(
            ids: ids,
            sortBykeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false)
        )
                
        #expect(objects.map { $0.id } == ids)
    }
    
    @Test()
    func getObjectByFilter() async throws {
        
        let database = try getSharedDatabase()
                
        let predicate = NSPredicate(format: "\(#keyPath(MockRealmObject.position)) == %@", NSNumber(value: 0))
        
        let query = RealmDatabaseQuery.filter(filter: predicate)
        
        let objects: [MockRealmObject] = try database.getObjects(query: query)
                
        #expect(objects.count == 1)
        #expect(objects.first?.id == "0")
    }
    
    @Test()
    func getObjectsBySortAscendingTrue() async throws {
        
        let database = try getSharedDatabase()
                        
        let query = RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: true))
        
        let objects: [MockRealmObject] = Array(try database.getObjectsResults(query: query))
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    }
    
    @Test()
    func getObjectsBySortAscendingFalse() async throws {
        
        let database = try getSharedDatabase()
                        
        let query = RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false))
        
        let objects: [MockRealmObject] = try database.getObjects(query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
    }
    
    @Test()
    func getObjectByFilterAndSort() async throws {
        
        let database = try getSharedDatabase()
                
        let isEvenPosition = NSPredicate(format: "\(#keyPath(MockRealmObject.isEvenPosition)) == %@", NSNumber(value: true))
        
        let query = RealmDatabaseQuery(
            filter: isEvenPosition,
            sortByKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false)
        )
        
        let objects: [MockRealmObject] = try database.getObjects(query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [8, 6, 4, 2, 0])
    }
    
    @Test()
    func writeToExistingObjects() async throws {
        
        let database = try getSharedDatabase()
                
        try database.writeObjects(writeClosure: { realm in
            
            let objects: [MockRealmObject] = database.getObjects(realm: realm, query: nil)
            
            for object in objects {
                object.position = -9999
            }
            
            return RealmDatabaseWrite(updateObjects: objects, deleteObjects: nil)
            
        }, updatePolicy: .modified)
        
        let objects: [MockRealmObject] = try database.getObjects(query: nil)
                
        #expect(objects.first?.position == -9999)
        #expect(objects.last?.position == -9999)
    }
    
    @Test()
    func writeNewObjects() async throws {
        
        let database = try getSharedDatabase()
                
        let uniqueId: String = UUID().uuidString
        
        let newObject = MockRealmObject()
        newObject.id = uniqueId
                
        let newObjects: [MockRealmObject] = [
            newObject
        ]
        
        try database.writeObjects(writeClosure: { realm in
            return RealmDatabaseWrite(updateObjects: newObjects, deleteObjects: nil)
        }, updatePolicy: .modified)
        
        let object: MockRealmObject = try #require(try database.getObject(id: uniqueId))
                
        #expect(object.id == uniqueId)
    }
    
    @Test()
    @MainActor func writeNewObjectsAsync()  async throws {
        
        let database = try getSharedDatabase()
                
        let uniqueId: String = UUID().uuidString
                
        await confirmation(expectedCount: 1) { confirmation in
            
            await withCheckedContinuation { continuation in
                
                let timeoutTask = Task {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    continuation.resume(returning: ())
                }
                
                let newObject = MockRealmObject()
                newObject.id = uniqueId
                
                let newObjects: [MockRealmObject] = [
                    newObject
                ]
                
                database.writeAsync(writeClosure: { (realm: Realm) in
                    realm.add(newObjects, update: .modified)
                }, completion: { (result: Result<Realm, Error>) in
                    
                    DispatchQueue.main.async {
                        // Place inside a sink or other async closure:
                        confirmation()
                        
                        // When finished be sure to call:
                        timeoutTask.cancel()
                        continuation.resume(returning: ())
                    }
                })
            }
        }
        
        let object: MockRealmObject = try #require(try database.getObject(id: uniqueId))
                
        #expect(object.id == uniqueId)
    }
    
    @Test()
    func writeNewAndDeleteExistingObjects() async throws {
                
        let database = try getSharedDatabase()
                
        let newObjectIds: [String] = ["0", "10", "11", "12"]
        
        try database.writeObjects(
            writeClosure: { (realm: Realm) in
                
                let existingObjects: [MockRealmObject] = database.getObjects(realm: realm, query: nil)
                
                let newObjects: [MockRealmObject] = newObjectIds.compactMap {
                    let object = MockRealmObject()
                    object.id = $0
                    return object
                }
                                
                return RealmDatabaseWrite(updateObjects: newObjects, deleteObjects: existingObjects)
            },
            updatePolicy: .modified)
     
        let query = RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: true))
        
        let objects: [MockRealmObject] = try database.getObjects(query: query)
                
        #expect(objects.map { $0.id } == ["0", "10", "11", "12"])
    }
    
    @Test()
    func deleteObject() async throws {
        
        let database = try getSharedDatabase()
        
        let realm: Realm = try database.openRealm()
        
        let objectId: String = "0"
        
        let object: MockRealmObject = try #require(database.getObject(realm: realm, id: objectId))
        
        try database.writeObjects(realm: realm, writeClosure: { (realm: Realm) in
            return RealmDatabaseWrite(updateObjects: [], deleteObjects: [object])
        }, updatePolicy: .modified)
                    
        let objectAfterDelete: MockRealmObject? = database.getObject(realm: realm, id: objectId)
                
        #expect(objectAfterDelete == nil)
    }
    
    @Test()
    func deleteObjects() async throws {
        
        let database = try getSharedDatabase()
        
        let realm: Realm = try database.openRealm()
                
        let currentObjects: [MockRealmObject] = database.getObjects(realm: realm, query: nil)
                
        #expect(currentObjects.count > 0)
        
        try database.writeObjects(realm: realm, writeClosure: { (realm: Realm) in
            
            return RealmDatabaseWrite(updateObjects: [], deleteObjects: currentObjects)
        }, updatePolicy: .modified)
                
        let objectsAfterDelete: [MockRealmObject] = database.getObjects(realm: realm, query: nil)
                        
        #expect(objectsAfterDelete.count == 0)
    }
    
    @Test()
    func willNotDeleteObjectsWhenObjectsIsEmpty() async throws {
        
        let database = try getSharedDatabase()
        
        let realm: Realm = try database.openRealm()
        
        let query = RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false))
        
        let currentObjects: [MockRealmObject] = database.getObjects(realm: realm, query: query)
        
        try database.writeObjects(realm: realm, writeClosure: { (realm: Realm) in
            
            return RealmDatabaseWrite(updateObjects: [], deleteObjects: [])
        }, updatePolicy: .modified)
                
        let objectsAfterDelete: [MockRealmObject] = database.getObjects(realm: realm, query: query)
                
        #expect(currentObjects == objectsAfterDelete)
    }
}

extension RealmDatabaseTests {
    
    private func getSharedDatabase() throws -> RealmDatabase {
        
        let objects: [MockRealmObject] = allObjectIds.map {
            MockRealmObject.createFrom(interface: MockDataModel.createFromIntId(id: $0))
        }
        
        let directoryName: String = "realm_\(String(describing: RealmDatabaseTests.self))"
        
        return try MockRealmDatabase().createDatabase(directoryName: directoryName, objects: objects, shouldDeleteExistingObjects: true)
    }
}
