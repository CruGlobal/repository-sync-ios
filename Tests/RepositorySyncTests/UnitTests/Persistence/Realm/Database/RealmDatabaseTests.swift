//
//  RealmDatabaseTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Testing
@testable import RepositorySync
import RealmSwift

@Suite(.serialized)
struct RealmDatabaseTests {
        
    private let allObjectIds: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    
    @Test()
    func isInMemory() async throws {
        
        let database = try getDatabase()
        
        #expect(database.databaseConfig.isInMemory == false)
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
    
    // MARK: - Write Async With Completion
    
    /*
    
    @Test()
    @MainActor func createObjectsAsyncWithCompletion() async throws {
        
        let database = try getDatabase()
                                
        let uniqueId: String = UUID().uuidString
                
        let newObject = MockRealmObject()
        newObject.id = uniqueId
        
        let newObjects: [MockRealmObject] = [
            newObject
        ]
        
        var objectAfterAdd: MockRealmObject?
        
        try await confirmation(expectedCount: 1) { confirmation in
            
            try await withCheckedThrowingContinuation { continuation in
                
                let timeoutTask = Task {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    continuation.resume(returning: ())
                }
                
                DispatchQueue.main.async {
                    
                    database.asyncWrite.objects(
                        writeClosure: { (realm: Realm) in
                            
                            realm.add(newObjects)
                        },
                        completion: { (result: Result<Realm, Error>) in
                            
                            // Place inside a sink or other async closure:
                            confirmation()
                            
                            switch result {
                            
                            case .success(let realm):
                                objectAfterAdd = database.read.object(realm: realm, id: uniqueId)
                                timeoutTask.cancel()
                                continuation.resume(returning: ())
                            
                            case .failure(let error):
                                timeoutTask.cancel()
                                continuation.resume(throwing: error)
                            }
                        }
                    )
                }
            }
        }
                
        let fetchedObject: MockRealmObject = try #require(objectAfterAdd)
                
        #expect(fetchedObject.id == uniqueId)
    }
    
    @Test()
    @MainActor func updateObjectsAsyncWithCompletion() async throws {
        
        let database = try getDatabase()
        
        var objectsAfterUpdate: [MockRealmObject] = Array()
        
        try await confirmation(expectedCount: 1) { confirmation in
            
            try await withCheckedThrowingContinuation { continuation in
                
                let timeoutTask = Task {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    continuation.resume(returning: ())
                }
                
                DispatchQueue.main.async {
                    
                    database.asyncWrite.objects(
                        writeClosure: { (realm: Realm) in
                            
                            let allObjects: [MockRealmObject] = database.read.objects(realm: realm, query: nil)
                                      
                            for object in allObjects {
                                object.position = -9999
                            }
                            
                            realm.add(allObjects, update: .modified)
                        },
                        completion: { (result: Result<Realm, Error>) in
                            
                            // Place inside a sink or other async closure:
                            confirmation()
                            
                            switch result {
                            
                            case .success(let realm):
                                objectsAfterUpdate = database.read.objects(realm: realm, query: nil)
                                timeoutTask.cancel()
                                continuation.resume(returning: ())
                            
                            case .failure(let error):
                                objectsAfterUpdate = Array()
                                timeoutTask.cancel()
                                continuation.resume(throwing: error)
                            }
                        }
                    )
                }
            }
        }
                                                    
        #expect(objectsAfterUpdate.first?.position == -9999)
        #expect(objectsAfterUpdate.last?.position == -9999)
    }
    
    @Test()
    @MainActor func deleteObjectsAsyncWithCompletion() async throws {
        
        let database = try getDatabase()
        
        let currentObjects: [MockRealmObject] = try database.openRealmAndRead.objects(query: nil)
        
        var objectsAfterDelete: [MockRealmObject] = currentObjects
        
        #expect(currentObjects.count == allObjectIds.count)
                        
        try await confirmation(expectedCount: 1) { confirmation in
            
            try await withCheckedThrowingContinuation { continuation in
                
                let timeoutTask = Task {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    continuation.resume(returning: ())
                }
                
                DispatchQueue.main.async {
                    
                    database.asyncWrite.objects(
                        writeClosure: { (realm: Realm) in
                            
                            let allObjects: [MockRealmObject] = database.read.objects(realm: realm, query: nil)
                            
                            realm.delete(allObjects)
                        },
                        completion: { (result: Result<Realm, Error>) in
                            
                            // Place inside a sink or other async closure:
                            confirmation()
                            
                            switch result {
                                
                            case .success(let realm):
                                objectsAfterDelete = database.read.objects(realm: realm, query: nil)
                                timeoutTask.cancel()
                                continuation.resume(returning: ())
                                
                            case .failure(let error):
                                timeoutTask.cancel()
                                continuation.resume(throwing: error)
                            }
                        }
                    )
                }
            }
        }
                                                  
        #expect(objectsAfterDelete.count == 0)
    }*/
}

extension RealmDatabaseTests {
    
    private func getDatabase() throws -> RealmDatabase {
        
        let objects: [MockRealmObject] = allObjectIds.map {
            MockRealmObject.createFrom(interface: MockDataModel.createFromIntId(id: $0))
        }
                
        let database = try MockRealmDatabase().createDatabase(
            directoryName: "realm_\(String(describing: RealmDatabaseTests.self))",
            objects: objects,
            shouldDeleteExistingObjects: true
        )
        
        return database
    }
}
