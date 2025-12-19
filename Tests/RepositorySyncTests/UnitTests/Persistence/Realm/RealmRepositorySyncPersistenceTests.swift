//
//  RealmRepositorySyncPersistenceTests.swift
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

@Suite(.serialized)
struct RealmRepositorySyncPersistenceTests {
 
    private let allObjectIds: [String] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    @Test()
    @MainActor func getObjectCount() async throws {
        
        let persistence = try getPersistence()
        
        let objectCount: Int = try persistence.getObjectCount()
                                
        #expect(objectCount == allObjectIds.count)
    }
    
    @Test()
    @MainActor func getObjectsAsync() async throws {
        
        let persistence = try getPersistence()
        
        let dataModels: [MockDataModel] = try await persistence.getObjectsAsync(getObjectsType: .allObjects)
                                        
        #expect(MockDataModel.getIdsSortedByPosition(dataModels: dataModels) == allObjectIds)
    }
    
    @Test()
    @MainActor func getObjectAsync() async throws {
        
        let persistence = try getPersistence()
        
        let dataModels: [MockDataModel] = try await persistence.getObjectsAsync(getObjectsType: .object(id: "3"))
        
        let dataModel: MockDataModel = try #require(dataModels.first)
        
        #expect(dataModel.id == "3")
    }
    
    @Test()
    @MainActor func getObjectsPublisher() async throws {
        
        let persistence = try getPersistence()
        
        var cancellables: Set<AnyCancellable> = Set()
        
        var dataModelsRef: [MockDataModel] = Array()
        
        await confirmation(expectedCount: 1) { confirmation in
            
            await withCheckedContinuation { continuation in
                
                let timeoutTask = Task {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    continuation.resume(returning: ())
                }
                
                persistence
                    .getObjectsPublisher(getObjectsType: .allObjects)
                    .sink { completion in
                        
                        // Place inside a sink or other async closure:
                        confirmation()

                        // When finished be sure to call:
                        timeoutTask.cancel()
                        continuation.resume(returning: ())
                        
                    } receiveValue: { (dataModels: [MockDataModel]) in
                        
                        dataModelsRef = dataModels
                    }
                    .store(in: &cancellables)
            }
        }
        
        #expect(MockDataModel.getIdsSortedByPosition(dataModels: dataModelsRef) == allObjectIds)
    }
    
    @Test()
    @MainActor func mapPersistObjects() async throws {
        
        let persistence = try getPersistence()
        
        let sortedPeristObjectsIds: [String] = ["0", "1", "2"]
        
        let persistObjects: [MockRealmObject] = sortedPeristObjectsIds.compactMap {
            guard let dataModel = MockDataModel.createFromStringId(id: $0) else {
                return nil
            }
            return MockRealmObject.createFrom(interface: dataModel)
        }

        let dataModels: [MockDataModel] = persistence.mapPersistObjects(persistObjects: persistObjects)
        
        #expect(dataModels.count == persistObjects.count)
        #expect(MockDataModel.getIdsSortedByPosition(dataModels: dataModels) == sortedPeristObjectsIds)
    }
    
    @Test()
    @MainActor func writeObjectsAsyncWithMapping() async throws {
        
        let persistence = try getPersistence()
        
        let newObjectIds: [String] = ["10", "11", "12"]
        
        let externalObjects: [MockDataModel] = newObjectIds.compactMap {
            MockDataModel.createFromStringId(id: $0)
        }
        
        let mappedDataModels: [MockDataModel] = try await persistence.writeObjectsAsync(
            externalObjects: externalObjects,
            getObjectsType: .allObjects
        )
        
        let allIds: [String] = allObjectIds + newObjectIds
        
        #expect(MockDataModel.getIdsSortedByPosition(dataModels: mappedDataModels) == allIds)
    }
    
    @Test()
    @MainActor func writeObjectsAsyncWithoutMapping() async throws {
        
        let persistence = try getPersistence()
        
        let newObjectIds: [String] = ["10", "11", "12"]
        
        let externalObjects: [MockDataModel] = newObjectIds.compactMap {
            MockDataModel.createFromStringId(id: $0)
        }
        
        let mappedDataModels: [MockDataModel] = try await persistence.writeObjectsAsync(
            externalObjects: externalObjects,
            getObjectsType: nil
        )
        
        #expect(mappedDataModels.count == 0)
        
        let allIds: [String] = allObjectIds + newObjectIds
        let allDataModels: [MockDataModel] = try await persistence.getObjectsAsync(getObjectsType: .allObjects)
        
        #expect(MockDataModel.getIdsSortedByPosition(dataModels: allDataModels) == allIds)
    }
    
    @Test()
    @MainActor func writeObjectsPublisherWithMapping() async throws {
        
        let persistence = try getPersistence()
        
        let newObjectIds: [String] = ["10", "11", "12"]
        
        let externalObjects: [MockDataModel] = newObjectIds.compactMap {
            MockDataModel.createFromStringId(id: $0)
        }
        
        var cancellables: Set<AnyCancellable> = Set()
        
        var mappedDataModels: [MockDataModel] = Array()
        
        await confirmation(expectedCount: 1) { confirmation in
            
            await withCheckedContinuation { continuation in
                
                let timeoutTask = Task {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    continuation.resume(returning: ())
                }
                
                persistence.writeObjectsPublisher(
                    externalObjects: externalObjects,
                    getObjectsType: .allObjects
                )
                .sink { completion in
                
                    // Place inside a sink or other async closure:
                    confirmation()
                                    
                    // When finished be sure to call:
                    timeoutTask.cancel()
                    continuation.resume(returning: ())
                    
                } receiveValue: { (dataModels: [MockDataModel]) in
                    
                    mappedDataModels = dataModels
                }
                .store(in: &cancellables)
            }
        }
        
        let allIds: [String] = allObjectIds + newObjectIds
        
        #expect(MockDataModel.getIdsSortedByPosition(dataModels: mappedDataModels) == allIds)
    }
    
    @Test()
    @MainActor func writeObjectsPublisherWithoutMapping() async throws {
        
        let persistence = try getPersistence()
        
        let newObjectIds: [String] = ["10", "11", "12"]
        
        let externalObjects: [MockDataModel] = newObjectIds.compactMap {
            MockDataModel.createFromStringId(id: $0)
        }
        
        var cancellables: Set<AnyCancellable> = Set()
        
        var mappedDataModels: [MockDataModel] = Array()
        
        await confirmation(expectedCount: 1) { confirmation in
            
            await withCheckedContinuation { continuation in
                
                let timeoutTask = Task {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    continuation.resume(returning: ())
                }
                
                persistence.writeObjectsPublisher(
                    externalObjects: externalObjects,
                    getObjectsType: nil
                )
                .sink { completion in
                
                    // Place inside a sink or other async closure:
                    confirmation()
                                    
                    // When finished be sure to call:
                    timeoutTask.cancel()
                    continuation.resume(returning: ())
                    
                } receiveValue: { (dataModels: [MockDataModel]) in
                    
                    mappedDataModels = dataModels
                }
                .store(in: &cancellables)
            }
        }
        
        #expect(mappedDataModels.count == 0)
        
        let allIds: [String] = allObjectIds + newObjectIds
        let allDataModels: [MockDataModel] = try await persistence.getObjectsAsync(getObjectsType: .allObjects)
        
        #expect(MockDataModel.getIdsSortedByPosition(dataModels: allDataModels) == allIds)
    }
}

extension RealmRepositorySyncPersistenceTests {
    
    private func getPersistence() throws -> RealmRepositorySyncPersistence<MockDataModel, MockDataModel, MockRealmObject> {
        
        return RealmRepositorySyncPersistence(
            database: try getSharedDatabase(),
            dataModelMapping: MockRealmRepositorySyncMapping()
        )
    }
    
    private func getSharedDatabase() throws -> RealmDatabase {
        
        let persistObjects: [MockRealmObject] = allObjectIds.compactMap {
            guard let dataModel = MockDataModel.createFromStringId(id: $0) else {
                return nil
            }
            return MockRealmObject.createFrom(interface: dataModel)
        }
        
        let directoryName: String = "realm_\(String(describing: RealmRepositorySyncPersistenceTests.self))"
        
        return try MockRealmDatabase().createDatabase(directoryName: directoryName, objects: persistObjects, shouldDeleteExistingObjects: true)
    }
}
