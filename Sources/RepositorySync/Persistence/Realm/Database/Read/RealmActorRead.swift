//
//  RealmActorRead.swift
//  RepositorySync
//
//  Created by Levi Eggert on 5/22/26.
//  Copyright © 2026 Cru. All rights reserved.
//

import Foundation
import RealmSwift

public actor RealmActorRead<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableRealmObject> {
    
    private var realm: Realm!
    private let mapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(config: Realm.Configuration, mapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) async throws {
        
        self.mapping = mapping
        
        realm = try await Realm(configuration: config, actor: self)
    }
    
    public func getDataModel(id: String) -> DataModelType? {
        
        let object: PersistObjectType? = RealmDataRead()
            .object(realm: realm, id: id)
        
        guard let object = object else {
            return nil
        }
        
        return mapping.toDataModel(persistObject: object)
    }
    
    public func getDataModels(ids: Set<String>, sortBykeyPath: SortByKeyPath?) -> [DataModelType] {
        
        let objects: [PersistObjectType] = RealmDataRead()
            .objects(realm: realm, ids: ids, sortBykeyPath: sortBykeyPath)
                
        return objects.compactMap {
            mapping.toDataModel(persistObject: $0)
        }
    }
    
    public func getDataModels(query: RealmDatabaseQuery?) -> [DataModelType] {
        
        let objects: [PersistObjectType] = RealmDataRead()
            .objects(realm: realm, query: query)
        
        return objects.compactMap {
            mapping.toDataModel(persistObject: $0)
        }
    }
    
    public func getDataModels(readObjectsType: RealmReadObjectsType) -> [DataModelType] {
        
        let objects: [PersistObjectType] = RealmDataRead()
            .getObjects(realm: realm, readObjectsType: readObjectsType)
        
        return objects.compactMap {
            mapping.toDataModel(persistObject: $0)
        }
    }
}
