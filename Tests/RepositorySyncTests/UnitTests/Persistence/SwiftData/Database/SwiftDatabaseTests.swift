//
//  SwiftDatabaseTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Testing
@testable import RepositorySync
import SwiftData

@Suite(.serialized)
struct SwiftDatabaseTests {
    
    private let allObjectIds: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    
    // MARK: - Read
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectCount() async throws {
        
        let database = try getDatabase()
        
        let query = SwiftDatabaseQuery(
            fetchDescriptor: FetchDescriptor<MockSwiftObject>()
        )
        
        let objectCount: Int = try database.openContextAndRead.objectCount(query: query)
                
        #expect(objectCount == allObjectIds.count)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectById() async throws {
        
        let database = try getDatabase()
        
        let object: MockSwiftObject? = try database.openContextAndRead.object(id: "0")
        
        #expect(object != nil)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectsByIds() async throws {
        
        let database = try getDatabase()
        
        let ids: [String] = ["6", "4", "2"]
        
        let objects: [MockSwiftObject] = try database.openContextAndRead.objects(
            ids: ids,
            sortBy: [SortDescriptor(\MockSwiftObject.position, order: .reverse)]
        )
                
        #expect(objects.map { $0.id } == ids)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectByFilter() async throws {
        
        let database = try getDatabase()
        
        let positionPredicate = #Predicate<MockSwiftObject> { object in
            object.position == 0
        }
                
        let query = SwiftDatabaseQuery.filter(filter: positionPredicate)
        
        let objects: [MockSwiftObject] = try database.openContextAndRead.objects(query: query)
                
        #expect(objects.count == 1)
        #expect(objects.first?.id == "0")
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectsBySortAscendingTrue() async throws {
        
        let database = try getDatabase()
        
        let query = SwiftDatabaseQuery.sort(sortBy: [SortDescriptor(\MockSwiftObject.position, order: .forward)])
                
        let objects: [MockSwiftObject] = try database.openContextAndRead.objects(query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectsBySortAscendingFalse() async throws {
        
        let database = try getDatabase()
        
        let query = SwiftDatabaseQuery.sort(sortBy: [SortDescriptor(\MockSwiftObject.position, order: .reverse)])
                
        let objects: [MockSwiftObject] = try database.openContextAndRead.objects(query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectByFilterAndSort() async throws {
        
        let database = try getDatabase()
        
        let isEvenPosition = #Predicate<MockSwiftObject> { object in
            object.isEvenPosition == true
        }
        
        let query = SwiftDatabaseQuery(
            filter: isEvenPosition,
            sortBy: [SortDescriptor(\MockSwiftObject.position, order: .reverse)]
        )
        
        let objects: [MockSwiftObject] = try database.openContextAndRead.objects(query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [8, 6, 4, 2, 0])
    }
    
    // MARK: - Write
    
    @available(iOS 17.4, *)
    @Test()
    func createObjects() async throws {
        
        let database = try getDatabase()
        
        let context: ModelContext = database.openContext()
        
        let uniqueId: String = UUID().uuidString
                
        let newObject = MockSwiftObject()
        newObject.id = uniqueId
        
        let newObjects: [MockSwiftObject] = [
            newObject
        ]
        
        let writeObjects = WriteSwiftObjects(deleteObjects: nil, insertObjects: newObjects)
        
        try database.write.objects(context: context, writeObjects: writeObjects)
        
        let fetchedObject: MockSwiftObject = try #require(try database.read.object(context: context, id: uniqueId))
                
        #expect(fetchedObject.id == uniqueId)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func updateObjects() async throws {
        
        let database = try getDatabase()
        
        let context: ModelContext = database.openContext()
        
        let allObjects: [MockSwiftObject] = try database.read.objects(context: context, query: nil)
                  
        for object in allObjects {
            object.position = -9999
        }
        
        let writeObjects = WriteSwiftObjects(deleteObjects: nil, insertObjects: allObjects)
        
        try database.write.objects(context: context, writeObjects: writeObjects)
        
        let objects: [MockSwiftObject] = try database.read.objects(context: context, query: nil)
                
        #expect(objects.first?.position == -9999)
        #expect(objects.last?.position == -9999)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func deleteObjects() async throws {
        
        let database = try getDatabase()
        
        let context: ModelContext = database.openContext()
        
        let allObjects: [MockSwiftObject] = try database.read.objects(context: context, query: nil)
                
        #expect(allObjects.count == allObjectIds.count)
        
        let writeObjects = WriteSwiftObjects(deleteObjects: allObjects, insertObjects: nil)
        
        try database.write.objects(context: context, writeObjects: writeObjects)
        
        let objectsAfterDelete: [MockSwiftObject] = try database.read.objects(context: context, query: nil)
                        
        #expect(objectsAfterDelete.count == 0)
    }
    
    // MARK: - Write Async

//    @available(iOS 17.4, *)
//    @Test()
//    func createObjectsAsync() async throws {
//               
//        let database = try getDatabase()
//                        
//        let uniqueId: String = UUID().uuidString
//                
//        let newObject = MockSwiftObject()
//        newObject.id = uniqueId
//        
//        let newObjects: [MockSwiftObject] = [
//            newObject
//        ]
//        
//        let writeObjects = WriteSwiftObjects(deleteObjects: nil, insertObjects: newObjects)
//        
//        try database.asyncWrite.objects(writeObjects: writeObjects)
//        
//        let fetchedObject: MockSwiftObject = try #require(try database.read.object(context: database.asyncWrite.context, id: uniqueId))
//                
//        #expect(fetchedObject.id == uniqueId)
//    }
//    
//    @available(iOS 17.4, *)
//    @Test()
//    func updateObjectsAsync() async throws {
//                
//        let database = try getDatabase()
//        
//        let allObjects: [MockSwiftObject] = try database.read.objects(context: database.asyncWrite.context, query: nil)
//                  
//        for object in allObjects {
//            object.position = -9999
//        }
//        
//        let writeObjects = WriteSwiftObjects(deleteObjects: nil, insertObjects: allObjects)
//        
//        try database.asyncWrite.objects(writeObjects: writeObjects)
//        
//        let objects: [MockSwiftObject] = try database.read.objects(context: database.asyncWrite.context, query: nil)
//                
//        #expect(objects.first?.position == -9999)
//        #expect(objects.last?.position == -9999)
//    }
//    
//    @available(iOS 17.4, *)
//    @Test()
//    func deleteObjectsAsync() async throws {
//                
//        let database = try getDatabase()
//                
//        let allObjects: [MockSwiftObject] = try database.read.objects(context: database.asyncWrite.context, query: nil)
//                
//        #expect(allObjects.count == allObjectIds.count)
//        
//        let writeObjects = WriteSwiftObjects(deleteObjects: allObjects, insertObjects: nil)
//        
//        try database.asyncWrite.objects(writeObjects: writeObjects)
//        
//        let objectsAfterDelete: [MockSwiftObject] = try database.read.objects(context: database.asyncWrite.context, query: nil)
//                        
//        #expect(objectsAfterDelete.count == 0)
//    }
}

extension SwiftDatabaseTests {
    
    @available(iOS 17.4, *)
    private func getDatabase() throws -> SwiftDatabase {
        
        let objects: [MockSwiftObject] = allObjectIds.map {
            MockSwiftObject.createFrom(interface: MockDataModel.createFromIntId(id: $0))
        }
        
        let database = try MockSwiftDatabase().createDatabase(
            directoryName: "swift_\(String(describing: SwiftDatabaseTests.self))",
            objects: objects,
            shouldDeleteExistingObjects: true
        )
        
        return database
    }
}
