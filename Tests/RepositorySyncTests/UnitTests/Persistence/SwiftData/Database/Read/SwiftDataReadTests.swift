//
//  SwiftDataReadTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 5/22/26.
//  Copyright © 2026 Cru. All rights reserved.
//

import Foundation
import Testing
@testable import RepositorySync
import SwiftData

struct SwiftDataReadTests {
    
    private let allObjectIds: Set<String> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

    @available(iOS 17.4, *)
    @Test()
    func getObjectCount() async throws {
        
        let context: ModelContext = try getModelContext()
        
        let query = SwiftDatabaseQuery(
            fetchDescriptor: FetchDescriptor<MockSwiftObject>()
        )
                
        let objectCount: Int = try SwiftDataRead().objectCount(context: context, query: query)
                
        #expect(objectCount == allObjectIds.count)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectById() throws {
                
        let context: ModelContext = try getModelContext()
        
        let objectId: String = "0"
                
        let object: MockSwiftObject = try #require(try SwiftDataRead().object(context: context, id: objectId))
                
        #expect(object.id == objectId)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectsByIds() throws {
                
        let context: ModelContext = try getModelContext()
                        
        let getObjectIds: Set<String> = ["2", "4", "6"]
        
        let objects: [MockSwiftObject] = try SwiftDataRead().objects(
            context: context,
            ids: getObjectIds,
            sortBy: nil
        )
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
                
        #expect(objectIds == getObjectIds)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectsByIdsAscendingFalse() throws {
                
        let context: ModelContext = try getModelContext()
                        
        let getObjectIds: Set<String> = ["6", "4", "2"]
        
        let objects: [MockSwiftObject] = try SwiftDataRead().objects(
            context: context,
            ids: getObjectIds,
            sortBy: [SortDescriptor(\MockSwiftObject.position, order: .reverse)]
        )
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
                
        #expect(objectIds == getObjectIds)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectByFilter() throws {
                
        let context: ModelContext = try getModelContext()
        
        let positionIsZero = #Predicate<MockSwiftObject> { object in
            object.position == 0
        }
                        
        let query = SwiftDatabaseQuery.filter(filter: positionIsZero)
        
        let objects: [MockSwiftObject] = try SwiftDataRead().objects(context: context, query: query)
        
        let object: MockSwiftObject = try #require(objects.first)
                
        #expect(object.id == "0")
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectsBySortAscendingTrue() throws {
                
        let context: ModelContext = try getModelContext()
                        
        let query = SwiftDatabaseQuery.sort(sortBy: [SortDescriptor(\MockSwiftObject.position, order: .forward)])
        
        let objects: [MockSwiftObject] = try SwiftDataRead().objects(context: context, query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectsBySortAscendingFalse() throws {
                
        let context: ModelContext = try getModelContext()
                        
        let query = SwiftDatabaseQuery.sort(sortBy: [SortDescriptor(\MockSwiftObject.position, order: .reverse)])
        
        let objects: [MockSwiftObject] = try SwiftDataRead().objects(context: context, query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectByFilterAndSort() throws {
                
        let context: ModelContext = try getModelContext()
                
        let isEvenPosition = #Predicate<MockSwiftObject> { object in
            object.isEvenPosition == true
        }
        
        let query = SwiftDatabaseQuery(
            filter: isEvenPosition,
            sortBy: [SortDescriptor(\MockSwiftObject.position, order: .reverse)]
        )

        let objects: [MockSwiftObject] = try SwiftDataRead().objects(context: context, query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [8, 6, 4, 2, 0])
    }
    
    @available(iOS 17.4, *)
    @Test()
    func readAllObjects() throws {
        
        let context: ModelContext = try getModelContext()
        
        let objects: [MockSwiftObject] =  try SwiftDataRead().getObjects(context: context, readObjectsType: .allObjects)
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
        
        #expect(objectIds == allObjectIds)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func readObjectById() throws {
        
        let context: ModelContext = try getModelContext()
        
        let objectId: String = "0"
        
        let objects: [MockSwiftObject] =  try SwiftDataRead().getObjects(context: context, readObjectsType: .object(id: objectId))
        
        let object: MockSwiftObject = try #require(objects.first)
        
        #expect(object.id == objectId)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func readObjectByIdIsEmptyWhenObjectDoesntExist() throws {
        
        let context: ModelContext = try getModelContext()
        
        let objectId: String = UUID().uuidString
        
        let objects: [MockSwiftObject] =  try SwiftDataRead().getObjects(context: context, readObjectsType: .object(id: objectId))
                
        #expect(objects.count == 0)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func readObjectsByIds() throws {
        
        let context: ModelContext = try getModelContext()
        
        let getObjectIds: Set<String> = ["1", "4", "0"]
        
        let objects: [MockSwiftObject] =  try SwiftDataRead().getObjects(context: context, readObjectsType: .objectsByIds(ids: getObjectIds, sortBy: nil))
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
                
        #expect(objectIds == getObjectIds)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func readObjectsByQuery() throws {
        
        let context: ModelContext = try getModelContext()
        
        let isEvenPosition = #Predicate<MockSwiftObject> { object in
            object.isEvenPosition == true
        }
        
        let query = SwiftDatabaseQuery(
            filter: isEvenPosition,
            sortBy: [SortDescriptor(\MockSwiftObject.position, order: .reverse)]
        )
        
        let objects: [MockSwiftObject] =  try SwiftDataRead().getObjects(context: context, readObjectsType: .objectsByQuery(query: query))
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [8, 6, 4, 2, 0])
    }
}

extension SwiftDataReadTests {
    
    @available(iOS 17.4, *)
    private func getModelContext() throws -> ModelContext {
        
        let schema = Schema(versionedSchema: MockSwiftDatabaseSchema.self)
        let container = try SwiftDataContainer.createInMemoryContainer(schema: schema)
        let database = SwiftDatabase(container: container)
        
        let context: ModelContext = database.openContext()
        
        for id in allObjectIds {
            
            guard let position = Int(id) else {
                continue
            }
            
            let object = MockSwiftObject.createFrom(model: MockDataModel(id: id, name: "name - \(id)", position: position))
            
            context.insert(object)
        }
        
        try context.save()
        
        return context
    }
}
