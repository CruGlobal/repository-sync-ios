//
//  InMemoryRealmDatabaseTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Testing
@testable import RepositorySync
import RealmSwift

struct InMemoryRealmDatabaseTests {
        
    private let allObjectIds: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    
    @Test()
    func isInMemory() async throws {
        
        let database = try getDatabase()
        
        #expect(database.databaseConfig.isInMemory == true)
    }
    
    // MARK: - Read
    
    @Test()
    func getObjectById() async throws {
        
        let database = try getDatabase()
                
        let object: MockRealmObject? = try database.openRealmAndRead.object(id: "0")
                
        #expect(object != nil)
    }
    
    @Test()
    func getObjectsByIds() async throws {
        
        let database = try getDatabase()
                        
        let ids: [String] = ["6", "4", "2"]
        
        let objects: [MockRealmObject] = try database.openRealmAndRead.objects(
            ids: ids,
            sortBykeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false)
        )
                
        #expect(objects.map { $0.id } == ids)
    }
    
    @Test()
    func getObjectByFilter() async throws {
        
        let database = try getDatabase()
                
        let predicate = NSPredicate(format: "\(#keyPath(MockRealmObject.position)) == %@", NSNumber(value: 0))
        
        let query = RealmDatabaseQuery.filter(filter: predicate)
        
        let objects: [MockRealmObject] = try database.openRealmAndRead.objects(query: query)
                
        #expect(objects.count == 1)
        #expect(objects.first?.id == "0")
    }
    
    @Test()
    func getObjectsBySortAscendingTrue() async throws {
        
        let database = try getDatabase()
                        
        let query = RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: true))
        
        let objects: [MockRealmObject] = Array(try database.openRealmAndRead.results(query: query))
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    }
    
    @Test()
    func getObjectsBySortAscendingFalse() async throws {
        
        let database = try getDatabase()
                        
        let query = RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false))
        
        let objects: [MockRealmObject] = try database.openRealmAndRead.objects(query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
    }
    
    @Test()
    func getObjectByFilterAndSort() async throws {
        
        let database = try getDatabase()
                
        let isEvenPosition = NSPredicate(format: "\(#keyPath(MockRealmObject.isEvenPosition)) == %@", NSNumber(value: true))
        
        let query = RealmDatabaseQuery(
            filter: isEvenPosition,
            sortByKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false)
        )
        
        let objects: [MockRealmObject] = try database.openRealmAndRead.objects(query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [8, 6, 4, 2, 0])
    }
    
    // MARK: - Write
    
    @Test()
    func createObjects() async throws {
        
        let database = try getDatabase()
        
        let realm: Realm = try database.openRealm()
                        
        let uniqueId: String = UUID().uuidString
                
        let newObject = MockRealmObject()
        newObject.id = uniqueId
        
        let newObjects: [MockRealmObject] = [
            newObject
        ]
        
        try database.write.objects(realm: realm, writeClosure: { (realm: Realm) in
            return WriteRealmObjects(deleteObjects: nil, addObjects: newObjects)
        }, updatePolicy: .modified)
        
        let fetchedObject: MockRealmObject = try #require(database.read.object(realm: realm, id: uniqueId))
                
        #expect(fetchedObject.id == uniqueId)
    }
    
    @Test()
    func updateObjects() async throws {
        
        let database = try getDatabase()
        
        let realm: Realm = try database.openRealm()
                
        try database.write.objects(realm: realm, writeClosure: { (realm: Realm) in
            
            let allObjects: [MockRealmObject] = database.read.objects(realm: realm, query: nil)
                      
            for object in allObjects {
                object.position = -9999
            }
            
            return WriteRealmObjects(deleteObjects: nil, addObjects: allObjects)
            
        }, updatePolicy: .modified)
                
        let objects: [MockRealmObject] = database.read.objects(realm: realm, query: nil)
                
        #expect(objects.first?.position == -9999)
        #expect(objects.last?.position == -9999)
    }
    
    @Test()
    func deleteObjects() async throws {
        
        let database = try getDatabase()
        
        let realm: Realm = try database.openRealm()
                        
        let allObjects: [MockRealmObject] = database.read.objects(realm: realm, query: nil)
                
        #expect(allObjects.count == allObjectIds.count)
        
        try database.write.objects(realm: realm, writeClosure: { (realm: Realm) in
            return WriteRealmObjects(deleteObjects: allObjects, addObjects: nil)
        }, updatePolicy: .modified)
                
        let objectsAfterDelete: [MockRealmObject] = database.read.objects(realm: realm, query: nil)
                        
        #expect(objectsAfterDelete.count == 0)
    }
    
    // MARK: - Write Async With Completion Will Error
    
    @Test()
    @MainActor func createObjectsAsyncWillErrorSinceNotSupportedOnInMemoryRealms() async throws {
        
        let database = try getDatabase()
                                
        let uniqueId: String = UUID().uuidString
                
        let newObject = MockRealmObject()
        newObject.id = uniqueId
        
        let newObjects: [MockRealmObject] = [
            newObject
        ]
        
        var errorRef: Error?
        
        await confirmation(expectedCount: 1) { confirmation in
            
            await withCheckedContinuation { continuation in
                
                let timeoutTask = Task {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    continuation.resume(returning: ())
                }
                
                database.asyncWrite.objects(
                    writeClosure: { (realm: Realm) in
                        
                        realm.add(newObjects)
                        
                        // Place inside a sink or other async closure:
                        confirmation()
                        
                        errorRef = nil
                        
                        timeoutTask.cancel()
                        continuation.resume(returning: ())
                    },
                    writeError: { (error: Error) in
                        
                        // Place inside a sink or other async closure:
                        confirmation()
                        
                        errorRef = error
                        
                        timeoutTask.cancel()
                        continuation.resume(returning: ())
                    }
                )
            }
        }
                                
        #expect(errorRef != nil)
    }
}

extension InMemoryRealmDatabaseTests {

    private func getDatabase() throws -> RealmDatabase {
        
        let objects: [MockRealmObject] = allObjectIds.map {
            MockRealmObject.createFrom(interface: MockDataModel.createFromIntId(id: $0))
        }
        
        let database = RealmDatabase(
            databaseConfig: RealmDatabaseConfig.createInMemoryConfig()
        )
        
        let realm: Realm = try database.openRealm()
        
        try database.write.objects(
            realm: realm,
            writeClosure: { (realm: Realm) in
                return WriteRealmObjects(
                    deleteObjects: nil,
                    addObjects: objects
                )
            },
            updatePolicy: .modified
        )

        return database
    }
}
