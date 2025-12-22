//
//  RealmDataRealmWrite.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift

public final class RealmDataRealmWrite {
    
    public let realm: Realm
    public let write: RealmDataWrite = RealmDataWrite()
    
    public init(realm: Realm) {
        
        self.realm = realm
    }
    
    public func objects(writeClosure: ((_ realm: Realm) -> WriteRealmObjects), updatePolicy: Realm.UpdatePolicy, completion: ((_ realm: Realm) -> Void)? = nil) throws {
        try write.objects(realm: realm, writeClosure: writeClosure, updatePolicy: updatePolicy, completion: completion)
    }
}
