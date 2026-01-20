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

@Suite(.serialized)
struct RealmRepositorySyncPersistenceTests {
 
    private let allObjectIds: [String] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    @Test()
    func getObjectCount() async throws {
        
        let persistence = try getPersistence()
        
        let objectCount: Int = try persistence.getObjectCount()
                                
        #expect(objectCount == allObjectIds.count)
    }
    
    @Test()
    func getDataModel() async throws {
        
        let persistence = try getPersistence()
        
        let dataModelId: String = "4"
        
        let dataModel: MockDataModel = try #require(try persistence.getDataModel(id: dataModelId))
                                                
        #expect(dataModel.id == dataModelId)
    }
    
    @Test()
    func getDataModelsPublisher() async throws {
        
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
                    .getDataModelsPublisher(getOption: .allObjects)
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
    func writeObjectsPublisherWithMapping() async throws {
        
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
    
    @Test()
    func writeObjectsPublisherWithoutMapping() async throws {
        
        let persistence = try getPersistence()
        
        let newObjectIds: [String] = ["10", "11", "12"]
        
        let externalObjects: [MockDataModel] = newObjectIds.compactMap {
            MockDataModel.createFromStringId(id: $0)
        }
        
        var cancellables: Set<AnyCancellable> = Set()
        
        var mappedDataModelsRef: [MockDataModel] = Array()
        
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
                    
                    mappedDataModelsRef = dataModels
                }
                .store(in: &cancellables)
            }
        }
        
        #expect(mappedDataModelsRef.count == 0)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func writeObjectsPublisherWithWriteOptionDeleteObjectsNotInExternal() async throws {

        let persistence = try getPersistence()
        
        let newObjectIds: [String] = ["10", "11", "12"]
        
        let externalObjects: [MockDataModel] = newObjectIds.compactMap {
            MockDataModel.createFromStringId(id: $0)
        }
        
        var cancellables: Set<AnyCancellable> = Set()
        
        var mappedDataModelsRef: [MockDataModel] = Array()
        
        await confirmation(expectedCount: 1) { confirmation in
            
            await withCheckedContinuation { continuation in
                
                let timeoutTask = Task {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    continuation.resume(returning: ())
                }
                
                persistence.writeObjectsPublisher(
                    externalObjects: externalObjects,
                    writeOption: .deleteObjectsNotInExternal,
                    getOption: .allObjects
                )
                .sink { completion in
                
                    // Place inside a sink or other async closure:
                    confirmation()
                                    
                    // When finished be sure to call:
                    timeoutTask.cancel()
                    continuation.resume(returning: ())
                    
                } receiveValue: { (dataModels: [MockDataModel]) in
                    
                    mappedDataModelsRef = dataModels
                }
                .store(in: &cancellables)
            }
        }
                        
        #expect(MockDataModel.getIdsSortedByPosition(dataModels: mappedDataModelsRef) == newObjectIds)
    }
}

extension RealmRepositorySyncPersistenceTests {
    
    private func getPersistence() throws -> RealmRepositorySyncPersistence<MockDataModel, MockDataModel, MockRealmObject> {
        
        return RealmRepositorySyncPersistence(
            database: try getDatabase(),
            dataModelMapping: MockRealmRepositorySyncMapping()
        )
    }
    
    private func getDatabase() throws -> RealmDatabase {
        
        let objects: [MockRealmObject] = allObjectIds.compactMap {
            
            guard let dataModel = MockDataModel.createFromStringId(id: $0) else {
                return nil
            }
            
            return MockRealmObject.createFrom(interface: dataModel)
        }
        
        return try MockRealmDatabase().createDatabase(
            directoryName: "realm_\(String(describing: RealmRepositorySyncPersistenceTests.self))",
            objects: objects,
            shouldDeleteExistingObjects: true
        )
    }
}
