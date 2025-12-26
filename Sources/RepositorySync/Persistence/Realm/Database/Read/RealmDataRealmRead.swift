//
//  RealmDataRealmRead.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import  RealmSwift

public final class RealmDataRealmRead {
    
    public let realm: Realm
    public let read: RealmDataRead = RealmDataRead()
    
    public init(realm: Realm) {
        
        self.realm = realm
    }
    
    public func object<T: IdentifiableRealmObject>(id: String) -> T? {
        return read.object(realm: realm, id: id)
    }
    
    public func objects<T: IdentifiableRealmObject>(ids: [String], sortBykeyPath: SortByKeyPath?) -> [T] {
        return read.objects(realm: realm, ids: ids, sortBykeyPath: sortBykeyPath)
    }
    
    public func objects<T: IdentifiableRealmObject>(query: RealmDatabaseQuery?) -> [T] {
        return read.objects(realm: realm, query: query)
    }
    
    public func results<T: IdentifiableRealmObject>(query: RealmDatabaseQuery?) -> Results<T> {
        return read.results(realm: realm, query: query)
    }
}
