//
//  RealmRepositorySyncPersistenceRead.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift

public final class RealmRepositorySyncPersistenceRead<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableRealmObject> {
    
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.dataModelMapping = dataModelMapping
    }
    
    public func getObjects(realm: Realm, getObjectsType: GetObjectsType, query: RealmDatabaseQuery?) throws -> [DataModelType] {
           
        // TODO: Should an error be thrown if GetObjectsType is other than all and query is provided since query won't apply to object id? ~Levi
        
        let read = RealmDataRead()
        
        let persistObjects: [PersistObjectType]
                
        switch getObjectsType {
            
        case .allObjects:
            persistObjects = read.objects(realm: realm, query: query)
            
        case .object(let id):
            
            let object: PersistObjectType? = read.object(realm: realm, id: id)
            
            if let object = object {
                persistObjects = [object]
            }
            else {
                persistObjects = []
            }
        }
        
        let dataModels: [DataModelType] = persistObjects.compactMap { object in
            self.dataModelMapping.toDataModel(persistObject: object)
        }
        
        return dataModels
    }
}
