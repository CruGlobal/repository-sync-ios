//
//  RealmActorReadTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 5/22/26.
//  Copyright © 2026 Cru. All rights reserved.
//

import Foundation
import Testing
@testable import RepositorySync
import RealmSwift

struct RealmActorReadTests {
    
    private let allObjectIds: Set<String> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    @Test()
    func getObjectById() async throws {
                
        let realmActorRead: RealmActorRead = try await getRealmActorRead()
        
        let objectId: String = "0"
                
        let object: MockDataModel = try #require(await realmActorRead.getDataModel(id: objectId))
                
        #expect(object.id == objectId)
    }
    
    @Test()
    func getObjectByIdIsNilWhenDoesntExist() async throws {
                
        let realmActorRead: RealmActorRead = try await getRealmActorRead()
        
        let objectId: String = UUID().uuidString
                
        let object: MockDataModel? = await realmActorRead.getDataModel(id: objectId)
                
        #expect(object == nil)
    }
    
    @Test()
    func getObjectsByIds() async throws {
                
        let realmActorRead: RealmActorRead = try await getRealmActorRead()
                        
        let getObjectIds: Set<String> = ["2", "4", "6"]
        
        let objects: [MockDataModel] = await realmActorRead.getDataModels(
            ids: getObjectIds,
            sortBykeyPath: nil
        )
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
                
        #expect(objectIds == getObjectIds)
    }
    
    @Test()
    func getObjectsByIdsAscendingFalse() async throws {
                
        let realmActorRead: RealmActorRead = try await getRealmActorRead()
                        
        let getObjectIds: Set<String> = ["6", "4", "2"]
        
        let objects: [MockDataModel] = await realmActorRead.getDataModels(
            ids: getObjectIds,
            sortBykeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false)
        )
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
                
        #expect(objectIds == getObjectIds)
    }
    
    @Test()
    func getObjectByFilter() async throws {
                
        let realmActorRead: RealmActorRead = try await getRealmActorRead()
                
        let predicate = NSPredicate(format: "\(#keyPath(MockRealmObject.position)) == %@", NSNumber(value: 0))
        
        let query = RealmDatabaseQuery.filter(filter: predicate)
        
        let objects: [MockDataModel] = await realmActorRead.getDataModels(query: query)
        
        let object: MockDataModel = try #require(objects.first)
                
        #expect(object.id == "0")
    }
    
    @Test()
    func getObjectsBySortAscendingTrue() async throws {
                
        let realmActorRead: RealmActorRead = try await getRealmActorRead()
                        
        let query = RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: true))
        
        let objects: [MockDataModel] = await realmActorRead.getDataModels(query: query)
                
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    }
    
    @Test()
    func getObjectsBySortAscendingFalse() async throws {
                
        let realmActorRead: RealmActorRead = try await getRealmActorRead()
                        
        let query = RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false))
        
        let objects: [MockDataModel] = await realmActorRead.getDataModels(query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
    }
    
    @Test()
    func getObjectByFilterAndSort() async throws {
                
        let realmActorRead: RealmActorRead = try await getRealmActorRead()
                
        let isEvenPosition = NSPredicate(format: "\(#keyPath(MockRealmObject.isEvenPosition)) == %@", NSNumber(value: true))
        
        let query = RealmDatabaseQuery(
            filter: isEvenPosition,
            sortByKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false)
        )
        
        let objects: [MockDataModel] = await realmActorRead.getDataModels(query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [8, 6, 4, 2, 0])
    }
    
    @Test()
    func readAllObjects() async throws {
        
        let realmActorRead: RealmActorRead = try await getRealmActorRead()
        
        let objects: [MockDataModel] =  try await realmActorRead.getDataModels(readObjectsType: .allObjects)
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
        
        #expect(objectIds == allObjectIds)
    }
    
    @Test()
    func readObjectById() async throws {
        
        let realmActorRead: RealmActorRead = try await getRealmActorRead()
        
        let objectId: String = "0"
        
        let objects: [MockDataModel] =  try await realmActorRead.getDataModels(readObjectsType: .object(id: objectId))
        
        let object: MockDataModel = try #require(objects.first)
        
        #expect(object.id == objectId)
    }
    
    @Test()
    func readObjectByIdIsEmptyWhenObjectDoesntExist() async throws {
        
        let realmActorRead: RealmActorRead = try await getRealmActorRead()
        
        let objectId: String = UUID().uuidString
        
        let objects: [MockDataModel] =  try await realmActorRead.getDataModels(readObjectsType: .object(id: objectId))
                
        #expect(objects.count == 0)
    }
    
    @Test()
    func readObjectsByIds() async throws {
        
        let realmActorRead: RealmActorRead = try await getRealmActorRead()
        
        let getObjectIds: Set<String> = ["1", "4", "0"]
        
        let objects: [MockDataModel] =  try await realmActorRead.getDataModels(readObjectsType: .objectsByIds(ids: getObjectIds, sortByKeyPath: nil))
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
                
        #expect(objectIds == getObjectIds)
    }
    
    @Test()
    func readObjectsByQuery() async throws {
        
        let realmActorRead: RealmActorRead = try await getRealmActorRead()
        
        let isEvenPosition = NSPredicate(format: "\(#keyPath(MockRealmObject.isEvenPosition)) == %@", NSNumber(value: true))
        
        let query = RealmDatabaseQuery(
            filter: isEvenPosition,
            sortByKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false)
        )
        
        let objects: [MockDataModel] =  try await realmActorRead.getDataModels(readObjectsType: .objectsByQuery(query: query))
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [8, 6, 4, 2, 0])
    }
}

extension RealmActorReadTests {
    
    private func getRealmActorRead() async throws -> RealmActorRead<MockDataModel, MockDataModel, MockRealmObject> {
        
        let config: Realm.Configuration = RealmDatabaseConfig.createInMemoryConfig().config
        
        let realmActorWrite = try await RealmActorWrite(
            config: config,
            mapping: MockRealmRepositorySyncMapping()
        )
        
        let objects: [MockDataModel] = allObjectIds.compactMap {
         
            let id: String = $0
            
            guard let position = Int(id) else {
                return nil
            }
            
            return MockDataModel(id: id, name: "name - \(id)", position: position)
        }
        
        _ = try await realmActorWrite.addObjects(
            externalObjects: objects,
            updatePolicy: .modified
        )
        
        let realmActorRead = try await RealmActorRead(
            config: config,
            mapping: MockRealmRepositorySyncMapping()
        )
        
        return realmActorRead
    }
}
