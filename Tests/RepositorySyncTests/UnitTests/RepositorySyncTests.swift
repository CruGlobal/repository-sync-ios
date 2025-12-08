//
//  RepositorySyncTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/8/25.
//

import Testing
@testable import RepositorySync
import Foundation
import Combine

struct RepositorySyncTests {
    
    private let runTestWaitFor: UInt64 = 3_000_000_000 // 3 seconds
    private let mockExternalDataFetchDelayRequestForSeconds: TimeInterval = 1
    private let triggerSecondaryExternalDataFetchWithDelayForSeconds: TimeInterval = 1
    private let namePrefix: String = "name_"
    
    struct TestArgument {
        let initialPersistedObjectsIds: [String]
        let externalDataModelIds: [String]
        let expectedCachedResponseDataModelIds: [String]?
        let expectedResponseDataModelIds: [String]
    }
    
    // MARK: - Run Realm Test
    
    private func runRealmTest(argument: TestArgument, getObjectsType: GetObjectsType, cachePolicy: CachePolicy, expectedNumberOfChanges: Int, triggerSecondaryExternalDataFetchWithIds: [String] = Array(), loggingEnabled: Bool = false) async throws {
        
        try await runRealmTest(
            initialPersistedObjectsIds: argument.initialPersistedObjectsIds,
            externalDataModelIds: argument.externalDataModelIds,
            expectedCachedResponseDataModelIds: argument.expectedCachedResponseDataModelIds,
            expectedResponseDataModelIds: argument.expectedResponseDataModelIds,
            getObjectsType: getObjectsType,
            cachePolicy: cachePolicy,
            expectedNumberOfChanges: expectedNumberOfChanges,
            triggerSecondaryExternalDataFetchWithIds: triggerSecondaryExternalDataFetchWithIds,
            loggingEnabled: loggingEnabled
        )
    }
    
    private func runRealmTest(initialPersistedObjectsIds: [String], externalDataModelIds: [String], expectedCachedResponseDataModelIds: [String]?, expectedResponseDataModelIds: [String], getObjectsType: GetObjectsType, cachePolicy: CachePolicy, expectedNumberOfChanges: Int, triggerSecondaryExternalDataFetchWithIds: [String], loggingEnabled: Bool) async throws {
        
        if loggingEnabled {
            print("\n *** RUNNING REALM TEST *** \n")
        }
        
        let databaseDirectoryName: String = getUniqueDirectoryName()
        
        let triggersSecondaryExternalDataFetch: Bool = triggerSecondaryExternalDataFetchWithIds.count > 0
        
        if triggersSecondaryExternalDataFetch {
                        
            DispatchQueue.global().asyncAfter(deadline: .now() + triggerSecondaryExternalDataFetchWithDelayForSeconds) {

                // TODO: See if I can trigger another external data fetch by fetching from mock external data and writing objects to the database. ~Levi
                
                if loggingEnabled {
                    print("\n PERFORMING SECONDARY EXTERNAL DATA FETCH")
                }
                
                do {
                    
                    let persistence = try getRealmRepositorySyncPersistence(
                        directoryName: databaseDirectoryName,
                        addObjects: []
                    )
                                    
                    let externalDataFetch = self.getExternalDataFetch(
                        dataModels: MockRepositorySyncDataModel.createDataModelsFromIds(ids: triggerSecondaryExternalDataFetchWithIds)
                    )
                    
                    let additionalRepositorySync = RepositorySync<MockRepositorySyncDataModel, MockRepositorySyncExternalDataFetch>(
                        externalDataFetch: externalDataFetch,
                        persistence: persistence
                    )
                    
                    var cancellables: Set<AnyCancellable> = Set()
                    
                    additionalRepositorySync
                        .getObjectsPublisher(
                            getObjectsType: .allObjects,
                            cachePolicy: .fetchIgnoringCacheData,
                            context: MockExternalDataFetchContext()
                        )
                        .sink { completion in
                            
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                if loggingEnabled {
                                    print("\n DID COMPLETE SECONDARY DATA FETCH WITH ERROR: \(error)")
                                }
                            }
                            
                        } receiveValue: { (objects: [MockRepositorySyncDataModel]) in
                            
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
        
        let initialDataModels: [MockRepositorySyncDataModel] = MockRepositorySyncDataModel.createDataModelsFromIds(ids: initialPersistedObjectsIds)
        
        let externalDataFetch = getExternalDataFetch(dataModels: initialDataModels)
        
        let persistence = try getRealmRepositorySyncPersistence(
            directoryName: databaseDirectoryName,
            addObjects: initialDataModels
        )
        
        let repositorySync = RepositorySync<MockRepositorySyncDataModel, MockRepositorySyncExternalDataFetch>(
            externalDataFetch: externalDataFetch,
            persistence: persistence
        )
        
        var sinkCount: Int = 0
        
        var cachedObjects: [MockRepositorySyncDataModel] = Array()
        var responseObjects: [MockRepositorySyncDataModel] = Array()
        
        var cancellables: Set<AnyCancellable> = Set()
        
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
                    .getObjectsPublisher(
                        getObjectsType: getObjectsType,
                        cachePolicy: cachePolicy,
                        context: MockExternalDataFetchContext()
                    )
                    .sink { completion in
                        
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            
                            if loggingEnabled {
                                print("\n DID COMPLETE WITH ERROR: \(error)")
                            }
                            
                            timeoutTask.cancel()
                            continuation.resume(returning: ())
                        }
                        
                    } receiveValue: { (objects: [MockRepositorySyncDataModel]) in
                        
                        confirmation()
                        
                        sinkCount += 1
                        
                        if loggingEnabled {
                            print("\n DID SINK")
                            print("  COUNT: \(sinkCount)")
                            print("  RESPONSE: \(objects.map{$0.id})")
                        }
                                                
                        if sinkCount == 1 && expectedCachedResponseDataModelIds != nil {
                            
                            cachedObjects = objects
                            
                            if loggingEnabled {
                                print("\n CACHE RESPONSE RECORDED: \(objects.map{$0.id})")
                            }
                        }
                        
                        if sinkCount == expectedNumberOfChanges {
                            
                            responseObjects = objects
                            
                            if loggingEnabled {
                                print("\n RESPONSE RECORDED: \(objects.map{$0.id})")
                                print("\n SINK COMPLETE")
                            }
                            
                            timeoutTask.cancel()
                            continuation.resume(returning: ())
                        }
                    }
                    .store(in: &cancellables)
            }
        }
        
        try deleteRealmDatabaseDirectory(directoryName: databaseDirectoryName)
                
        if let expectedCachedResponseDataModelIds = expectedCachedResponseDataModelIds {
            
            let cachedResponseDataModelIds: [String] = MockRepositorySyncDataModel.sortDataModelIds(dataModels: cachedObjects)
                        
            if loggingEnabled {
                print("\n EXPECT")
                print("  CACHE RESPONSE: \(cachedResponseDataModelIds)")
                print("  TO EQUAL: \(expectedCachedResponseDataModelIds)")
            }
            
            #expect(cachedResponseDataModelIds == expectedCachedResponseDataModelIds)
        }
        
        let responseDataModelIds: [String] = MockRepositorySyncDataModel.sortDataModelIds(dataModels: responseObjects)
        
        if loggingEnabled {
            print("\n EXPECT")
            print("  RESPONSE: \(responseDataModelIds)")
            print("  TO EQUAL: \(expectedResponseDataModelIds)")
        }
        
        #expect(responseDataModelIds == expectedResponseDataModelIds)
    }
    
    // MARK: - Run Swift Test
    
    @available(iOS 17.4, *)
    private func runSwiftTest(argument: TestArgument, getObjectsType: GetObjectsType, cachePolicy: CachePolicy, expectedNumberOfChanges: Int, triggerSecondaryExternalDataFetchWithIds: [String] = Array(), loggingEnabled: Bool = false) async throws {
        
        try await runSwiftTest(
            initialPersistedObjectsIds: argument.initialPersistedObjectsIds,
            externalDataModelIds: argument.externalDataModelIds,
            expectedCachedResponseDataModelIds: argument.expectedCachedResponseDataModelIds,
            expectedResponseDataModelIds: argument.expectedResponseDataModelIds,
            getObjectsType: getObjectsType,
            cachePolicy: cachePolicy,
            expectedNumberOfChanges: expectedNumberOfChanges,
            triggerSecondaryExternalDataFetchWithIds: triggerSecondaryExternalDataFetchWithIds,
            loggingEnabled: loggingEnabled
        )
    }
    
    @available(iOS 17.4, *)
    private func runSwiftTest(initialPersistedObjectsIds: [String], externalDataModelIds: [String], expectedCachedResponseDataModelIds: [String]?, expectedResponseDataModelIds: [String], getObjectsType: GetObjectsType, cachePolicy: CachePolicy, expectedNumberOfChanges: Int, triggerSecondaryExternalDataFetchWithIds: [String], loggingEnabled: Bool) async throws {
        
        if loggingEnabled {
            print("\n *** RUNNING SWIFT TEST *** \n")
        }
        
        let databaseDirectoryName: String = getUniqueDirectoryName()
        
        let triggersSecondaryExternalDataFetch: Bool = triggerSecondaryExternalDataFetchWithIds.count > 0
        
        if triggersSecondaryExternalDataFetch {
                        
            DispatchQueue.global().asyncAfter(deadline: .now() + triggerSecondaryExternalDataFetchWithDelayForSeconds) {

                // TODO: See if I can trigger another external data fetch by fetching from mock external data and writing objects to the database. ~Levi
                
                if loggingEnabled {
                    print("\n PERFORMING SECONDARY EXTERNAL DATA FETCH")
                }
                
                do {
                    
                    let persistence = try getSwiftRepositorySyncPersistence(
                        directoryName: databaseDirectoryName,
                        addObjects: []
                    )
                    
                    let externalDataFetch = self.getExternalDataFetch(
                        dataModels: MockRepositorySyncDataModel.createDataModelsFromIds(ids: triggerSecondaryExternalDataFetchWithIds)
                    )
                    
                    let additionalRepositorySync = RepositorySync<MockRepositorySyncDataModel, MockRepositorySyncExternalDataFetch>(
                        externalDataFetch: externalDataFetch,
                        persistence: persistence
                    )
                    
                    var cancellables: Set<AnyCancellable> = Set()
                    
                    additionalRepositorySync
                        .getObjectsPublisher(
                            getObjectsType: .allObjects,
                            cachePolicy: .fetchIgnoringCacheData,
                            context: MockExternalDataFetchContext()
                        )
                        .sink { completion in
                            
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                if loggingEnabled {
                                    print("\n DID COMPLETE SECONDARY DATA FETCH WITH ERROR: \(error)")
                                }
                            }
                            
                        } receiveValue: { (objects: [MockRepositorySyncDataModel]) in
                            
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
        
        let initialDataModels: [MockRepositorySyncDataModel] = MockRepositorySyncDataModel.createDataModelsFromIds(ids: initialPersistedObjectsIds)
        
        let externalDataFetch = getExternalDataFetch(dataModels: initialDataModels)
        
        let persistence = try getSwiftRepositorySyncPersistence(
            directoryName: databaseDirectoryName,
            addObjects: initialDataModels
        )

        let repositorySync = RepositorySync<MockRepositorySyncDataModel, MockRepositorySyncExternalDataFetch>(
            externalDataFetch: externalDataFetch,
            persistence: persistence
        )
        
        var sinkCount: Int = 0
        
        var cachedObjects: [MockRepositorySyncDataModel] = Array()
        var responseObjects: [MockRepositorySyncDataModel] = Array()
        
        var cancellables: Set<AnyCancellable> = Set()
        
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
                    .getObjectsPublisher(
                        getObjectsType: getObjectsType,
                        cachePolicy: cachePolicy,
                        context: MockExternalDataFetchContext()
                    )
                    .sink { completion in
                        
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            
                            if loggingEnabled {
                                print("\n DID COMPLETE WITH ERROR: \(error)")
                            }
                            
                            timeoutTask.cancel()
                            continuation.resume(returning: ())
                        }
                        
                    } receiveValue: { (objects: [MockRepositorySyncDataModel]) in
                        
                        confirmation()
                        
                        sinkCount += 1
                        
                        if loggingEnabled {
                            print("\n DID SINK")
                            print("  COUNT: \(sinkCount)")
                            print("  RESPONSE: \(objects.map{$0.id})")
                        }
                                                
                        if sinkCount == 1 && expectedCachedResponseDataModelIds != nil {
                            
                            cachedObjects = objects
                            
                            if loggingEnabled {
                                print("\n CACHE RESPONSE RECORDED: \(objects.map{$0.id})")
                            }
                        }
                        
                        if sinkCount == expectedNumberOfChanges {
                            
                            responseObjects = objects
                            
                            if loggingEnabled {
                                print("\n RESPONSE RECORDED: \(objects.map{$0.id})")
                                print("\n SINK COMPLETE")
                            }
                            
                            timeoutTask.cancel()
                            continuation.resume(returning: ())
                        }
                    }
                    .store(in: &cancellables)
            }
        }
        
        try deleteSwiftDatabaseDirectory(directoryName: databaseDirectoryName)
                        
        if let expectedCachedResponseDataModelIds = expectedCachedResponseDataModelIds {
            
            let cachedResponseDataModelIds: [String] = MockRepositorySyncDataModel.sortDataModelIds(dataModels: cachedObjects)
                        
            if loggingEnabled {
                print("\n EXPECT")
                print("  CACHE RESPONSE: \(cachedResponseDataModelIds)")
                print("  TO EQUAL: \(expectedCachedResponseDataModelIds)")
            }
            
            #expect(cachedResponseDataModelIds == expectedCachedResponseDataModelIds)
        }
        
        let responseDataModelIds: [String] = MockRepositorySyncDataModel.sortDataModelIds(dataModels: responseObjects)
        
        if loggingEnabled {
            print("\n EXPECT")
            print("  RESPONSE: \(responseDataModelIds)")
            print("  TO EQUAL: \(expectedResponseDataModelIds)")
        }
        
        #expect(responseDataModelIds == expectedResponseDataModelIds)
    }
}

// MARK: - Persistence

extension RepositorySyncTests {
 
    private func getRealmRepositorySyncPersistence(directoryName: String, addObjects: [MockRepositorySyncDataModel]) throws -> RealmRepositorySyncPersistence<MockRepositorySyncDataModel, MockRepositorySyncDataModel, MockRealmObject> {
        
        let realmDatabase = try MockRealmDatabase().createDatabase(
            directoryName: directoryName,
            objects: []
        )
        
        return RealmRepositorySyncPersistence(
            database: realmDatabase,
            dataModelMapping: MockRealmRepositorySyncMapping()
        )
    }
    
    @available(iOS 17.4, *)
    private func getSwiftRepositorySyncPersistence(directoryName: String, addObjects: [MockRepositorySyncDataModel]) throws -> SwiftRepositorySyncPersistence<MockRepositorySyncDataModel, MockRepositorySyncDataModel, MockSwiftObject> {
        
        let swiftDatabase = try MockSwiftDatabase().createDatabase(
            directoryName: directoryName,
            objects: []
        )
        
        return SwiftRepositorySyncPersistence(
            database: swiftDatabase,
            dataModelMapping: MockRepositorySyncMapping()
        )
    }
}

// MARK: - Database

extension RepositorySyncTests {
    
    private func getUniqueDirectoryName() -> String {
        return UUID().uuidString
    }
    
    private func getRealmDatabase(directoryName: String) throws -> RealmDatabase {
        return try MockRealmDatabase().createDatabase(directoryName: directoryName, ids: [])
    }
    
    private func deleteRealmDatabaseDirectory(directoryName: String) throws {
        try MockRealmDatabase().deleteDatabase(directoryName: directoryName)
    }
    
    @available(iOS 17.4, *)
    private func getSwiftDatabase(directoryName: String) throws -> SwiftDatabase {
        return try MockSwiftDatabase().createDatabase(directoryName: directoryName, ids: [])
    }
    
    @available(iOS 17.4, *)
    private func deleteSwiftDatabaseDirectory(directoryName: String) throws {
        try MockSwiftDatabase().deleteDatabase(directoryName: directoryName)
    }
}

// MARK: - Get External Data Fetch

extension RepositorySyncTests {

    private func getExternalDataFetch(dataModels: [MockRepositorySyncDataModel]) -> MockRepositorySyncExternalDataFetch {
        
        let externalDataFetch = MockRepositorySyncExternalDataFetch(
            objects: dataModels,
            delayRequestSeconds: mockExternalDataFetchDelayRequestForSeconds
        )
        
        return externalDataFetch
    }
}
