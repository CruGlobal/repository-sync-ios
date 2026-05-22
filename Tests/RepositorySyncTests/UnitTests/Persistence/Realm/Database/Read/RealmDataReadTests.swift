//
//  RealmDataReadTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 5/22/26.
//  Copyright © 2026 Cru. All rights reserved.
//

import Foundation
import Testing
@testable import RepositorySync
import RealmSwift

struct RealmDataReadTests {
    
    private let allObjectIds: Set<String> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    @Test()
    func getObjectById() throws {
                
        let realm: Realm = try getRealm()
        
        let objectId: String = "0"
                
        let object: MockRealmObject = try #require(RealmDataRead().object(realm: realm, id: objectId))
                
        #expect(object.id == objectId)
    }
    
    @Test()
    func getObjectsByIds() throws {
                
        let realm: Realm = try getRealm()
                        
        let getObjectIds: Set<String> = ["2", "4", "6"]
        
        let objects: [MockRealmObject] = RealmDataRead().objects(
            realm: realm,
            ids: getObjectIds,
            sortBykeyPath: nil
        )
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
                
        #expect(objectIds == getObjectIds)
    }
    
    @Test()
    func getObjectsByIdsAscendingFalse() throws {
                
        let realm: Realm = try getRealm()
                        
        let getObjectIds: Set<String> = ["6", "4", "2"]
        
        let objects: [MockRealmObject] = RealmDataRead().objects(
            realm: realm,
            ids: getObjectIds,
            sortBykeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false)
        )
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
                
        #expect(objectIds == getObjectIds)
    }
    
    @Test()
    func getObjectByFilter() throws {
                
        let realm: Realm = try getRealm()
                
        let predicate = NSPredicate(format: "\(#keyPath(MockRealmObject.position)) == %@", NSNumber(value: 0))
        
        let query = RealmDatabaseQuery.filter(filter: predicate)
        
        let objects: [MockRealmObject] = RealmDataRead().objects(realm: realm, query: query)
        
        let object: MockRealmObject = try #require(objects.first)
                
        #expect(object.id == "0")
    }
    
    @Test()
    func getObjectsBySortAscendingTrue() throws {
                
        let realm: Realm = try getRealm()
                        
        let query = RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: true))
        
        let objects: [MockRealmObject] = Array(RealmDataRead().results(realm: realm, query: query))
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    }
    
    @Test()
    func getObjectsBySortAscendingFalse() throws {
                
        let realm: Realm = try getRealm()
                        
        let query = RealmDatabaseQuery.sort(byKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false))
        
        let objects: [MockRealmObject] = RealmDataRead().objects(realm: realm, query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
    }
    
    @Test()
    func getObjectByFilterAndSort() throws {
                
        let realm: Realm = try getRealm()
                
        let isEvenPosition = NSPredicate(format: "\(#keyPath(MockRealmObject.isEvenPosition)) == %@", NSNumber(value: true))
        
        let query = RealmDatabaseQuery(
            filter: isEvenPosition,
            sortByKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false)
        )
        
        let objects: [MockRealmObject] = RealmDataRead().objects(realm: realm, query: query)
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [8, 6, 4, 2, 0])
    }
    
    @Test()
    func readAllObjects() throws {
        
        let realm: Realm = try getRealm()
        
        let objects: [MockRealmObject] =  try RealmDataRead().getObjects(realm: realm, readObjectsType: .allObjects)
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
        
        #expect(objectIds == allObjectIds)
    }
    
    @Test()
    func readObjectById() throws {
        
        let realm: Realm = try getRealm()
        
        let objectId: String = "0"
        
        let objects: [MockRealmObject] =  try RealmDataRead().getObjects(realm: realm, readObjectsType: .object(id: objectId))
        
        let object: MockRealmObject = try #require(objects.first)
        
        #expect(object.id == objectId)
    }
    
    @Test()
    func readObjectByIdIsEmptyWhenObjectDoesntExist() throws {
        
        let realm: Realm = try getRealm()
        
        let objectId: String = UUID().uuidString
        
        let objects: [MockRealmObject] =  try RealmDataRead().getObjects(realm: realm, readObjectsType: .object(id: objectId))
                
        #expect(objects.count == 0)
    }
    
    @Test()
    func readObjectsByIds() throws {
        
        let realm: Realm = try getRealm()
        
        let getObjectIds: Set<String> = ["1", "4", "0"]
        
        let objects: [MockRealmObject] =  try RealmDataRead().getObjects(realm: realm, readObjectsType: .objectsByIds(ids: getObjectIds, sortByKeyPath: nil))
        
        let objectIds: Set<String> = Set(objects.map { $0.id })
                
        #expect(objectIds == getObjectIds)
    }
    
    @Test()
    func readObjectsByQuery() throws {
        
        let realm: Realm = try getRealm()
        
        let isEvenPosition = NSPredicate(format: "\(#keyPath(MockRealmObject.isEvenPosition)) == %@", NSNumber(value: true))
        
        let query = RealmDatabaseQuery(
            filter: isEvenPosition,
            sortByKeyPath: SortByKeyPath(keyPath: #keyPath(MockRealmObject.position), ascending: false)
        )
        
        let objects: [MockRealmObject] =  try RealmDataRead().getObjects(realm: realm, readObjectsType: .objectsByQuery(query: query))
        
        let objectPositions: [Int] = objects.map { $0.position }
                
        #expect(objectPositions == [8, 6, 4, 2, 0])
    }
}

extension RealmDataReadTests {
    
    private func getRealm() throws -> Realm {
        
        let config: Realm.Configuration = RealmDatabaseConfig.createInMemoryConfig().config
        
        let realm = try Realm(
            configuration: config
        )
        
        var objects: [MockRealmObject] = Array()
        
        for id in allObjectIds {
            
            guard let position = Int(id) else {
                continue
            }
            
            objects.append(
                MockRealmObject.createFrom(model: MockDataModel(id: id, name: "name - \(id)", position: position))
            )
        }
        
        try realm.write {
            realm.add(objects, update: .all)
        }
        
        return realm
    }
}
