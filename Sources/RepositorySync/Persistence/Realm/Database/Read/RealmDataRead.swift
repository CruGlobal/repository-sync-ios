//
//  RealmDataRead.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import  RealmSwift

public final class RealmDataRead: Sendable {
    
    public init() {
        
    }
    
    public func object<T: IdentifiableRealmObject>(realm: Realm, id: String) -> T? {
        
        let realmObject: T? = realm.object(ofType: T.self, forPrimaryKey: id)

        return realmObject
    }
    
    public func objects<T: IdentifiableRealmObject>(realm: Realm, ids: Set<String>, sortBykeyPath: SortByKeyPath?) -> [T] {
                
        let query = RealmDatabaseQuery(
            filter: NSPredicate(format: "id IN %@", ids),
            sortByKeyPath: sortBykeyPath
        )
        
        return objects(realm: realm, query: query)
    }
    
    public func objects<T: IdentifiableRealmObject>(realm: Realm, query: RealmDatabaseQuery?) -> [T] {
        
        return Array(results(realm: realm, query: query))
    }
    
    public func results<T: IdentifiableRealmObject>(realm: Realm, query: RealmDatabaseQuery?) -> Results<T> {
        
        let results = realm.objects(T.self)
        
        if let filter = query?.filter, let sortByKeyPath = query?.sortByKeyPath {
            
            return results
                .filter(filter)
                .sorted(byKeyPath: sortByKeyPath.keyPath, ascending: sortByKeyPath.ascending)
        }
        else if let filter = query?.filter {
           
            return results
                .filter(filter)
        }
        else if let sortByKeyPath = query?.sortByKeyPath {
            return results
                .sorted(byKeyPath: sortByKeyPath.keyPath, ascending: sortByKeyPath.ascending)
        }
        
        return results
    }
    
    public func getObjects<T: IdentifiableRealmObject>(realm: Realm, readObjectsType: RealmReadObjectsType) -> [T] {
                
        let persistObjects: [T]
                
        switch readObjectsType {
            
        case .allObjects:
            persistObjects = objects(realm: realm, query: nil)
            
        case .object(let id):
            
            let object: T? = object(realm: realm, id: id)
            
            if let object = object {
                persistObjects = [object]
            }
            else {
                persistObjects = []
            }
            
        case .objectsByIds(let ids, let sortByKeyPath):
            persistObjects = objects(realm: realm, ids: ids, sortBykeyPath: sortByKeyPath)
            
        case .objectsByQuery(let query):
            persistObjects = objects(realm: realm, query: query)
        }
        
        return persistObjects
    }
}
