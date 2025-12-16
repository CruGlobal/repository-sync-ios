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
    func realmIgnoreCacheDataWillTriggerOnceSinceCacheIsIgnoredAndExternalFetchIsMade(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .get(cachePolicy: .fetchIgnoringCacheData),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: [],
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
    func realmIgnoreCacheDataWillTriggerOnceWithSingleObjectSinceCacheIsIgnoredAndExternalFetchIsMade(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            cachePolicy: .get(cachePolicy: .fetchIgnoringCacheData),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: [],
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
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
        )
    ])
    func realmReturnCacheDataDontFetchWillTriggerOnceWhenCacheDataAlreadyExists(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .observe(cachePolicy: .returnCacheDataDontFetch),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: [],
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["0", "1", "2"],
            externalDataModelIds: ["5", "4"],
            expectedCachedResponseDataModelIds: ["0", "1", "2"],
            expectedResponseDataModelIds: ["0", "1", "2", "8"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["3", "2"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["0", "1", "8"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["0", "1", "8"]
        )
    ])
    func realmReturnCacheDataDontFetchWillTriggerTwiceWhenObservingChangesOnceForInitialCacheDataAndAgainForSecondaryExternalDataFetch(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .observe(cachePolicy: .returnCacheDataDontFetch),
            expectedNumberOfChanges: 2,
            triggerSecondaryExternalDataFetchWithIds: ["8", "1", "0"],
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
    func realmReturnCacheDataDontFetchWillTriggerOnceWithSingleObjectWhenCacheDataAlreadyExists(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            cachePolicy: .observe(cachePolicy: .returnCacheDataDontFetch),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: [],
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
    func realmReturnCacheDataDontFetchWillTriggerTwiceWithSingleObjectWhenObservingChangesOnceForInitialCacheDataAndAgainForSecondaryExternalDataFetch(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            cachePolicy: .observe(cachePolicy: .returnCacheDataDontFetch),
            expectedNumberOfChanges: 2,
            triggerSecondaryExternalDataFetchWithIds: ["8", "1", "0"],
            shouldEnableSwiftDatabase: false,
            loggingEnabled: false
        )
    }
    
    
    
    
    
    
    
//    @Test(arguments: [
//        TestArgument(
//            initialPersistedObjectsIds: ["0", "1"],
//            externalDataModelIds: ["5", "6", "7", "8", "9"],
//            expectedCachedResponseDataModelIds: nil,
//            expectedResponseDataModelIds: ["0", "1", "5", "6", "7", "8", "9"]
//        )
//    ])
//    func ignoreCacheDataWillTriggerOnceSinceCacheIsIgnoredAndExternalFetchIsMade_1(argument: TestArgument) async throws {
//        
//        try await runRealmAndSwiftTest(
//            argument: argument,
//            getObjectsType: .allObjects,
//            cachePolicy: .get(cachePolicy: .fetchIgnoringCacheData),
//            expectedNumberOfChanges: 1,
//            loggingEnabled: true
//        )
//    }
//    
//    @Test(arguments: [
//        TestArgument(
//            initialPersistedObjectsIds: [],
//            externalDataModelIds: ["1", "2"],
//            expectedCachedResponseDataModelIds: nil,
//            expectedResponseDataModelIds: ["1", "2"]
//        )
//    ])
//    func ignoreCacheDataWillTriggerOnceSinceCacheIsIgnoredAndExternalFetchIsMade_2(argument: TestArgument) async throws {
//        
//        try await runRealmAndSwiftTest(
//            argument: argument,
//            getObjectsType: .allObjects,
//            cachePolicy: .get(cachePolicy: .fetchIgnoringCacheData),
//            expectedNumberOfChanges: 1,
//            loggingEnabled: true
//        )
//    }
//    
//    @Test(arguments: [
//        TestArgument(
//            initialPersistedObjectsIds: ["2", "3"],
//            externalDataModelIds: [],
//            expectedCachedResponseDataModelIds: nil,
//            expectedResponseDataModelIds: ["2", "3"]
//        )
//    ])
//    func ignoreCacheDataWillTriggerOnceSinceCacheIsIgnoredAndExternalFetchIsMade_3(argument: TestArgument) async throws {
//        
//        try await runRealmAndSwiftTest(
//            argument: argument,
//            getObjectsType: .allObjects,
//            cachePolicy: .get(cachePolicy: .fetchIgnoringCacheData),
//            expectedNumberOfChanges: 1,
//            loggingEnabled: true
//        )
//    }
//    
//    @Test(arguments: [
//        TestArgument(
//            initialPersistedObjectsIds: [],
//            externalDataModelIds: [],
//            expectedCachedResponseDataModelIds: nil,
//            expectedResponseDataModelIds: []
//        )
//    ])
//    func ignoreCacheDataWillTriggerOnceSinceCacheIsIgnoredAndExternalFetchIsMade_4(argument: TestArgument) async throws {
//        
//        try await runRealmAndSwiftTest(
//            argument: argument,
//            getObjectsType: .allObjects,
//            cachePolicy: .get(cachePolicy: .fetchIgnoringCacheData),
//            expectedNumberOfChanges: 1,
//            loggingEnabled: true
//        )
//    }
    
    // MARK: - SWIFT TESTS
    
    /*
    
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
    func ignoreCacheDataWillTriggerOnceSinceCacheIsIgnoredAndExternalFetchIsMade(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .get(cachePolicy: .fetchIgnoringCacheData),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: [],
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
    func ignoreCacheDataWillTriggerOnceWithSingleObjectSinceCacheIsIgnoredAndExternalFetchIsMade(argument: TestArgument) async throws {
        
        try await runTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            cachePolicy: .get(cachePolicy: .fetchIgnoringCacheData),
            expectedNumberOfChanges: 1,
            triggerSecondaryExternalDataFetchWithIds: [],
            shouldEnableSwiftDatabase: true,
            loggingEnabled: true
        )
    }
     */
    
    // MARK: - Original With Observe Changes
    
    /*
    
    // MARK: - Test Cache Policy (Ignoring Cache Data) - Objects
    
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
    func ignoreCacheDataWillTriggerOnceSinceCacheIsIgnoredAndExternalFetchIsMade(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .fetchIgnoringCacheData,
            expectedNumberOfChanges: 1
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .allObjects,
                cachePolicy: .fetchIgnoringCacheData,
                expectedNumberOfChanges: 1
            )
        }
    }
    
    // MARK: - Test Cache Policy (Ignoring Cache Data) - Object ID
    
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
    func ignoreCacheDataWillTriggerOnceWithSingleObjectSinceCacheIsIgnoredAndExternalFetchIsMade(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            cachePolicy: .fetchIgnoringCacheData,
            expectedNumberOfChanges: 1
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .object(id: "1"),
                cachePolicy: .fetchIgnoringCacheData,
                expectedNumberOfChanges: 1
            )
        }
    }
    
    // MARK: - Test Cache Policy (Return Cache Data Don't Fetch) - Objects
    
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
    func returnCacheDataDontFetchWillTriggerOnceWhenCacheDataAlreadyExists(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .returnCacheDataDontFetch(observeChanges: false),
            expectedNumberOfChanges: 1
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .allObjects,
                cachePolicy: .returnCacheDataDontFetch(observeChanges: false),
                expectedNumberOfChanges: 1
            )
        }
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["0", "1", "2"],
            externalDataModelIds: ["5", "4"],
            expectedCachedResponseDataModelIds: ["0", "1", "2"],
            expectedResponseDataModelIds: ["0", "1", "2", "8"]
        ),
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["3", "2"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["0", "1", "8"]
        )
    ])
    func returnCacheDataDontFetchWillTriggerTwiceWhenObservingChangesOnceForInitialCacheDataAndAgainForSecondaryExternalDataFetch(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .returnCacheDataDontFetch(observeChanges: true),
            expectedNumberOfChanges: 2,
            triggerSecondaryExternalDataFetchWithIds: ["8", "1", "0"]
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .allObjects,
                cachePolicy: .returnCacheDataDontFetch(observeChanges: true),
                expectedNumberOfChanges: 2,
                triggerSecondaryExternalDataFetchWithIds: ["8", "1", "0"]
            )
        }
    }
    
    // MARK: - Test Cache Policy (Return Cache Data Don't Fetch) - Object ID
    
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
    func returnCacheDataDontFetchWillTriggerOnceWithSingleObjectWhenCacheDataAlreadyExists(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            cachePolicy: .returnCacheDataDontFetch(observeChanges: false),
            expectedNumberOfChanges: 1
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .object(id: "1"),
                cachePolicy: .returnCacheDataDontFetch(observeChanges: false),
                expectedNumberOfChanges: 1
            )
        }
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
    func returnCacheDataDontFetchWillTriggerTwiceWithSingleObjectWhenObservingChangesOnceForInitialCacheDataAndAgainForSecondaryExternalDataFetch(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            cachePolicy: .returnCacheDataDontFetch(observeChanges: true),
            expectedNumberOfChanges: 2,
            triggerSecondaryExternalDataFetchWithIds: ["8", "1", "0"]
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .object(id: "1"),
                cachePolicy: .returnCacheDataDontFetch(observeChanges: true),
                expectedNumberOfChanges: 2,
                triggerSecondaryExternalDataFetchWithIds: ["8", "1", "0"]
            )
        }
    }
    
    // MARK: - Test Cache Policy (Return Cache Data Else Fetch) - Objects
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["0", "1"],
            externalDataModelIds: ["5", "6", "7", "8", "9"],
            expectedCachedResponseDataModelIds: ["0", "1"],
            expectedResponseDataModelIds: ["0", "1"]
        ),
        TestArgument(
            initialPersistedObjectsIds: ["1", "2"],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: ["1", "2"],
            expectedResponseDataModelIds: ["1", "2"]
        )
    ])
    func returnCacheDataElseFetchIsTriggeredOnceWhenCacheDataAlreadyExists(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .returnCacheDataElseFetch(observeChanges: false),
            expectedNumberOfChanges: 1
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .allObjects,
                cachePolicy: .returnCacheDataElseFetch(observeChanges: false),
                expectedNumberOfChanges: 1
            )
        }
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["5", "6", "7"],
            expectedCachedResponseDataModelIds: nil,
            expectedResponseDataModelIds: ["5", "6", "7"]
        )
    ])
    func returnCacheDataElseFetchIsTriggeredOnceWhenNoCacheDataExistsAndExternalDataIsFetchedAndNotObservingChanges(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .returnCacheDataElseFetch(observeChanges: false),
            expectedNumberOfChanges: 1
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .allObjects,
                cachePolicy: .returnCacheDataElseFetch(observeChanges: false),
                expectedNumberOfChanges: 1
            )
        }
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["5", "6", "7"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["5", "6", "7"]
        )
    ])
    func returnCacheDataElseFetchIsTriggeredTwiceWhenNoCacheDataExistsAndExternalDataIsFetchedAndIsObservingChanges(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .returnCacheDataElseFetch(observeChanges: true),
            expectedNumberOfChanges: 2
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .allObjects,
                cachePolicy: .returnCacheDataElseFetch(observeChanges: true),
                expectedNumberOfChanges: 2
            )
        }
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["5", "6", "7"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["5", "6", "7", "9"]
        )
    ])
    func returnCacheDataElseFetchIsTriggeredThreeTimesWhenCacheIsEmptyOnExternalDataFetchAndOnSecondaryExternalDataFetch(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .returnCacheDataElseFetch(observeChanges: true),
            expectedNumberOfChanges: 3,
            triggerSecondaryExternalDataFetchWithIds: ["9", "7"]
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .allObjects,
                cachePolicy: .returnCacheDataElseFetch(observeChanges: true),
                expectedNumberOfChanges: 3,
                triggerSecondaryExternalDataFetchWithIds: ["9", "7"]
            )
        }
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["1", "2"],
            externalDataModelIds: ["3", "5", "4"],
            expectedCachedResponseDataModelIds: ["1", "2"],
            expectedResponseDataModelIds: ["1", "2", "7", "9"]
        )
    ])
    func returnCacheDataElseFetchIsTriggeredTwiceWhenCacheHasDataAndOnSecondaryExternalDataFetch(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .returnCacheDataElseFetch(observeChanges: true),
            expectedNumberOfChanges: 2,
            triggerSecondaryExternalDataFetchWithIds: ["9", "7"]
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .allObjects,
                cachePolicy: .returnCacheDataElseFetch(observeChanges: true),
                expectedNumberOfChanges: 2,
                triggerSecondaryExternalDataFetchWithIds: ["9", "7"]
            )
        }
    }
    
    // MARK: - Test Cache Policy (Return Cache Data Else Fetch) - Object ID
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["0", "1"],
            externalDataModelIds: ["5", "6", "7", "8", "9"],
            expectedCachedResponseDataModelIds: ["1"],
            expectedResponseDataModelIds: ["1"]
        ),
        TestArgument(
            initialPersistedObjectsIds: ["1", "2"],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: ["1"],
            expectedResponseDataModelIds: ["1"]
        )
    ])
    func returnCacheDataElseFetchIsTriggeredOnceWithSingleObjectWhenCacheDataAlreadyExists(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            cachePolicy: .returnCacheDataElseFetch(observeChanges: false),
            expectedNumberOfChanges: 1
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .object(id: "1"),
                cachePolicy: .returnCacheDataElseFetch(observeChanges: false),
                expectedNumberOfChanges: 1
            )
        }
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["5", "6", "7"],
            expectedCachedResponseDataModelIds: nil,
            expectedResponseDataModelIds: ["6"]
        )
    ])
    func returnCacheDataElseFetchIsTriggeredOnceWithSingleObjectWhenNoCacheDataExistsAndExternalDataIsFetchedAndNotObservingChanges(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .object(id: "6"),
            cachePolicy: .returnCacheDataElseFetch(observeChanges: false),
            expectedNumberOfChanges: 1
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .object(id: "6"),
                cachePolicy: .returnCacheDataElseFetch(observeChanges: false),
                expectedNumberOfChanges: 1
            )
        }
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["5", "6", "7"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["7"]
        )
    ])
    func returnCacheDataElseFetchIsTriggeredTwiceWithSingleObjectWhenNoCacheDataExistsAndExternalDataIsFetchedAndIsObservingChanges(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .object(id: "7"),
            cachePolicy: .returnCacheDataElseFetch(observeChanges: true),
            expectedNumberOfChanges: 2
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .object(id: "7"),
                cachePolicy: .returnCacheDataElseFetch(observeChanges: true),
                expectedNumberOfChanges: 2
            )
        }
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: [],
            externalDataModelIds: ["5", "6", "7", "9"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["9"]
        )
    ])
    func returnCacheDataElseFetchIsTriggeredThreeTimesWithSingleObjectWhenCacheIsEmptyOnExternalDataFetchAndOnSecondaryExternalDataFetch(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .object(id: "9"),
            cachePolicy: .returnCacheDataElseFetch(observeChanges: true),
            expectedNumberOfChanges: 3,
            triggerSecondaryExternalDataFetchWithIds: ["9", "7"]
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .object(id: "9"),
                cachePolicy: .returnCacheDataElseFetch(observeChanges: true),
                expectedNumberOfChanges: 3,
                triggerSecondaryExternalDataFetchWithIds: ["9", "7"]
            )
        }
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["1", "2"],
            externalDataModelIds: ["3", "5", "4"],
            expectedCachedResponseDataModelIds: ["1"],
            expectedResponseDataModelIds: ["1"]
        )
    ])
    func returnCacheDataElseFetchIsTriggeredTwiceWithSingleObjectWhenCacheHasDataAndOnSecondaryExternalDataFetch(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .object(id: "1"),
            cachePolicy: .returnCacheDataElseFetch(observeChanges: true),
            expectedNumberOfChanges: 2,
            triggerSecondaryExternalDataFetchWithIds: ["1", "7"]
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .object(id: "1"),
                cachePolicy: .returnCacheDataElseFetch(observeChanges: true),
                expectedNumberOfChanges: 2,
                triggerSecondaryExternalDataFetchWithIds: ["1", "7"]
            )
        }
    }
    
    // MARK: - Test Cache Policy (Return Cache Data And Fetch) - Objects

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
    func returnCacheDataAndFetchWillTriggerOnceWhenNoExternalDataExists(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .returnCacheDataAndFetch,
            expectedNumberOfChanges: 1
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .allObjects,
                cachePolicy: .returnCacheDataAndFetch,
                expectedNumberOfChanges: 1
            )
        }
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
    func returnCacheDataAndFetchWillTriggerTwiceWhenExternalDataExists(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .returnCacheDataAndFetch,
            expectedNumberOfChanges: 2
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .allObjects,
                cachePolicy: .returnCacheDataAndFetch,
                expectedNumberOfChanges: 2
            )
        }
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
    func returnCacheDataAndFetchWillTriggerThreeTimesOnceForInitialCacheDataForExternalDataFetchAndSecondaryExternalDataFetch(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .allObjects,
            cachePolicy: .returnCacheDataAndFetch,
            expectedNumberOfChanges: 3,
            triggerSecondaryExternalDataFetchWithIds: ["9", "5"]
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .allObjects,
                cachePolicy: .returnCacheDataAndFetch,
                expectedNumberOfChanges: 3,
                triggerSecondaryExternalDataFetchWithIds: ["9", "5"]
            )
        }
    }
    
    // MARK: - Test Cache Policy (Return Cache Data And Fetch) - Object ID
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["0", "1"],
            externalDataModelIds: ["3"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["3"]
        )
    ])
    func returnCacheDataAndFetchWillTriggerTwiceWithSingleObjectWhenExternalDataExists(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .object(id: "3"),
            cachePolicy: .returnCacheDataAndFetch,
            expectedNumberOfChanges: 2
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .object(id: "3"),
                cachePolicy: .returnCacheDataAndFetch,
                expectedNumberOfChanges: 2
            )
        }
    }
    
    @Test(arguments: [
        TestArgument(
            initialPersistedObjectsIds: ["0", "1"],
            externalDataModelIds: [],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["3"]
        ),
        TestArgument(
            initialPersistedObjectsIds: ["0", "1"],
            externalDataModelIds: ["5"],
            expectedCachedResponseDataModelIds: [],
            expectedResponseDataModelIds: ["3"]
        )
    ])
    func returnCacheDataAndFetchWillTriggerTwiceWithSingleObjectWhenAdditionalDataExists(argument: TestArgument) async throws {
        
        try await runRealmTest(
            argument: argument,
            getObjectsType: .object(id: "3"),
            cachePolicy: .returnCacheDataAndFetch,
            expectedNumberOfChanges: 2,
            triggerSecondaryExternalDataFetchWithIds: ["3"]
        )
        
        if #available(iOS 17.4, *) {
            
            try await runSwiftTest(
                argument: argument,
                getObjectsType: .object(id: "3"),
                cachePolicy: .returnCacheDataAndFetch,
                expectedNumberOfChanges: 2,
                triggerSecondaryExternalDataFetchWithIds: ["3"]
            )
        }
    }
    
    */
    
    // MARK: - Run Test
    
    @MainActor private func runTest(argument: TestArgument, getObjectsType: GetObjectsType, cachePolicy: CachePolicy, expectedNumberOfChanges: Int, triggerSecondaryExternalDataFetchWithIds: [String], shouldEnableSwiftDatabase: Bool, loggingEnabled: Bool) async throws {
        
        let testName: String = shouldEnableSwiftDatabase ? "SWIFT" : "REALM"
        
        let initialPersistedObjectsIds: [String] = argument.initialPersistedObjectsIds
        let externalDataModelIds: [String] = argument.externalDataModelIds
        let expectedCachedResponseDataModelIds: [String]? = argument.expectedCachedResponseDataModelIds
        let expectedResponseDataModelIds: [String] = argument.expectedResponseDataModelIds
        
        if loggingEnabled {
            print("\n *** RUNNING \(testName) TEST *** \n")
            print("  initial persisted object ids: \(initialPersistedObjectsIds) ")
            print("  external data model ids: \(externalDataModelIds) ")
        }
        
        var cancellables: Set<AnyCancellable> = Set()
                
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
                        .getObjectsPublisher(
                            getObjectsType: .allObjects,
                            cachePolicy: .get(cachePolicy: .fetchIgnoringCacheData),
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
                        
                    } receiveValue: { (objects: [MockDataModel]) in
                        
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
             
        if let expectedCachedResponseDataModelIds = expectedCachedResponseDataModelIds {
            
            let cachedResponseDataModelIds: [String] = MockDataModel.sortDataModelIds(dataModels: cachedObjects)
                        
            if loggingEnabled {
                print("\n EXPECT")
                print("  CACHE RESPONSE: \(cachedResponseDataModelIds)")
                print("  TO EQUAL: \(expectedCachedResponseDataModelIds)")
            }
            
            #expect(cachedResponseDataModelIds == expectedCachedResponseDataModelIds)
        }
        
        let responseDataModelIds: [String] = MockDataModel.sortDataModelIds(dataModels: responseObjects)
        
        if loggingEnabled {
            print("\n EXPECT")
            print("  RESPONSE: \(responseDataModelIds)")
            print("  TO EQUAL: \(expectedResponseDataModelIds)")
        }
        
        #expect(responseDataModelIds == expectedResponseDataModelIds)
    }
}

// MARK: - RepositorySync

extension RepositorySyncTests {
    
    private func getSharedRealmDatabase(addObjects: [MockRealmObject], shouldDeleteExistingObjects: Bool) throws -> RealmDatabase {
        return try MockRealmDatabase().getSharedDatabase(objects: addObjects, shouldDeleteExistingObjects: shouldDeleteExistingObjects)
    }
    
    @available(iOS 17.4, *)
    private func getSharedSwiftDatabase(addObjects: [MockSwiftObject], shouldDeleteExistingObjects: Bool) throws -> SwiftDatabase {
        return try MockSwiftDatabase().getSharedDatabase(objects: addObjects, shouldDeleteExistingObjects: shouldDeleteExistingObjects)
    }
    
    @MainActor private func getRepositorySync(externalDataFetch: MockExternalDataFetch, addObjectsToDatabase: [MockDataModel], shouldDeleteExistingObjectsInDatabase: Bool, shouldEnableSwiftDatabase: Bool) throws -> RepositorySync<MockDataModel, MockExternalDataFetch, MockRealmObject> {
        
        let realmObjects: [MockRealmObject] = addObjectsToDatabase.map {
            MockRealmObject.createObject(id: $0.id, name: $0.name)
        }
        
        let realmDatabase: RealmDatabase = try getSharedRealmDatabase(addObjects: realmObjects, shouldDeleteExistingObjects: shouldDeleteExistingObjectsInDatabase)
        
        let realmPersistence = RealmRepositorySyncPersistence(
            database: realmDatabase,
            dataModelMapping: MockRealmRepositorySyncMapping()
        )
        
        if #available(iOS 17.4, *), shouldEnableSwiftDatabase {
            
            let swiftObjects: [MockSwiftObject] = addObjectsToDatabase.map {
                MockSwiftObject.createObject(id: $0.id, name: $0.name)
            }
            
            let swiftDatabase: SwiftDatabase = try getSharedSwiftDatabase(addObjects: swiftObjects, shouldDeleteExistingObjects: shouldDeleteExistingObjectsInDatabase)
            
            GlobalSwiftDatabase.shared.enableSwiftDatabase(
                swiftDatabase: swiftDatabase
            )
        }
        
        let swiftElseRealmPersistence = MockSwiftElseRealmPersistence(
            realmPersistence: realmPersistence
        )
        
        let repositorySync = MockRepositorySync(
            externalDataFetch: externalDataFetch,
            swiftElseRealmPersistence: swiftElseRealmPersistence
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
