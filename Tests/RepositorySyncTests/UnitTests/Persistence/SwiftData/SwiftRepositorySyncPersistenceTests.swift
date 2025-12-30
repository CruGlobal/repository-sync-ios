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

@Suite(.serialized)
struct SwiftRepositorySyncPersistenceTests {
    
    private let allObjectIds: [String] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    @available(iOS 17.4, *)
    @Test()
    func getObjectCount() async throws {
        
        let persistence = try getPersistence()
        
        let objectCount: Int = try persistence.getObjectCount()
                                
        #expect(objectCount == allObjectIds.count)
    }
    
    @available(iOS 17.4, *)
    @Test()
    @MainActor func getObjectsAsync() async throws {
        
        let persistence = try getPersistence()
        
        let dataModels: [MockDataModel] = try await persistence.getObjectsAsync(getOption: .allObjects)
        
        let sortedDataModels: [String] = MockDataModel.getIdsSortedByPosition(dataModels: dataModels)
                                        
        #expect(sortedDataModels == allObjectIds)
    }
    
    @available(iOS 17.4, *)
    @Test()
    @MainActor func getObjectAsync() async throws {
        
        let persistence = try getPersistence()
        
        let dataModels: [MockDataModel] = try await persistence.getObjectsAsync(getOption: .object(id: "3"))
        
        let dataModel: MockDataModel = try #require(dataModels.first)
        
        #expect(dataModel.id == "3")
    }
    
    @available(iOS 17.4, *)
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
                    .getObjectsPublisher(getOption: .allObjects)
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
    
    @available(iOS 17.4, *)
    @Test()
    @MainActor func writeObjectsAsyncWithMapping() async throws {
        
        let persistence = try getPersistence()
        
        let newObjectIds: [String] = ["10", "11", "12"]
        
        let externalObjects: [MockDataModel] = newObjectIds.compactMap {
            MockDataModel.createFromStringId(id: $0)
        }
        
        let mappedDataModels: [MockDataModel] = try await persistence.writeObjectsAsync(
            externalObjects: externalObjects,
            writeOption: nil,
            getOption: .allObjects
        )
        
        let allIds: [String] = allObjectIds + newObjectIds
        
        #expect(MockDataModel.getIdsSortedByPosition(dataModels: mappedDataModels) == allIds)
    }
    
    @available(iOS 17.4, *)
    @Test()
    @MainActor func writeObjectsAsyncWithoutMapping() async throws {
        
        let persistence = try getPersistence()
        
        let newObjectIds: [String] = ["10", "11", "12"]
        
        let externalObjects: [MockDataModel] = newObjectIds.compactMap {
            MockDataModel.createFromStringId(id: $0)
        }
        
        let mappedDataModels: [MockDataModel] = try await persistence.writeObjectsAsync(
            externalObjects: externalObjects,
            writeOption: nil,
            getOption: nil
        )
        
        #expect(mappedDataModels.count == 0)
        
        let allIds: [String] = allObjectIds + newObjectIds
        let allDataModels: [MockDataModel] = try await persistence.getObjectsAsync(getOption: .allObjects)
        
        #expect(MockDataModel.getIdsSortedByPosition(dataModels: allDataModels) == allIds)
    }
    
    @available(iOS 17.4, *)
    @Test()
    @MainActor func writeObjectsAsyncWithWriteOptionDeleteObjectsNotInExternal() async throws {
        
        let persistence = try getPersistence()
        
        let newObjectIds: [String] = ["10", "11", "12"]
        
        let externalObjects: [MockDataModel] = newObjectIds.compactMap {
            MockDataModel.createFromStringId(id: $0)
        }
        
        let mappedDataModels: [MockDataModel] = try await persistence.writeObjectsAsync(
            externalObjects: externalObjects,
            writeOption: .deleteObjectsNotInExternal,
            getOption: nil
        )
        
        #expect(mappedDataModels.count == 0)
        
        let allDataModels: [MockDataModel] = try await persistence.getObjectsAsync(getOption: .allObjects)
        
        #expect(MockDataModel.getIdsSortedByPosition(dataModels: allDataModels) == newObjectIds)
    }
    
    @available(iOS 17.4, *)
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
                    writeOption: nil,
                    getOption: .allObjects
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
    
    @available(iOS 17.4, *)
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
                    writeOption: nil,
                    getOption: nil
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
        let allDataModels: [MockDataModel] = try await persistence.getObjectsAsync(getOption: .allObjects)
        
        #expect(MockDataModel.getIdsSortedByPosition(dataModels: allDataModels) == allIds)
    }
    
    @available(iOS 17.4, *)
    @Test()
    @MainActor func writeObjectsPublisherWithWriteOptionDeleteObjectsNotInExternal() async throws {

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
                    writeOption: .deleteObjectsNotInExternal,
                    getOption: nil
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
        
        let allDataModels: [MockDataModel] = try await persistence.getObjectsAsync(getOption: .allObjects)
        
        #expect(MockDataModel.getIdsSortedByPosition(dataModels: allDataModels) == newObjectIds)
    }
}

extension SwiftRepositorySyncPersistenceTests {
    
    @available(iOS 17.4, *)
    private func getPersistence() throws -> SwiftRepositorySyncPersistence<MockDataModel, MockDataModel, MockSwiftObject> {
        
        return SwiftRepositorySyncPersistence(
            database: try getDatabase(),
            dataModelMapping: MockSwiftRepositorySyncMapping()
        )
    }
    
    @available(iOS 17.4, *)
    private func getDatabase() throws -> SwiftDatabase {
        
        let objects: [MockSwiftObject] = allObjectIds.compactMap {
            
            guard let dataModel = MockDataModel.createFromStringId(id: $0) else {
                return nil
            }
            
            return MockSwiftObject.createFrom(interface: dataModel)
        }
        
        let database = try MockSwiftDatabase().createDatabase(
            directoryName: "swift_\(String(describing: SwiftRepositorySyncPersistenceTests.self))",
            objects: objects,
            shouldDeleteExistingObjects: true
        )
        
        return database
    }
}
