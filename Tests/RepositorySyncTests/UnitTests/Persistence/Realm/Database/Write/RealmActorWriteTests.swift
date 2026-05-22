//
//  RealmActorWriteTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 5/22/26.
//  Copyright © 2026 Cru. All rights reserved.
//

import Foundation
import Testing
@testable import RepositorySync
import RealmSwift

struct RealmActorWriteTests {
    
    private let allObjectIds: Set<String> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    @Test()
    func addObjects() async throws {
        
        let realmActorWrite: RealmActorWrite = try await getRealmActorWrite()
                                
        let addObjectId: String = UUID().uuidString
        
        let objectToAdd = MockDataModel(id: addObjectId, name: "name", position: 0)
        
        let objects: [MockDataModel] = try await realmActorWrite.addObjects(
            externalObjects: [objectToAdd],
            updatePolicy: .modified,
            readObjectsType: .object(id: addObjectId)
        )
        
        let objectById: MockDataModel = try #require(objects.first)
                
        #expect(objectById.id == addObjectId)
    }
    
    @Test()
    func updateObjects() async throws {
        
        let realmActorWrite: RealmActorWrite = try await getRealmActorWrite()
        
        let objectIdToUpdate: String = "3"
        let name: String = "Updated Object 3"
        let position: Int = 9999999
        
        let updateObject = MockDataModel(id: objectIdToUpdate, name: name, position: position)
                
        let objects: [MockDataModel] = try await realmActorWrite.addObjects(
            externalObjects: [updateObject],
            updatePolicy: .modified,
            readObjectsType: .object(id: objectIdToUpdate)
        )
        
        let objectById: MockDataModel = try #require(objects.first)
                
        #expect(objectById.id == objectIdToUpdate)
        #expect(objectById.name == name)
        #expect(objectById.position == position)
    }
    
    @Test()
    func deleteObjects() async throws {
        
        let realmActorWrite: RealmActorWrite = try await getRealmActorWrite()
                        
        let objects: [MockDataModel] = try await realmActorWrite.deleteObjectsByIds(
            ids: allObjectIds,
            readObjectsType: .allObjects
        )
                     
        #expect(objects.count == 0)
    }
}

extension RealmActorWriteTests {
    
    private func getRealmActorWrite() async throws -> RealmActorWrite<MockDataModel, MockDataModel, MockRealmObject> {
        
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
        
        return realmActorWrite
    }
}
