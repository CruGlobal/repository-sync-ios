//
//  RealmRepositorySyncPersistenceTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Testing
@testable import RepositorySync
import RealmSwift
import Combine

struct RealmRepositorySyncPersistenceTests {
 
    private let allObjectIds: Set<String> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    @Test()
    @MainActor func observesCollectionChangesFiresOnceOnInitialSink() async throws {
        
        let persistence = try await getPersistence()
        
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
    
    @Test()
    @MainActor func observesCollectionChangesFiresWhenWritingObjects() async throws {
        
        let persistence = try await getPersistence()
        
        var cancellables: Set<AnyCancellable> = Set()
        var triggerCount: Int = 0
        
        let expectedTriggerCount: Int = 2
        
        let writeTask = Task {
            
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
                writeTask.cancel()
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
                        writeTask.cancel()
                        continuation.resume(returning: ())
                    }
                }
                .store(in: &cancellables)
        }

        #expect(triggerCount == expectedTriggerCount)
    }
    
    @Test()
    func getObjectCount() async throws {
        
        let persistence = try await getPersistence()
        
        let objectCount: Int = try persistence.getObjectCount()
                                
        #expect(objectCount == allObjectIds.count)
    }
    
    @Test()
    func getDataModel() async throws {
        
        let persistence = try await getPersistence()
        
        let dataModelId: String = "4"
        
        let dataModel: MockDataModel = try #require(try persistence.getDataModel(id: dataModelId))
                                                
        #expect(dataModel.id == dataModelId)
    }
    
    @Test()
    func readAllObjects() async throws {
        
        let persistence = try await getPersistence()
        
        let objects: [MockDataModel] =  try await persistence.getDataModels(getOption: .allObjects)
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
        
        #expect(objectIds == allObjectIds)
    }
    
    @Test()
    func readObjectById() async throws {
        
        let persistence = try await getPersistence()
        
        let objectId: String = "0"
        
        let objects: [MockDataModel] =  try await persistence.getDataModels(getOption: .object(id: objectId))
        
        let object: MockDataModel = try #require(objects.first)
        
        #expect(object.id == objectId)
    }
    
    @Test()
    func readObjectByIdIsEmptyWhenObjectDoesntExist() async throws {
        
        let persistence = try await getPersistence()
        
        let objectId: String = UUID().uuidString
        
        let objects: [MockDataModel] =  try await persistence.getDataModels(getOption: .object(id: objectId))
                
        #expect(objects.count == 0)
    }
    
    @Test()
    func readObjectsByIds() async throws {
        
        let persistence = try await getPersistence()
        
        let getObjectIds: Set<String> = ["1", "4", "0"]
        
        let objects: [MockDataModel] =  try await persistence.getDataModels(getOption: .objectsByIds(ids: getObjectIds))
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
                
        #expect(objectIds == getObjectIds)
    }
    
    @Test()
    func writeObjectsDeletesNonExistingFromExternalObjects() async throws {
        
        let persistence = try await getPersistence()
        
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

extension RealmRepositorySyncPersistenceTests {
    
    private func getPersistence() async throws -> RealmRepositorySyncPersistence<MockDataModel, MockDataModel, MockRealmObject> {
        
        let databaseConfig = try RealmDatabaseConfig.createInMemoryConfig()
        
        let repositorySync = RealmRepositorySyncPersistence(
            databaseConfig: databaseConfig,
            mapping: MockRealmRepositorySyncMapping()
        )
        
        let objects: [MockDataModel] = allObjectIds.compactMap {
         
            let id: String = $0
            
            guard let position = Int(id) else {
                return nil
            }
            
            return MockDataModel(id: id, name: "name - \(id)", position: position)
        }
        
        _ = try await repositorySync.writeObjects(
            externalObjects: objects,
            writeOption: nil,
            getOption: nil
        )
        
        return repositorySync
    }
}
