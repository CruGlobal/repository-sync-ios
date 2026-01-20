//
//  RepositorySyncGetPublisherTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Testing
@testable import RepositorySync
import Foundation
import Combine

@Suite(.serialized)
struct RepositorySyncGetPublisherTests {
    
    private let runTestWaitFor: UInt64 = 3_000_000_000 // 3 seconds
    private let mockExternalDataFetchDelayRequestForSeconds: TimeInterval = 1
    private let triggerSecondaryExternalDataFetchWithDelayForSeconds: TimeInterval = 1
    
    struct TestArgument {
        let initialPersistedObjectsIds: [String]
        let externalDataModelIds: [String]
        let expectedCachedResponseDataModelIds: [String]?
        let expectedResponseDataModelIds: [String]
    }
    
    // MARK: - SWIFT TESTS
    
    // MARK: - Swift Test Cache Policy (Get Ignoring Cache Data) - Objects
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["0", "1"],
            externalDataModelIds: ["5", "6", "7", "8", "9"],
            expectedCachedResponseDataModelIds: nil,
            expectedResponseDataModelIds: ["0", "1", "5", "6", "7", "8", "9"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["1", "2"],
            expectedCachedResponseDataModelIds: nil,
            expectedResponseDataModelIds: ["1", "2"]
        ),
        TestArgument(
            initialPersistedObjectsIds: ["2", "3"],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: nil,
            expectedResponseDataModelIds: ["2", "3"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: nil,
            expectedResponseDataModelIds: []
        )
    ])
    @available(iOS 17.4, *)
    func getIgnoreCacheDataWillTriggerOnceOnExternalFetchWithAllObjects(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .ignoreCacheData,
            expectedNumberOfChanges: 1,
            loggingEnabled: false
        )
    }

    // MARK: - Swift Test Cache Policy (Get Ignoring Cache Data) - Object ID
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["0", "1"],
            externalDataModelIds: ["5", "6", "7", "8", "9"],
            expectedCachedResponseDataModelIds: nil,
            expectedResponseDataModelIds: ["1"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["1", "2"],
            expectedCachedResponseDataModelIds: nil,
            expectedResponseDataModelIds: ["1"]
        ),
        TestArgument(
            initialPersistedObjectsIds: ["1", "2", "3"],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: nil,
            expectedResponseDataModelIds: ["1"]
        ),
        TestArgument(
            initialPersistedObjectsIds: ["2", "3"],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: nil,
            expectedResponseDataModelIds: []
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: nil,
            expectedResponseDataModelIds: []
        )
    ])
    @available(iOS 17.4, *)
    func getIgnoreCacheDataWillTriggerOnceOnExternalFetchWithObject(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            cachePolicy: .ignoreCacheData,
            expectedNumberOfChanges: 1,
            loggingEnabled: false
        )
    }
    
    // MARK: - Swift Test Cache Policy (Get Return Cache Data Don't Fetch) - Objects
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["0", "1"],
            externalDataModelIds: ["5", "6", "7", "8", "9"],
            expectedCachedResponseDataModelIds: ["0", "1"],
            expectedResponseDataModelIds: ["0", "1"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["1", "2"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: []
        ),
        TestArgument(
            initialPersistedObjectsIds: ["2", "3"],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: ["2", "3"],
            expectedResponseDataModelIds: ["2", "3"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: []
        )
    ])
    @available(iOS 17.4, *)
    func getReturnCacheDataDontFetchWillTriggerOnceWithAllObjects(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .returnCacheDataDontFetch,
            expectedNumberOfChanges: 1,
            loggingEnabled: false
        )
    }
    
    // MARK: - Swift Test Cache Policy (Get Return Cache Data Don't Fetch) - Object ID
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["0", "1"],
            externalDataModelIds: ["5", "6", "7", "8", "9"],
            expectedCachedResponseDataModelIds: ["1"],
            expectedResponseDataModelIds: ["1"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["1", "2"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: []
        ),
        TestArgument(
            initialPersistedObjectsIds: ["1", "2", "3"],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: ["1"],
            expectedResponseDataModelIds: ["1"]
        ),
        TestArgument(
            initialPersistedObjectsIds: ["2", "3"],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: nil,
            expectedResponseDataModelIds: []
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: nil,
            expectedResponseDataModelIds: []
        )
    ])
    @available(iOS 17.4, *)
    func getReturnCacheDataDontFetchWillTriggerOnceWithObject(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            cachePolicy: .returnCacheDataDontFetch,
            expectedNumberOfChanges: 1,
            loggingEnabled: false
        )
    }
    
    // MARK: - Swift Test Cache Policy (Get Return Cache Data Else Fetch) - Objects
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["0", "1"],
            externalDataModelIds: ["5", "6", "7", "8", "9"],
            expectedCachedResponseDataModelIds: ["0", "1"],
            expectedResponseDataModelIds: ["0", "1"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["1", "2"],
            expectedCachedResponseDataModelIds: ["1", "2"],
            expectedResponseDataModelIds: ["1", "2"]
        ),
        TestArgument(
            initialPersistedObjectsIds: ["1", "2", "3"],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: ["1", "2", "3"],
            expectedResponseDataModelIds: ["1", "2", "3"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: nil,
            expectedResponseDataModelIds: []
        )
    ])
    @available(iOS 17.4, *)
    func getReturnCacheDataElseFetchWillTriggerOnceWithAllObjects(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .returnCacheDataElseFetch,
            expectedNumberOfChanges: 1,
            loggingEnabled: false
        )
    }
    
    // MARK: - Swift Test Cache Policy (Get Return Cache Data Else Fetch) - Object ID
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["0", "1"],
            externalDataModelIds: ["5", "6", "7", "8", "9"],
            expectedCachedResponseDataModelIds: ["1"],
            expectedResponseDataModelIds: ["1"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["1", "2"],
            expectedCachedResponseDataModelIds: ["1"],
            expectedResponseDataModelIds: ["1"]
        ),
        TestArgument(
            initialPersistedObjectsIds: ["1", "2", "3"],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: ["1"],
            expectedResponseDataModelIds: ["1"]
        ),
        TestArgument(
            initialPersistedObjectsIds: ["2", "3"],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: nil,
            expectedResponseDataModelIds: []
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: nil,
            expectedResponseDataModelIds: []
        )
    ])
    @available(iOS 17.4, *)
    func getReturnCacheDataElseFetchWillTriggerOnceWithObject(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            cachePolicy: .returnCacheDataElseFetch,
            expectedNumberOfChanges: 1,
            loggingEnabled: false
        )
    }
    
    // MARK: - Run Test
    
    @available(iOS 17.4, *)
    private func runTest(argument: TestArgument, getObjectsType: GetObjectsType, cachePolicy: GetCachePolicy, expectedNumberOfChanges: Int, loggingEnabled: Bool) async throws {
        
        let testName: String = "SWIFT"
        let testId: String = UUID().uuidString
        
        let initialPersistedObjectsIds: [String] = argument.initialPersistedObjectsIds
        let externalDataModelIds: [String] = argument.externalDataModelIds
        let expectedCachedResponseDataModelIds: [String]? = argument.expectedCachedResponseDataModelIds
        let expectedResponseDataModelIds: [String] = argument.expectedResponseDataModelIds
        
        if loggingEnabled {
            print("\n *** RUNNING \(testName) TEST *** \n")
            print("  testId: \(testId)")
            print("  initial persisted object ids: \(initialPersistedObjectsIds) ")
            print("  external data model ids: \(externalDataModelIds) ")
        }
        
        var cancellables: Set<AnyCancellable> = Set()
        
        let repositorySync = try getRepositorySync(
            externalDataFetch: getExternalDataFetch(dataModels: MockDataModel.createDataModelsFromIds(ids: externalDataModelIds)),
            addObjectsToDatabase: MockDataModel.createDataModelsFromIds(ids: initialPersistedObjectsIds),
            shouldDeleteExistingObjectsInDatabase: true
        )
        
        var sinkCount: Int = 0
        
        var cachedObjects: [MockDataModel] = Array()
        var responseObjects: [MockDataModel] = Array()
                
        await confirmation(expectedCount: expectedNumberOfChanges) { confirmation in
            
            await withCheckedContinuation { continuation in
                
                let timeoutTask = Task {
                    try await Task.sleep(nanoseconds: self.runTestWaitFor)
                    if loggingEnabled {
                        print("\n TIMEOUT")
                    }
                    continuation.resume(returning: ())
                }
                
                repositorySync
                    .getDataModelsPublisher(
                        getObjectsType: getObjectsType,
                        cachePolicy: cachePolicy,
                        context: MockExternalDataFetchContext()
                    )
                    .sink { completion in
                        
                        switch completion {
                        case .finished:
                            if loggingEnabled {
                                print("\n DID COMPLETE")
                                print("\n    CACHED OBJECTS: \(cachedObjects.map{$0.id})")
                                print("\n    RESPONSE OBJECTS: \(responseObjects.map{$0.id})")
                                print("\n WITH ABOVE RESPONSE")
                            }
                        case .failure(let error):
                            if loggingEnabled {
                                print("\n DID COMPLETE WITH ERROR: \(error)")
                            }
                        }
                        
                        timeoutTask.cancel()
                        continuation.resume(returning: ())
                        
                    } receiveValue: { (objects: [MockDataModel]) in
                        
                        if loggingEnabled {
                            print("\n DID SINK")
                            print("  COUNT: \(sinkCount)")
                            print("  RESPONSE: \(objects.map{$0.id})")
                        }
                        
                        confirmation()
                        
                        sinkCount += 1
                                                
                        if sinkCount == 1 && expectedCachedResponseDataModelIds != nil {
                            
                            if loggingEnabled {
                                print("\n CACHE RESPONSE RECORDED: \(objects.map{$0.id})")
                            }
                            
                            cachedObjects = objects
                        }
                        
                        if sinkCount == expectedNumberOfChanges {
                            
                            if loggingEnabled {
                                print("\n RESPONSE RECORDED: \(objects.map{$0.id})")
                                print("\n SINK COMPLETE")
                            }
                            
                            responseObjects = objects
                        }
                    }
                    .store(in: &cancellables)
            }
        }
             
        if let expectedCachedResponseDataModelIds = expectedCachedResponseDataModelIds {
            
            let cachedResponseDataModelIds: [String] = MockDataModel.getIdsSortedByPosition(dataModels: cachedObjects)
                        
            if loggingEnabled {
                print("\n EXPECT")
                print("  CACHE RESPONSE: \(cachedResponseDataModelIds)")
                print("  TO EQUAL: \(expectedCachedResponseDataModelIds)")
            }
            
            #expect(cachedResponseDataModelIds == expectedCachedResponseDataModelIds)
        }
        
        let responseDataModelIds: [String] = MockDataModel.getIdsSortedByPosition(dataModels: responseObjects)
        
        if loggingEnabled {
            print("\n EXPECT")
            print("  RESPONSE: \(responseDataModelIds)")
            print("  TO EQUAL: \(expectedResponseDataModelIds)")
        }
        
        #expect(responseDataModelIds == expectedResponseDataModelIds)
        
        if loggingEnabled {
            print("\n\n END \(testName) TEST")
            print("  testId: \(testId)")
            print("\n\n")
        }
    }
}

// MARK: - RepositorySync

extension RepositorySyncGetPublisherTests {
    
    @available(iOS 17.4, *)
    private func getSharedSwiftDatabase(addObjects: [MockSwiftObject], shouldDeleteExistingObjects: Bool) throws -> SwiftDatabase {
        let directoryName: String = "swift_\(String(describing: RepositorySyncGetPublisherTests.self))"
        return try MockSwiftDatabase().createDatabase(directoryName: directoryName, objects: addObjects, shouldDeleteExistingObjects: shouldDeleteExistingObjects)
    }
    
    @available(iOS 17.4, *)
    private func getRepositorySync(externalDataFetch: MockExternalDataFetch, addObjectsToDatabase: [MockDataModel], shouldDeleteExistingObjectsInDatabase: Bool) throws -> RepositorySync<MockDataModel, MockExternalDataFetch> {
        
        let persistence: any Persistence<MockDataModel, MockDataModel>
        
        let swiftObjects: [MockSwiftObject] = addObjectsToDatabase.map {
            MockSwiftObject.createFrom(interface: $0)
        }
        
        let swiftDatabase: SwiftDatabase = try getSharedSwiftDatabase(
            addObjects: swiftObjects,
            shouldDeleteExistingObjects: shouldDeleteExistingObjectsInDatabase
        )
        
        persistence = SwiftRepositorySyncPersistence<MockDataModel, MockDataModel, MockSwiftObject>(
            database: swiftDatabase,
            dataModelMapping: MockSwiftRepositorySyncMapping()
        )
        
        let repositorySync = RepositorySync(
            externalDataFetch: externalDataFetch,
            persistence: persistence
        )
        
        return repositorySync
    }
}

// MARK: - Get External Data Fetch

extension RepositorySyncGetPublisherTests {

    private func getExternalDataFetch(dataModels: [MockDataModel]) -> MockExternalDataFetch {
        
        let externalDataFetch = MockExternalDataFetch(
            objects: dataModels,
            delayRequestSeconds: mockExternalDataFetchDelayRequestForSeconds
        )
        
        return externalDataFetch
    }
}
