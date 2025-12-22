//
//  RealmDataWrite.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift

public final class RealmDataWrite: Sendable {
    
    public func objects(realm: Realm, writeClosure: ((_ realm: Realm) -> WriteRealmObjects), updatePolicy: Realm.UpdatePolicy, completion: ((_ realm: Realm) -> Void)? = nil) throws {
        
        try realm.write {
            
            let writeRealmObjects: WriteRealmObjects = writeClosure(realm)
             
            if let objectsToDelete = writeRealmObjects.deleteObjects, objectsToDelete.count > 0 {
                realm.delete(objectsToDelete)
            }
            
            if let objectsToAdd = writeRealmObjects.addObjects, objectsToAdd.count > 0 {
                realm.add(objectsToAdd, update: updatePolicy)
            }
            
            completion?(realm)
        }
    }
}
