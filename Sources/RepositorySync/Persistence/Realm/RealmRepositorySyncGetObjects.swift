//
//  RealmRepositorySyncGetObjects.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift

public final class RealmRepositorySyncGetObjects<PersistObjectType: IdentifiableRealmObject> {
    
    public init() {
        
    }
    
    public func getObjects(realm: Realm, getOption: PersistenceGetOption, query: RealmDatabaseQuery?) throws -> [PersistObjectType] {
        
        let read = RealmDataRead()
        
        let persistObjects: [PersistObjectType]
                
        switch getOption {
            
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
            
        case .objectsByIds(let ids):
            persistObjects = read.objects(realm: realm, ids: ids, sortBykeyPath: nil)
        }
        
        return persistObjects
    }
}
