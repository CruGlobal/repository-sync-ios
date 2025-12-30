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
import RealmSwift

@Suite(.serialized)
@MainActor struct RepositorySyncTests {
            
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
    
    // MARK: - REALM TESTS

    // MARK: - Realm Test Cache Policy (Get Ignoring Cache Data) - Objects
    
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
    func realmGetIgnoreCacheDataWillTriggerOnceOnExternalFetchWithAllObjects(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            fetchType: .get(cachePolicy: .ignoreCacheData),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: nil,
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    // MARK: - Realm Test Cache Policy (Get Ignoring Cache Data) - Object ID
    
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
    func realmGetIgnoreCacheDataWillTriggerOnceOnExternalFetchWithObject(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            fetchType: .get(cachePolicy: .ignoreCacheData),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: nil,
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    // MARK: - Realm Test Cache Policy (Get Return Cache Data Don't Fetch) - Objects
    
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
    func realmGetReturnCacheDataDontFetchWillTriggerOnceWithAllObjects(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            fetchType: .get(cachePolicy: .returnCacheDataDontFetch),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: nil,
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    // MARK: - Realm Test Cache Policy (Get Return Cache Data Don't Fetch) - Object ID
    
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
    func realmGetReturnCacheDataDontFetchWillTriggerOnceWithObject(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            fetchType: .get(cachePolicy: .returnCacheDataDontFetch),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: nil,
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    // MARK: - Realm Test Cache Policy (Get Return Cache Data Else Fetch) - Objects
    
    // MARK: - Realm Test Cache Policy (Get Return Cache Data Else Fetch) - Object ID
    
    // MARK: - Realm Test Cache Policy (Observe Return Cache Data Don't Fetch) - Objects
    
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
    func realmObserveReturnCacheDataDontFetchWillTriggerOnceWithAllObjects(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            fetchType: .observe(cachePolicy: .returnCacheDataDontFetch),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: nil,
            shouldEnableSwiftDatabase: false,
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
    func realmObserveReturnCacheDataDontFetchWillTriggerTwiceWithAllObjectsAndOnSecondaryExternalFetch(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            fetchType: .observe(cachePolicy: .returnCacheDataDontFetch),
            expectedNumberOfChanges: 2,
            triggerSecondaryExternalDataFetchWithIds: ["8", "9"],
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    // MARK: - Realm Test Cache Policy (Observe Return Cache Data Don't Fetch) - Object ID
    
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
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: []
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: []
        )
    ])
    func realmObserveReturnCacheDataDontFetchWillTriggerOnceWithObject(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            fetchType: .observe(cachePolicy: .returnCacheDataDontFetch),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: nil,
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["0", "1", "2"],
            externalDataModelIds: ["5", "4"],
            expectedCachedResponseDataModelIds: ["1"],
            expectedResponseDataModelIds: ["1"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["3", "2"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["1"]
        )
    ])
    func realmObserveReturnCacheDataDontFetchWillTriggerTwiceWithObjectAndOnSecondaryExternalDataFetch(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            fetchType: .observe(cachePolicy: .returnCacheDataDontFetch),
            expectedNumberOfChanges: 2,
            triggerSecondaryExternalDataFetchWithIds: ["8", "1", "0"],
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    // MARK: - Realm Test Cache Policy (Observe Return Cache Data Else Fetch) - Objects
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["5", "6", "7"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["5", "6", "7"]
        )
    ])
    func realmObserveReturnCacheDataElseFetchIsTriggeredTwiceWhenNoCacheDataExistsAndOnExternalDataFetch(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            fetchType: .observe(cachePolicy: .returnCacheDataElseFetch),
            expectedNumberOfChanges: 2,
            triggerSecondaryExternalDataFetchWithIds: nil,
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["5", "6", "7"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["5", "6", "7", "9"]
        )
    ])
    func realmObserveReturnCacheDataElseFetchIsTriggeredThreeTimesWithCachedObjectsAndExternalDataFetchAndOnSecondaryExternalDataFetch(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            fetchType: .observe(cachePolicy: .returnCacheDataElseFetch),
            expectedNumberOfChanges: 3,
            triggerSecondaryExternalDataFetchWithIds: ["9", "7"],
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["1", "2"],
            externalDataModelIds: ["3", "5", "4"],
            expectedCachedResponseDataModelIds: ["1", "2"],
            expectedResponseDataModelIds: ["1", "2", "7", "9"]
        )
    ])
    func realmObserveReturnCacheDataElseFetchIsTriggeredTwiceWithCachedObjectsAndOnSecondaryExternalDataFetch(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            fetchType: .observe(cachePolicy: .returnCacheDataElseFetch),
            expectedNumberOfChanges: 2,
            triggerSecondaryExternalDataFetchWithIds: ["9", "7"],
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    // MARK: - Realm Test Cache Policy (Observe Return Cache Data Else Fetch) - Object ID
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["5", "6", "7"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["7"]
        )
    ])
    func realmObserveReturnCacheDataElseFetchIsTriggeredTwiceWithCachedObjectAndExternalDataFetch(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .object(id: "7"),
            fetchType: .observe(cachePolicy: .returnCacheDataElseFetch),
            expectedNumberOfChanges: 2,
            triggerSecondaryExternalDataFetchWithIds: nil,
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["5", "6", "7", "9"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["9"]
        )
    ])
    func realmObserveReturnCacheDataElseFetchIsTriggeredThreeTimesWithCachedObjectAndExternalDataFetchAndOnSecondaryExternalDataFetch(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .object(id: "9"),
            fetchType: .observe(cachePolicy: .returnCacheDataElseFetch),
            expectedNumberOfChanges: 3,
            triggerSecondaryExternalDataFetchWithIds: ["9", "7"],
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["1", "2"],
            externalDataModelIds: ["3", "5", "4"],
            expectedCachedResponseDataModelIds: ["1"],
            expectedResponseDataModelIds: ["1"]
        )
    ])
    func realmObserveReturnCacheDataElseFetchIsTriggeredTwiceWithCachedObjectAndOnSecondaryExternalDataFetch(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            fetchType: .observe(cachePolicy: .returnCacheDataElseFetch),
            expectedNumberOfChanges: 2,
            triggerSecondaryExternalDataFetchWithIds: ["1", "7"],
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    // MARK: - Realm Test Cache Policy (Observe Return Cache Data And Fetch) - Objects
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: []
        ),
        TestArgument(
            initialPersistedObjectsIds: ["0", "1"],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: ["0", "1"],
            expectedResponseDataModelIds: ["0", "1"]
        )
    ])
    func realmObserveReturnCacheDataAndFetchWillTriggerOnceWhenNoExternalDataExists(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            fetchType: .observe(cachePolicy: .returnCacheDataAndFetch),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: nil,
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }

    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["0", "1"],
            externalDataModelIds: ["2"],
            expectedCachedResponseDataModelIds: ["0", "1"],
            expectedResponseDataModelIds: ["0", "1", "2"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["4", "5"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["4", "5"]
        )
    ])
    func realmObserveReturnCacheDataAndFetchWillTriggerTwiceWhenExternalDataExists(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            fetchType: .observe(cachePolicy: .returnCacheDataAndFetch),
            expectedNumberOfChanges: 2,
            triggerSecondaryExternalDataFetchWithIds: nil,
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["0", "1"],
            externalDataModelIds: ["2"],
            expectedCachedResponseDataModelIds: ["0", "1"],
            expectedResponseDataModelIds: ["0", "1", "2", "5", "9"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["4", "5"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["4", "5", "9"]
        )
    ])
    func realmObserveReturnCacheDataAndFetchWillTriggerThreeTimesOnceForInitialCacheDataForExternalDataFetchAndSecondaryExternalDataFetch(argument: TestArgument) async throws {
        
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            fetchType: .observe(cachePolicy: .returnCacheDataAndFetch),
            expectedNumberOfChanges: 3,
            triggerSecondaryExternalDataFetchWithIds: ["9", "5"],
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    // MARK: - Realm Test Cache Policy (Observe Return Cache Data And Fetch) - Object ID
    
    
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
    func getIgnoreCacheDataWillTriggerOnceOnExternalFetchWithAllObjects(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            fetchType: .get(cachePolicy: .ignoreCacheData),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: nil,
            shouldEnableSwiftDatabase: true,
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
    func getIgnoreCacheDataWillTriggerOnceOnExternalFetchWithObject(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            fetchType: .get(cachePolicy: .ignoreCacheData),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: nil,
            shouldEnableSwiftDatabase: true,
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
    func getReturnCacheDataDontFetchWillTriggerOnceWithAllObjects(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            fetchType: .get(cachePolicy: .returnCacheDataDontFetch),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: nil,
            shouldEnableSwiftDatabase: true,
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
    func getReturnCacheDataDontFetchWillTriggerOnceWithObject(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            fetchType: .get(cachePolicy: .returnCacheDataDontFetch),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: nil,
            shouldEnableSwiftDatabase: true,
            loggingEnabled: false
        )
    }
    
    // MARK: - Swift Test Cache Policy (Get Return Cache Data Else Fetch) - Objects
    
    // MARK: - Swift Test Cache Policy (Get Return Cache Data Else Fetch) - Object ID
    
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
    func observeReturnCacheDataDontFetchWillTriggerOnceWithAllObjects(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            fetchType: .observe(cachePolicy: .returnCacheDataDontFetch),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: nil,
            shouldEnableSwiftDatabase: true,
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
    func observeReturnCacheDataDontFetchWillTriggerTwiceWithAllObjectsAndOnSecondaryExternalFetch(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            fetchType: .observe(cachePolicy: .returnCacheDataDontFetch),
            expectedNumberOfChanges: 2,
            triggerSecondaryExternalDataFetchWithIds: ["8", "9"],
            shouldEnableSwiftDatabase: true,
            loggingEnabled: false
        )
    }
    
    // MARK: - Run Test
    
    @MainActor private func runTest(argument: TestArgument, getObjectsType: GetObjectsType, fetchType: FetchType, expectedNumberOfChanges: Int, triggerSecondaryExternalDataFetchWithIds: [String]?, shouldEnableSwiftDatabase: Bool, loggingEnabled: Bool) async throws {
        
        let testName: String = shouldEnableSwiftDatabase ? "SWIFT" : "REALM"
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
                        
            DispatchQueue.main.asyncAfter(deadline: .now() + triggerSecondaryExternalDataFetchWithDelayForSeconds) {

                // TODO: See if I can trigger another external data fetch by fetching from mock external data and writing objects to the database. ~Levi
                
                if loggingEnabled {
                    print("\n PERFORMING SECONDARY EXTERNAL DATA FETCH WITH IDS: \(triggerSecondaryExternalDataFetchWithIds)")
                }
                
                do {
                    
                    let additionalRepositorySync = try getRepositorySync(
                        externalDataFetch: getExternalDataFetch(dataModels: MockDataModel.createDataModelsFromIds(ids: triggerSecondaryExternalDataFetchWithIds)),
                        addObjectsToDatabase: [],
                        shouldDeleteExistingObjectsInDatabase: false,
                        shouldEnableSwiftDatabase: shouldEnableSwiftDatabase
                    )
                    
                    additionalRepositorySync
                        .syncObjectsPublisher(
                            fetchType: .get(cachePolicy: .ignoreCacheData),
                            getObjectsType: .allObjects,
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
            shouldDeleteExistingObjectsInDatabase: true,
            shouldEnableSwiftDatabase: shouldEnableSwiftDatabase
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
                    .syncObjectsPublisher(
                        fetchType: fetchType,
                        getObjectsType: getObjectsType,
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

extension RepositorySyncTests {
    
    private func getSharedRealmDatabase(addObjects: [MockRealmObject], shouldDeleteExistingObjects: Bool) throws -> RealmDatabase {
        let directoryName: String = "realm_\(String(describing: RepositorySyncTests.self))"
        return try MockRealmDatabase().createDatabase(directoryName: directoryName, objects: addObjects, shouldDeleteExistingObjects: shouldDeleteExistingObjects)
    }
    
    @available(iOS 17.4, *)
    private func getSharedSwiftDatabase(addObjects: [MockSwiftObject], shouldDeleteExistingObjects: Bool) throws -> SwiftDatabase {
        let directoryName: String = "swift_\(String(describing: RepositorySyncTests.self))"
        return try MockSwiftDatabase().createDatabase(directoryName: directoryName, objects: addObjects, shouldDeleteExistingObjects: shouldDeleteExistingObjects)
    }
    
    @MainActor private func getRepositorySync(externalDataFetch: MockExternalDataFetch, addObjectsToDatabase: [MockDataModel], shouldDeleteExistingObjectsInDatabase: Bool, shouldEnableSwiftDatabase: Bool) throws -> RepositorySync<MockDataModel, MockExternalDataFetch> {
        
        let persistence: any Persistence<MockDataModel, MockDataModel>
        
        if #available(iOS 17.4, *), shouldEnableSwiftDatabase {
            
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
        }
        else {
            
            let realmObjects: [MockRealmObject] = addObjectsToDatabase.map {
                MockRealmObject.createFrom(interface: $0)
            }
            
            let realmDatabase: RealmDatabase = try getSharedRealmDatabase(
                addObjects: realmObjects,
                shouldDeleteExistingObjects: shouldDeleteExistingObjectsInDatabase
            )
            
            persistence = RealmRepositorySyncPersistence(
                database: realmDatabase,
                dataModelMapping: MockRealmRepositorySyncMapping()
            )
        }
        
        let repositorySync = RepositorySync(
            externalDataFetch: externalDataFetch,
            persistence: persistence
        )
        
        return repositorySync
    }
}

// MARK: - Get External Data Fetch

extension RepositorySyncTests {

    private func getExternalDataFetch(dataModels: [MockDataModel]) -> MockExternalDataFetch {
        
        let externalDataFetch = MockExternalDataFetch(
            objects: dataModels,
            delayRequestSeconds: mockExternalDataFetchDelayRequestForSeconds
        )
        
        return externalDataFetch
    }
}
