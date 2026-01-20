//
//  RepositorySyncObservePublisherTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Testing
@testable import RepositorySync
import Foundation
import RealmSwift
import Combine

@Suite(.serialized)
struct RepositorySyncObservePublisherTests {
            
    private let runTestWaitFor: UInt64 = 3_000_000_000 // 3 seconds
    private let mockExternalDataFetchDelayRequestForSeconds: TimeInterval = 1
    private let triggerSecondaryExternalDataFetchWithDelayForSeconds: TimeInterval = 1
    
    struct TestArgument {
        let initialPersistedObjectsIds: [String]
        let externalDataModelIds: [String]
        let expectedCachedResponseDataModelIds: [String]?
        let expectedResponseDataModelIds: [String]
    }
    
    // TODO: Fix crash on context.save. ~Levi
    
//    @Test(arguments: [
//        TestArgument(
//            initialPersistedObjectsIds: ["0", "1"],
//            externalDataModelIds: [],
//            expectedCachedResponseDataModelIds: ["0", "1"],
//            expectedResponseDataModelIds: ["0", "1", "8", "9"]
//        )
//    ])
//    @available(iOS 17.4, *)
//    @MainActor func templateTest(argument: TestArgument) async throws {
//        
//        try await runTest(
//            argument: argument,
//            getObjectsType: .allObjects,
//            cachePolicy: .returnCacheDataDontFetch,
//            expectedNumberOfChanges: 2,
//            triggerSecondaryExternalDataFetchWithIds: ["8", "9"],
//            loggingEnabled: true
//        )
//    }
    
    // MARK: - SWIFT TESTS
    /*
    // MARK: - Swift Test Cache Policy (Observe Return Cache Data Don't Fetch) - Objects
    
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
        ),
        TestArgument(
            initialPersistedObjectsIds: ["2", "3"],
            externalDataModelIds: ["1", "2", "3"],
            expectedCachedResponseDataModelIds: ["2", "3"],
            expectedResponseDataModelIds: ["2", "3"]
        ),
    ])
    @available(iOS 17.4, *)
    @MainActor func observeReturnCacheDataDontFetchWillTriggerOnceWithAllObjects(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .returnCacheDataDontFetch,
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: nil,
            loggingEnabled: false
        )
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["0", "1"],
            externalDataModelIds: ["5", "6", "7", "8", "9"],
            expectedCachedResponseDataModelIds: ["0", "1"],
            expectedResponseDataModelIds: ["0", "1", "8", "9"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["1", "2"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["8", "9"]
        ),
        TestArgument(
            initialPersistedObjectsIds: ["2", "3"],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: ["2", "3"],
            expectedResponseDataModelIds: ["2", "3", "8", "9"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["8", "9"]
        ),
        TestArgument(
            initialPersistedObjectsIds: ["2", "3"],
            externalDataModelIds: ["1", "2", "3"],
            expectedCachedResponseDataModelIds: ["2", "3"],
            expectedResponseDataModelIds: ["2", "3", "8", "9"]
        ),
    ])
    @available(iOS 17.4, *)
    @MainActor func observeReturnCacheDataDontFetchWillTriggerTwiceWithAllObjectsAndOnSecondaryExternalFetch(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .returnCacheDataDontFetch,
            expectedNumberOfChanges: 2,
            triggerSecondaryExternalDataFetchWithIds: ["8", "9"],
            loggingEnabled: false
        )
    }
     */
    // MARK: - Run Test
    
    @available(iOS 17.4, *)
    @MainActor private func runTest(argument: TestArgument, getObjectsType: GetObjectsType, cachePolicy: ObserveCachePolicy, expectedNumberOfChanges: Int, triggerSecondaryExternalDataFetchWithIds: [String]?, loggingEnabled: Bool) async throws {
        
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
               
        let triggerSecondaryExternalDataFetchWithIds: [String] = triggerSecondaryExternalDataFetchWithIds ?? Array()
        let triggersSecondaryExternalDataFetch: Bool = triggerSecondaryExternalDataFetchWithIds.count > 0
        
        if triggersSecondaryExternalDataFetch {
                        
            DispatchQueue.global().asyncAfter(deadline: .now() + triggerSecondaryExternalDataFetchWithDelayForSeconds) {

                // TODO: See if I can trigger another external data fetch by fetching from mock external data and writing objects to the database. ~Levi
                
                if loggingEnabled {
                    print("\n PERFORMING SECONDARY EXTERNAL DATA FETCH WITH IDS: \(triggerSecondaryExternalDataFetchWithIds)")
                }
                
                do {
                    
                    let additionalRepositorySync = try getRepositorySync(
                        externalDataFetch: getExternalDataFetch(dataModels: MockDataModel.createDataModelsFromIds(ids: triggerSecondaryExternalDataFetchWithIds)),
                        addObjectsToDatabase: [],
                        shouldDeleteExistingObjectsInDatabase: false
                    )
                    
                    additionalRepositorySync
                         .getDataModelsPublisher(
                             getObjectsType: .allObjects,
                             cachePolicy: .ignoreCacheData,
                             context: MockExternalDataFetchContext()
                         )
                        .sink { completion in
                            
                            switch completion {
                            case .finished:
                                if loggingEnabled {
                                    print("\n DID COMPLETE SECONDARY DATA FETCH")
                                }
                            case .failure(let error):
                                if loggingEnabled {
                                    print("\n DID COMPLETE SECONDARY DATA FETCH WITH ERROR: \(error)")
                                }
                            }
                            
                        } receiveValue: { (objects: [MockDataModel]) in
                            
                            if loggingEnabled {
                                print("\n DID SINK SECONDARY DATA FETCH: \(objects.map{$0.id})")
                            }
                        }
                        .store(in: &cancellables)
                }
                catch let error {
                    
                    if loggingEnabled {
                        print("\n SECONDARY DATA FETCH FAILED WITH ERROR: \(error)")
                    }
                }
            }
        }
        
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
                    .observeDataModelsPublisher(
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

extension RepositorySyncObservePublisherTests {
    
    @available(iOS 17.4, *)
    private func getSharedSwiftDatabase(addObjects: [MockSwiftObject], shouldDeleteExistingObjects: Bool) throws -> SwiftDatabase {
        let directoryName: String = "swift_\(String(describing: RepositorySyncObservePublisherTests.self))"
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

extension RepositorySyncObservePublisherTests {

    private func getExternalDataFetch(dataModels: [MockDataModel]) -> MockExternalDataFetch {
        
        let externalDataFetch = MockExternalDataFetch(
            objects: dataModels,
            delayRequestSeconds: mockExternalDataFetchDelayRequestForSeconds
        )
        
        return externalDataFetch
    }
}
