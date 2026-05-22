//
//  RealmActorWrite.swift
//  RepositorySync
//
//  Created by Levi Eggert on 5/22/26.
//  Copyright © 2026 Cru. All rights reserved.
//

import Foundation
import RealmSwift

public actor RealmActorWrite<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableRealmObject> {
    
    private var realm: Realm!
    
    public let mapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(config: Realm.Configuration, mapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) async throws {
        
        self.mapping = mapping
        
        realm = try await Realm(configuration: config, actor: self)
    }
    
    private func readObjects(readObjectsType: RealmReadObjectsType?) throws -> [DataModelType] {
        
        guard let readObjectsType = readObjectsType else {
            return Array()
        }
        
        let objects: [PersistObjectType] = try RealmDataRead()
            .getObjects(realm: realm, readObjectsType: readObjectsType)
        
        return objects.compactMap {
            mapping.toDataModel(persistObject: $0)
        }
    }
    
    public func addObjects(externalObjects: [ExternalObjectType], updatePolicy: Realm.UpdatePolicy, readObjectsType: RealmReadObjectsType? = nil) async throws -> [DataModelType] {
        
        guard !externalObjects.isEmpty else {
            return try readObjects(readObjectsType: readObjectsType)
        }
        
        let objects: [PersistObjectType] = externalObjects.compactMap {
            mapping.toPersistObject(externalObject: $0)
        }
        
        try await realm.asyncWrite {
            realm.add(objects, update: updatePolicy)
        }
        
        return try readObjects(readObjectsType: readObjectsType)
    }
    
    public func deleteObjectsByIds(ids: Set<String>, readObjectsType: RealmReadObjectsType? = nil) async throws -> [DataModelType] {
        
        guard !ids.isEmpty else {
            return try readObjects(readObjectsType: readObjectsType)
        }
        
        let objects: [PersistObjectType] = try RealmDataRead()
            .getObjects(realm: realm, readObjectsType: .objectsByIds(ids: ids, sortByKeyPath: nil))
        
        try await realm.asyncWrite {
            realm.delete(objects)
        }
        
        return try readObjects(readObjectsType: readObjectsType)
    }
    
    public func writeObjects(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, readObjectsType: RealmReadObjectsType? = nil) async throws -> [DataModelType] {
     
        var objectIdsToDelete: Set<String> = Set()
        
        if let writeOption = writeOption {
            
            switch writeOption {
            case .deleteObjectsNotInExternal:
                objectIdsToDelete = getAllObjectIds()
            }
        }
        
        var objectsToInsert: [PersistObjectType] = Array()
        
        for externalObject in externalObjects {
            
            guard let dataModel = mapping.toPersistObject(externalObject: externalObject) else {
                continue
            }
            
            objectIdsToDelete.remove(dataModel.id)
            
            objectsToInsert.append(dataModel)
        }
        
        
        if !objectIdsToDelete.isEmpty {
            
            let objectsToDelete: [PersistObjectType] = RealmDataRead()
                .objects(realm: realm, ids: objectIdsToDelete, sortBykeyPath: nil)
            
            try await realm.asyncWrite {
                realm.delete(objectsToDelete)
            }
        }
        
        if !objectsToInsert.isEmpty {
            try await realm.asyncWrite {
                realm.add(objectsToInsert, update: .modified)
            }
        }
        
        return try readObjects(readObjectsType: readObjectsType)
    }
    
    private func getAllObjectIds() -> Set<String> {
        
        let objects: [PersistObjectType] = RealmDataRead().objects(realm: realm, query: nil)
        
        return Set(objects.map {
            $0.id
        })
    }
}
