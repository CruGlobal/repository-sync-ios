//
//  SwiftDatabaseTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Testing
@testable import RepositorySync
import SwiftData
import Combine

@Suite(.serialized)
struct SwiftDatabaseTests {
        
    private let allObjectIds: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
   
    @available(iOS 17.4, *)
    @Test()
    func getObjectCount() async throws {
        
        let database = try getDatabase()
        
        let context: ModelContext = database.openContext()
        
        let query = SwiftDatabaseQuery(
            fetchDescriptor: FetchDescriptor<MockSwiftObject>()
        )
        
        let objectCount: Int = try database.getObjectCount(context: context, query: query)
                
        #expect(objectCount == allObjectIds.count)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectById() async throws {
        
        let database = try getDatabase()
        
        let context: ModelContext = database.openContext()
        
        let object: MockSwiftObject? = try database.getObject(context: context, id: "0")
        
        #expect(object != nil)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectsByIds() async throws {
        
        let database = try getDatabase()

        let context: ModelContext = database.openContext()
        
        let ids: [String] = ["6", "4", "2"]
        
        let objects: [MockSwiftObject] = try database.getObjects(
            context: context,
            ids: ids,
            sortBy: [SortDescriptor(\MockSwiftObject.position, order: .reverse)]
        )
                
        #expect(objects.map { $0.id } == ids)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectByFilter() async throws {
        
        let database = try getDatabase()
        
        let context: ModelContext = database.openContext()
        
        let positionPredicate = #Predicate<MockSwiftObject> { object in
            object.position == 0
        }
                
        let query = SwiftDatabaseQuery.filter(filter: positionPredicate)
        
        let objects: [MockSwiftObject] = try database.getObjects(context: context, query: query)
                
        #expect(objects.count == 1)
        #expect(objects.first?.id == "0")
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectsBySortAscendingTrue() async throws {
        
        let database = try getDatabase()
                
        let context: ModelContext = database.openContext()
        
        let query = SwiftDatabaseQuery.sort(sortBy: [SortDescriptor(\MockSwiftObject.position, order: .forward)])
                
        let objects: [MockSwiftObject] = try database.getObjects(context: context, query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectsBySortAscendingFalse() async throws {
        
        let database = try getDatabase()
                
        let context: ModelContext = database.openContext()
        
        let query = SwiftDatabaseQuery.sort(sortBy: [SortDescriptor(\MockSwiftObject.position, order: .reverse)])
                
        let objects: [MockSwiftObject] = try database.getObjects(context: context, query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectByFilterAndSort() async throws {
        
        let database = try getDatabase()
        
        let context: ModelContext = database.openContext()
        
        let isEvenPosition = #Predicate<MockSwiftObject> { object in
            object.isEvenPosition == true
        }
        
        let query = SwiftDatabaseQuery(
            filter: isEvenPosition,
            sortBy: [SortDescriptor(\MockSwiftObject.position, order: .reverse)]
        )
        
        let objects: [MockSwiftObject] = try database.getObjects(context: context, query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [8, 6, 4, 2, 0])
    }
    
    @available(iOS 17.4, *)
    @Test()
    func writeToExistingObjects() async throws {
        
        let database = try getDatabase()
        
        let context: ModelContext = database.openContext()
        
        let objectsToUpdate: [MockSwiftObject] = try database.getObjects(context: context, query: nil)
                  
        for object in objectsToUpdate {
            object.position = -9999
        }
        
        try database.writeObjects(context: context, objects: objectsToUpdate)
        
        let objects: [MockSwiftObject] = try database.getObjects(context: context, query: nil)
                
        #expect(objects.first?.position == -9999)
        #expect(objects.last?.position == -9999)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func writeExistingObjectIdsWillNotDuplicate() async throws {
        
        let database = try getDatabase()
        
        let context: ModelContext = database.openContext()
        
        let idToAdd: String = "5"
        let positionToUpdate: Int = -73898
        
        let idPredicate = #Predicate<MockSwiftObject> { object in
            object.id == idToAdd
        }
        
        let query = SwiftDatabaseQuery.filter(filter: idPredicate)
        
        let currentObjects: [MockSwiftObject] = try database.getObjects(context: context, query: query)
        let currentObject: MockSwiftObject = try #require(currentObjects.first)
        
        #expect(currentObjects.count == 1)
        #expect(currentObject.position == 5)
        
        let objectsToAdd: [MockSwiftObject] = [
            MockSwiftObject.createObject(id: idToAdd, position: positionToUpdate)
        ]
        
        try database.writeObjects(context: context, objects: objectsToAdd)
        
        let objectsAfterWrite: [MockSwiftObject] = try database.getObjects(context: context, query: query)
        let objectAfterWrite: MockSwiftObject = try #require(objectsAfterWrite.first)
                
        #expect(objectsAfterWrite.count == 1)
        #expect(objectAfterWrite.position == positionToUpdate)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func writeNewObjects() async throws {
        
        let database = try getDatabase()
        
        let context: ModelContext = database.openContext()
        
        let uniqueId: String = UUID().uuidString
        
        let newObjects: [MockSwiftObject] = [
            MockSwiftObject.createObject(id: uniqueId)
        ]
        
        try database.writeObjects(context: context, objects: newObjects)
        
        let object: MockSwiftObject = try #require(try database.getObject(context: context, id: uniqueId))
                
        #expect(object.id == uniqueId)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func writeNewAndDeleteExistingObjectsPublisher() async throws {
                
        let database = try getDatabase()
        
        let context: ModelContext = database.openContext()
        
        let newObjectIds: [String] = ["10", "11", "12"]
        
        let existingObjects: [MockSwiftObject] = try database.getObjects(context: context, query: nil)
        
        let newObjects: [MockSwiftObject] = newObjectIds.compactMap {
            
            guard let position = Int($0) else {
                return nil
            }
            
            return MockSwiftObject.createObject(id: $0, position: position)
        }
        
        try database.writeObjects(
            context: context,
            objects: newObjects,
            deleteObjects: existingObjects
        )
        
        let query = SwiftDatabaseQuery.sort(sortBy: [SortDescriptor(\MockSwiftObject.position, order: .forward)])
                
        let objects: [MockSwiftObject] = try database.getObjects(context: context, query: query)
                
        #expect(objects.map { $0.id } == ["10", "11", "12"])
    }
    
    @available(iOS 17.4, *)
    @Test()
    func willNotWriteWhenObjectsIsEmpty() async throws {
        
        let database = try getDatabase()
        
        let context: ModelContext = database.openContext()
        
        let query = SwiftDatabaseQuery.sort(sortBy: [SortDescriptor(\MockSwiftObject.position, order: .reverse)])
        
        let currentObjects: [MockSwiftObject] = try database.getObjects(context: context, query: query)
        
        try database.writeObjects(context: context, objects: [])
        
        let objectsAfterUpdate: [MockSwiftObject] = try database.getObjects(context: context, query: query)
                
        #expect(currentObjects == objectsAfterUpdate)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func deleteObject() async throws {
        
        let database = try getDatabase()
        
        let context: ModelContext = database.openContext()
        
        let objectId: String = "0"
        
        let object: MockSwiftObject = try #require(try database.getObject(context: context, id: objectId))
        
        try database.deleteObjects(context: context, objects: [object])
            
        let objectAfterDelete: MockSwiftObject? = try database.getObject(context: context, id: objectId)
                
        #expect(objectAfterDelete == nil)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func deleteObjects() async throws {
        
        let database = try getDatabase()
              
        let context: ModelContext = database.openContext()
        
        let currentObjects: [MockSwiftObject] = try database.getObjects(context: context, query: nil)
                
        #expect(currentObjects.count > 0)
        
        try database.deleteObjects(context: context, objects: currentObjects)
        
        let objectsAfterDelete: [MockSwiftObject] = try database.getObjects(context: context, query: nil)
                        
        #expect(objectsAfterDelete.count == 0)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func willNotDeleteObjectsWhenObjectsIsEmpty() async throws {
        
        let database = try getDatabase()
        
        let context: ModelContext = database.openContext()
        
        let query = SwiftDatabaseQuery.sort(sortBy: [SortDescriptor(\MockSwiftObject.position, order: .reverse)])
        
        let currentObjects: [MockSwiftObject] = try database.getObjects(context: context, query: query)
        
        try database.deleteObjects(context: context, objects: [])
        
        let objectsAfterDelete: [MockSwiftObject] = try database.getObjects(context: context, query: query)
                
        #expect(currentObjects == objectsAfterDelete)
    }
}

extension SwiftDatabaseTests {
    
    @available(iOS 17.4, *)
    private func getDatabase() throws -> SwiftDatabase {
        
        var objects: [MockSwiftObject] = Array()
        
        for id in allObjectIds {
            
            objects.append(
                MockSwiftObject.createObject(
                    id: String(id),
                    position: id
                )
            )
        }
                
        return try MockSwiftDatabase().getSharedDatabase(objects: objects, shouldDeleteExistingObjects: true)
    }
}
