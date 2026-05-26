//
//  SwiftDataActorReadTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 5/22/26.
//  Copyright © 2026 Cru. All rights reserved.
//

import Foundation
import Testing
@testable import RepositorySync
import SwiftData

struct SwiftDataActorReadTests {
    
    private let allObjectIds: Set<String> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

    @available(iOS 17.4, *)
    @Test()
    func getObjectById() async throws {
                
        let swiftActorRead: SwiftDataActorRead = try getSwiftDataActorRead()
        
        let objectId: String = "0"
        
        let dataModel: MockDataModel? = try await swiftActorRead.getDataModel(id: objectId)
                
        let object: MockDataModel = try #require(dataModel)
                
        #expect(object.id == objectId)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectByIdIsNilWhenDoesntExist() async throws {
                
        let swiftActorRead: SwiftDataActorRead = try getSwiftDataActorRead()
        
        let objectId: String = UUID().uuidString
                
        let object: MockDataModel? = try await swiftActorRead.getDataModel(id: objectId)
                
        #expect(object == nil)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectsByIds() async throws {
                
        let swiftActorRead: SwiftDataActorRead = try getSwiftDataActorRead()
                        
        let getObjectIds: Set<String> = ["2", "4", "6"]
        
        let objects: [MockDataModel] = try await swiftActorRead.getDataModels(
            ids: getObjectIds,
            sortBy: nil
        )
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
                
        #expect(objectIds == getObjectIds)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectsByIdsAscendingFalse() async throws {
                
        let swiftActorRead: SwiftDataActorRead = try getSwiftDataActorRead()
                        
        let getObjectIds: Set<String> = ["6", "4", "2"]
        
        let objects: [MockDataModel] = try await swiftActorRead.getDataModels(
            ids: getObjectIds,
            sortBy: [SortDescriptor(\MockSwiftObject.position, order: .reverse)]
        )
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
                
        #expect(objectIds == getObjectIds)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectByFilter() async throws {
                
        let swiftActorRead: SwiftDataActorRead = try getSwiftDataActorRead()
        
        let positionIsZero = #Predicate<MockSwiftObject> { object in
            object.position == 0
        }
                        
        let query = SwiftDatabaseQuery.filter(filter: positionIsZero)
        
        let objects: [MockDataModel] = try await swiftActorRead.getDataModels(query: query)
        
        let object: MockDataModel = try #require(objects.first)
                
        #expect(object.id == "0")
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectsBySortAscendingTrue() async throws {
                
        let swiftActorRead: SwiftDataActorRead = try getSwiftDataActorRead()
                        
        let query = SwiftDatabaseQuery.sort(sortBy: [SortDescriptor(\MockSwiftObject.position, order: .forward)])
        
        let objects: [MockDataModel] = try await swiftActorRead.getDataModels(query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectsBySortAscendingFalse() async throws {
                
        let swiftActorRead: SwiftDataActorRead = try getSwiftDataActorRead()
                        
        let query = SwiftDatabaseQuery.sort(sortBy: [SortDescriptor(\MockSwiftObject.position, order: .reverse)])
        
        let objects: [MockDataModel] = try await swiftActorRead.getDataModels(query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectByFilterAndSort() async throws {
                
        let swiftActorRead: SwiftDataActorRead = try getSwiftDataActorRead()
                
        let isEvenPosition = #Predicate<MockSwiftObject> { object in
            object.isEvenPosition == true
        }
        
        let query = SwiftDatabaseQuery(
            filter: isEvenPosition,
            sortBy: [SortDescriptor(\MockSwiftObject.position, order: .reverse)]
        )

        let objects: [MockDataModel] = try await swiftActorRead.getDataModels(query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [8, 6, 4, 2, 0])
    }
    
    @available(iOS 17.4, *)
    @Test()
    func readAllObjects() async throws {
        
        let swiftActorRead: SwiftDataActorRead = try getSwiftDataActorRead()
        
        let objects: [MockDataModel] =  try await swiftActorRead.getDataModels(readObjectsType: .allObjects)
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
        
        #expect(objectIds == allObjectIds)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func readObjectById() async throws {
        
        let swiftActorRead: SwiftDataActorRead = try getSwiftDataActorRead()
        
        let objectId: String = "0"
        
        let objects: [MockDataModel] =  try await swiftActorRead.getDataModels(readObjectsType: .object(id: objectId))
        
        let object: MockDataModel = try #require(objects.first)
        
        #expect(object.id == objectId)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func readObjectByIdIsEmptyWhenObjectDoesntExist() async throws {
        
        let swiftActorRead: SwiftDataActorRead = try getSwiftDataActorRead()
        
        let objectId: String = UUID().uuidString
        
        let objects: [MockDataModel] =  try await swiftActorRead.getDataModels(readObjectsType: .object(id: objectId))
                
        #expect(objects.count == 0)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func readObjectsByIds() async throws {
        
        let swiftActorRead: SwiftDataActorRead = try getSwiftDataActorRead()
        
        let getObjectIds: Set<String> = ["1", "4", "0"]
        
        let objects: [MockDataModel] =  try await swiftActorRead.getDataModels(readObjectsType: .objectsByIds(ids: getObjectIds, sortBy: nil))
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
                
        #expect(objectIds == getObjectIds)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func readObjectsByQuery() async throws {
        
        let swiftActorRead: SwiftDataActorRead = try getSwiftDataActorRead()
        
        let isEvenPosition = #Predicate<MockSwiftObject> { object in
            object.isEvenPosition == true
        }
        
        let query = SwiftDatabaseQuery(
            filter: isEvenPosition,
            sortBy: [SortDescriptor(\MockSwiftObject.position, order: .reverse)]
        )
        
        let objects: [MockDataModel] =  try await swiftActorRead.getDataModels(readObjectsType: .objectsByQuery(query: query))
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [8, 6, 4, 2, 0])
    }
}

extension SwiftDataActorReadTests {
    
    @available(iOS 17.4, *)
    private func getSwiftDataActorRead() throws -> SwiftDataActorRead<MockDataModel, MockDataModel, MockSwiftObject> {
        
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
 
        return SwiftDataActorRead(
            container: container.modelContainer,
            mapping: MockSwiftRepositorySyncMapping()
        )
    }
}
