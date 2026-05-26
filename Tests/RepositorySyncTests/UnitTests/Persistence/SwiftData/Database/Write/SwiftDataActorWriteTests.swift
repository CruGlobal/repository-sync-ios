//
//  SwiftDataActorWriteTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 5/22/26.
//  Copyright © 2026 Cru. All rights reserved.
//

import Foundation
import Testing
@testable import RepositorySync
import SwiftData

struct SwiftDataActorWriteTests {
    
    private let allObjectIds: Set<String> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    @available(iOS 17.4, *)
    @Test()
    func addObjects() async throws {
        
        let actorWrite: SwiftDataActorWrite = try getSwiftDataActorWrite()
                                
        let addObjectId: String = UUID().uuidString
        
        let objectToAdd = MockDataModel(id: addObjectId, name: "name", position: 0)
        
        let objects: [MockDataModel] = try await actorWrite.addObjects(
            externalObjects: [objectToAdd],
            readObjectsType: .object(id: addObjectId)
        )
        
        let objectById: MockDataModel = try #require(objects.first)
                
        #expect(objectById.id == addObjectId)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func updateObjects() async throws {
        
        let actorWrite: SwiftDataActorWrite = try getSwiftDataActorWrite()
        
        let objectIdToUpdate: String = "3"
        let name: String = "Updated Object 3"
        let position: Int = 9999999
        
        let updateObject = MockDataModel(id: objectIdToUpdate, name: name, position: position)
                
        let objects: [MockDataModel] = try await actorWrite.addObjects(
            externalObjects: [updateObject],
            readObjectsType: .object(id: objectIdToUpdate)
        )
        
        let objectById: MockDataModel = try #require(objects.first)
                
        #expect(objectById.id == objectIdToUpdate)
        #expect(objectById.name == name)
        #expect(objectById.position == position)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func deleteObjectsByIds() async throws {
        
        let actorWrite: SwiftDataActorWrite = try getSwiftDataActorWrite()
                        
        let objects: [MockDataModel] = try await actorWrite.deleteObjectsByIds(
            ids: allObjectIds,
            readObjectsType: .allObjects
        )
                     
        #expect(objects.count == 0)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func deleteCollection() async throws {
        
        let actorWrite: SwiftDataActorWrite = try getSwiftDataActorWrite()
                        
        let objects: [MockDataModel] = try await actorWrite.deleteCollection(
            readObjectsType: .allObjects
        )
                     
        #expect(objects.count == 0)
    }
    
    @available(iOS 17.4, *)
    @Test()
    func writeObjectsDeletesNonExistingFromExternalObjects() async throws {
        
        let actorWrite: SwiftDataActorWrite = try getSwiftDataActorWrite()
        
        let externalObjectIds: Set<String> = ["1", "2", "25", "26", "27", "28", "29"]
        
        let externalObjects: [MockDataModel] = externalObjectIds.compactMap {
            guard let position = Int($0) else {
                return nil
            }
            return MockDataModel(id: $0, name: "name - \($0)", position: position)
        }
        
        let objects: [MockDataModel] = try await actorWrite.writeObjects(
            externalObjects: externalObjects,
            writeOption: .deleteObjectsNotInExternal,
            readObjectsType: .allObjects
        )
        
        let objectIds: Set<String> = Set(objects.map {
            $0.id
        })
        
        #expect(objectIds == externalObjectIds)
    }
}

extension SwiftDataActorWriteTests {
    
    @available(iOS 17.4, *)
    private func getSwiftDataActorWrite() throws -> SwiftDataActorWrite<MockDataModel, MockDataModel, MockSwiftObject> {
        
        let schema = Schema(versionedSchema: MockSwiftDatabaseSchema.self)
        let container = try SwiftDataContainer.createInMemoryContainer(schema: schema)
        let database = SwiftDatabase(container: container)
        
        let context: ModelContext = database.openContext()
        
        for id in allObjectIds {
            
            guard let position = Int(id) else {
                continue
            }
            
            let object = MockSwiftObject.createFrom(model: MockDataModel(id: id, name: "name - \(id)", position: position))
            
            context.insert(object)
        }
        
        try context.save()
 
        return SwiftDataActorWrite(
            container: container.modelContainer,
            mapping: MockSwiftRepositorySyncMapping()
        )
    }
}
