//
//  SwiftRepositorySyncPersistenceTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Testing
@testable import RepositorySync
import SwiftData
import Combine

struct SwiftRepositorySyncPersistenceTests {
    
    private let allObjectIds: Set<String> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    @available(iOS 17.4, *)
    @Test()
    @MainActor func observesCollectionChangesFiresOnceOnInitialSink() async throws {
        
        let persistence = try getPersistence()
        
        var cancellables: Set<AnyCancellable> = Set()
        var triggerCount: Int = 0
        
        let expectedTriggerCount: Int = 1
        
        await withCheckedContinuation { continuation in
            
            let timeoutTask = Task {
                try await Task.defaultTestSleep()
                continuation.resume(returning: ())
            }
            
            persistence
                .observeCollectionChangesPublisher()
                .sink { _ in
                    
                } receiveValue: { _ in
                    
                    triggerCount += 1
                    
                    if triggerCount == expectedTriggerCount {
                        
                        // When finished be sure to call:
                        timeoutTask.cancel()
                        continuation.resume(returning: ())
                    }
                }
                .store(in: &cancellables)
        }
        
        #expect(triggerCount == expectedTriggerCount)
    }
    
    @available(iOS 17.4, *)
    @Test()
    @MainActor func observesCollectionChangesFiresWhenWritingObjects() async throws {
        
        let persistence = try getPersistence()
        
        var cancellables: Set<AnyCancellable> = Set()
        var triggerCount: Int = 0
        
        let expectedTriggerCount: Int = 2
        
        Task {
            
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            let externalObjectIds: Set<String> = ["100"]
            
            let externalObjects: [MockDataModel] = externalObjectIds.compactMap {
                guard let position = Int($0) else {
                    return nil
                }
                return MockDataModel(id: $0, name: "name - \($0)", position: position)
            }
            
            _ = try await persistence.writeObjects(
                externalObjects: externalObjects,
                writeOption: nil,
                getOption: nil
            )
        }
                
        await withCheckedContinuation { continuation in
            
            let timeoutTask = Task {
                try await Task.defaultTestSleep()
                continuation.resume(returning: ())
            }
            
            persistence
                .observeCollectionChangesPublisher()
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    
                } receiveValue: { _ in
                    
                    triggerCount += 1
                    
                    if triggerCount == expectedTriggerCount {
                        
                        // When finished be sure to call:
                        timeoutTask.cancel()
                        continuation.resume(returning: ())
                    }
                }
                .store(in: &cancellables)
        }

        #expect(triggerCount == expectedTriggerCount)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectCount() async throws {
        
        let persistence = try getPersistence()
        
        let objectCount: Int = try persistence.getObjectCount()
                                
        #expect(objectCount == allObjectIds.count)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func getDataModel() async throws {
        
        let persistence = try getPersistence()
        
        let dataModelId: String = "4"
        
        let dataModel: MockDataModel = try #require(try persistence.getDataModel(id: dataModelId))
                                                
        #expect(dataModel.id == dataModelId)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func readAllObjects() async throws {
        
        let persistence = try getPersistence()
        
        let objects: [MockDataModel] =  try await persistence.getDataModels(getOption: .allObjects)
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
        
        #expect(objectIds == allObjectIds)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func readObjectById() async throws {
        
        let persistence = try getPersistence()
        
        let objectId: String = "0"
        
        let objects: [MockDataModel] =  try await persistence.getDataModels(getOption: .object(id: objectId))
        
        let object: MockDataModel = try #require(objects.first)
        
        #expect(object.id == objectId)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func readObjectByIdIsEmptyWhenObjectDoesntExist() async throws {
        
        let persistence = try getPersistence()
        
        let objectId: String = UUID().uuidString
        
        let objects: [MockDataModel] =  try await persistence.getDataModels(getOption: .object(id: objectId))
                
        #expect(objects.count == 0)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func readObjectsByIds() async throws {
        
        let persistence = try getPersistence()
        
        let getObjectIds: Set<String> = ["1", "4", "0"]
        
        let objects: [MockDataModel] =  try await persistence.getDataModels(getOption: .objectsByIds(ids: getObjectIds))
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
                
        #expect(objectIds == getObjectIds)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func writeObjectsDeletesNonExistingFromExternalObjects() async throws {
        
        let persistence = try getPersistence()
        
        let externalObjectIds: Set<String> = ["1", "2", "25", "26", "27", "28", "29"]
        
        let externalObjects: [MockDataModel] = externalObjectIds.compactMap {
            guard let position = Int($0) else {
                return nil
            }
            return MockDataModel(id: $0, name: "name - \($0)", position: position)
        }
        
        let objects: [MockDataModel] = try await persistence.writeObjects(
            externalObjects: externalObjects,
            writeOption: .deleteObjectsNotInExternal,
            getOption: .allObjects
        )
        
        let objectIds: Set<String> = Set(objects.map {
            $0.id
        })
        
        #expect(objectIds == externalObjectIds)
    }
}

extension SwiftRepositorySyncPersistenceTests {
    
    @available(iOS 17.4, *)
    private func getPersistence() throws -> SwiftRepositorySyncPersistence<MockDataModel, MockDataModel, MockSwiftObject> {
        
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

        return SwiftRepositorySyncPersistence(
            database: database,
            mapping: MockSwiftRepositorySyncMapping()
        )
    }
}
