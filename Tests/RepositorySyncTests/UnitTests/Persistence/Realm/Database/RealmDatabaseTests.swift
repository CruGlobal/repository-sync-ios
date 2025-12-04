//
//  RealmDatabaseTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 3/20/20.
//  Copyright © 2020 Cru. All rights reserved.
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
        
        let object: MockRealmObject? = try database.getObject(id: "0")
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(object != nil)
    }
    
    @Test()
    func getObjectByFilter() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        let predicate = NSPredicate(format: "\(#keyPath(MockRealmObject.position)) == %@", NSNumber(value: 0))
        
        let query = RealmDatabaseQuery.filter(filter: predicate)
        
        let objects: [MockRealmObject] = try database.getObjects(query: query)
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objects.count == 1)
        #expect(objects.first?.id == "0")
    }
    
    @Test()
    func getObjectsBySortAscendingTrue() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
                
        let query = RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: true))
        
        let objects: [MockRealmObject] = Array(try database.getObjectsResults(query: query))
        
        let objectPositions: [Int] = objects.map { $0.position }
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objectPositions == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    }
    
    @Test()
    func getObjectsBySortAscendingFalse() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
                
        let query = RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false))
        
        let objects: [MockRealmObject] = try database.getObjects(query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objectPositions == [9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
    }
    
    @Test()
    func getObjectByFilterAndSort() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        let isEvenPosition = NSPredicate(format: "\(#keyPath(MockRealmObject.isEvenPosition)) == %@", NSNumber(value: true))
        
        let query = RealmDatabaseQuery(
            filter: isEvenPosition,
            sortByKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false)
        )
        
        let objects: [MockRealmObject] = try database.getObjects(query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objectPositions == [8, 6, 4, 2, 0])
    }
    
    @Test()
    func writeToExistingObjects() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        try database.writeObjects(writeClosure: { realm in
            
            let objects: [MockRealmObject]
            
            do {
                objects = try database.getObjects(query: nil)
            }
            catch let error {
                objects = Array()
            }
            
            for object in objects {
                object.position = -9999
            }
            
            return objects
            
        }, updatePolicy: .modified)
        
        let objects: [MockRealmObject] = try database.getObjects(query: nil)
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objects.first?.position == -9999)
        #expect(objects.last?.position == -9999)
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
                    
                    let objects: [MockRealmObject]
                    
                    do {
                        objects = try database.getObjects(query: nil)
                    }
                    catch let error {
                        objects = Array()
                    }
                                        
                    for object in objects {
                        object.position = -9999
                    }
                    
                    return objects
                    
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
        
        let objects: [MockRealmObject] = try database.getObjects(query: nil)
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objects.first?.position == -9999)
        #expect(objects.last?.position == -9999)
    }
    
    @Test()
    func deleteObject() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
        
        let objectId: String = "0"
        
        let object: MockRealmObject? = try database.getObject(id: objectId)
        
        #expect(object != nil)
        
        if let object = object {
            try database.deleteObjects(objects: [object])
        }
            
        let objectAfterDelete: MockRealmObject? = try database.getObject(id: objectId)
        
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objectAfterDelete == nil)
    }
    
    @Test()
    func deleteAllObjects() async throws {
        
        let directoryName: String = getUniqueDirectoryName()
        
        let database = try getDatabase(directoryName: directoryName)
                
        let currentObjects: [MockRealmObject] = try database.getObjects(query: nil)
                
        #expect(currentObjects.count > 0)
        
        do {
            try database.deleteAllObjects()
        }
        catch let error {
            throw error
        }
        
        let objectsAfterDelete: [MockRealmObject] = try database.getObjects(query: nil)
                
        try deleteDatabaseDirectory(directoryName: directoryName)
        
        #expect(objectsAfterDelete.count == 0)
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
