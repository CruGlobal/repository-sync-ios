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

struct RealmDatabaseTests {
        
    private let allObjectIds: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        
    @Test()
    func getObjectById() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        let realm: Realm = try database.openRealm()
        
        let object: MockRealmObject? = database.getObject(realm: realm, id: "0")
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(object != nil)
    }
    
    @Test()
    func getObjectsByIds() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        let realm: Realm = try database.openRealm()
        
        let ids: [String] = ["6", "4", "2"]
        
        let objects: [MockRealmObject] = database.getObjects(
            realm: realm,
            ids: ids,
            sortBykeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false)
        )
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objects.map { $0.id } == ids)
    }
    
    @Test()
    func getObjectByFilter() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        let realm: Realm = try database.openRealm()
        
        let predicate = NSPredicate(format: "\(#keyPath(MockRealmObject.position)) == %@", NSNumber(value: 0))
        
        let query = RealmDatabaseQuery.filter(filter: predicate)
        
        let objects: [MockRealmObject] = database.getObjects(realm: realm, query: query)
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objects.count == 1)
        #expect(objects.first?.id == "0")
    }
    
    @Test()
    func getObjectsBySortAscendingTrue() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        let realm: Realm = try database.openRealm()
                
        let query = RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: true))
        
        let objects: [MockRealmObject] = Array(database.getObjectsResults(realm: realm, query: query))
        
        let objectPositions: [Int] = objects.map { $0.position }
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objectPositions == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    }
    
    @Test()
    func getObjectsBySortAscendingFalse() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        let realm: Realm = try database.openRealm()
                
        let query = RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false))
        
        let objects: [MockRealmObject] = database.getObjects(realm: realm, query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objectPositions == [9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
    }
    
    @Test()
    func getObjectByFilterAndSort() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        let realm: Realm = try database.openRealm()
        
        let isEvenPosition = NSPredicate(format: "\(#keyPath(MockRealmObject.isEvenPosition)) == %@", NSNumber(value: true))
        
        let query = RealmDatabaseQuery(
            filter: isEvenPosition,
            sortByKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false)
        )
        
        let objects: [MockRealmObject] = database.getObjects(realm: realm, query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objectPositions == [8, 6, 4, 2, 0])
    }
    
    @Test()
    func writeToExistingObjects() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        let realm: Realm = try database.openRealm()
        
        try database.writeObjects(realm: realm, writeClosure: { realm in
            
            let objects: [MockRealmObject] = database.getObjects(realm: realm, query: nil)
            
            for object in objects {
                object.position = -9999
            }
            
            return RealmDatabaseWrite(updateObjects: objects)
            
        }, updatePolicy: .modified)
        
        let objects: [MockRealmObject] = database.getObjects(realm: realm, query: nil)
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objects.first?.position == -9999)
        #expect(objects.last?.position == -9999)
    }
    
    @Test()
    func writeNewObjects() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        let realm: Realm = try database.openRealm()
        
        let uniqueId: String = UUID().uuidString
        
        let newObjects: [MockRealmObject] = [
            MockRealmObject.createObject(id: uniqueId)
        ]
        
        try database.writeObjects(realm: realm, writeClosure: { realm in
            return RealmDatabaseWrite(updateObjects: newObjects)
        }, updatePolicy: .modified)
        
        let object: MockRealmObject = try #require(database.getObject(realm: realm, id: uniqueId))
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(object.id == uniqueId)
    }
    
    @Test()
    func writeToExistingObjectsPublisher() async throws {
        
        var cancellables: Set<AnyCancellable> = Set()
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        var sinkCount: Int = 0
        
        await confirmation(expectedCount: 1) { confirmation in
            
            await withCheckedContinuation { continuation in
                
                let timeoutTask = Task {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    continuation.resume(returning: ())
                }
                
                database.writeObjectsPublisher(writeClosure: { realm in
                    
                    let objects: [MockRealmObject] = database.getObjects(realm: realm, query: nil)
                                    
                    for object in objects {
                        object.position = -9999
                    }
                    
                    return RealmDatabaseWrite(updateObjects: objects)
                    
                }, updatePolicy: .modified)
                .sink { completion in
                    
                    // When finished be sure to call:
                    timeoutTask.cancel()
                    continuation.resume(returning: ())
                    
                } receiveValue: { _ in
                    
                    // Place inside a sink or other async closure:
                    confirmation()
                    
                    sinkCount += 1
                }
                .store(in: &cancellables)
            }
        }
        
        let realm: Realm = try database.openRealm()
        
        let objects: [MockRealmObject] = database.getObjects(realm: realm, query: nil)
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objects.first?.position == -9999)
        #expect(objects.last?.position == -9999)
    }
    
    @Test()
    func writeNewAndDeleteExistingObjectsPublisher() async throws {
        
        var cancellables: Set<AnyCancellable> = Set()
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        let newObjectIds: [String] = ["0", "10", "11", "12"]
        
        var sinkCount: Int = 0
        
        await confirmation(expectedCount: 1) { confirmation in
            
            await withCheckedContinuation { continuation in
                
                let timeoutTask = Task {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    continuation.resume(returning: ())
                }
                
                database.writeObjectsPublisher(writeClosure: { realm in
                    
                    let existingObjects: [MockRealmObject] = database.getObjects(realm: realm, query: nil)
                    
                    let newObjects: [MockRealmObject] = newObjectIds.compactMap {
                        
                        guard let position = Int($0) else {
                            return nil
                        }
                        
                        return MockRealmObject.createObject(id: $0, position: position)
                    }
                                    
                    return RealmDatabaseWrite(updateObjects: newObjects, deleteObjects: existingObjects)
                    
                }, updatePolicy: .modified)
                .sink { completion in
                    
                    // When finished be sure to call:
                    timeoutTask.cancel()
                    continuation.resume(returning: ())
                    
                } receiveValue: { _ in
                    
                    // Place inside a sink or other async closure:
                    confirmation()
                    
                    sinkCount += 1
                }
                .store(in: &cancellables)
            }
        }
        
        let realm: Realm = try database.openRealm()
        
        let query = RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: true))
        
        let objects: [MockRealmObject] = database.getObjects(realm: realm, query: query)
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objects.map { $0.id } == ["10", "11", "12"])
    }
    
    @Test()
    func deleteObject() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        let realm: Realm = try database.openRealm()
        
        let objectId: String = "0"
        
        let object: MockRealmObject = try #require(database.getObject(realm: realm, id: objectId))
        
        try database.deleteObjects(realm: realm, objects: [object])
            
        let objectAfterDelete: MockRealmObject? = database.getObject(realm: realm, id: objectId)
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objectAfterDelete == nil)
    }
    
    @Test()
    func deleteObjects() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        let realm: Realm = try database.openRealm()
                
        let currentObjects: [MockRealmObject] = database.getObjects(realm: realm, query: nil)
                
        #expect(currentObjects.count > 0)
        
        try database.deleteObjects(realm: realm, objects: currentObjects)
        
        let objectsAfterDelete: [MockRealmObject] = database.getObjects(realm: realm, query: nil)
                
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objectsAfterDelete.count == 0)
    }
    
    @Test()
    func willNotDeleteObjectsWhenObjectsIsEmpty() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        let realm: Realm = try database.openRealm()
        
        let query = RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false))
        
        let currentObjects: [MockRealmObject] = database.getObjects(realm: realm, query: query)
        
        try database.deleteObjects(realm: realm, objects: [])
        
        let objectsAfterDelete: [MockRealmObject] = database.getObjects(realm: realm, query: query)
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(currentObjects == objectsAfterDelete)
    }
}

extension RealmDatabaseTests {
    
    private func getUniqueDirectoryName() -> String {
        return UUID().uuidString
    }
    
    private func getDatabase(directoryName: String) throws -> RealmDatabase {
        return try MockRealmDatabase().createDatabase(directoryName: directoryName, ids: allObjectIds)
    }
    
    private func deleteDatabaseDirectory(directoryName: String) throws {
        try MockRealmDatabase().deleteDatabase(directoryName: directoryName)
    }
}
