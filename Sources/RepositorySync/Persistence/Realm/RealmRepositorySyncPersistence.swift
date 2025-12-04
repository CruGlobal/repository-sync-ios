//
//  RealmRepositorySyncPersistence.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/3/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift
import Combine

open class RealmRepositorySyncPersistence<DataModelType, ExternalObjectType, PersistObjectType: IdentifiableRealmObject>: RepositorySyncPersistence {
    
    public let realmDatabase: RealmDatabase
    public let dataModelMapping: any RepositorySyncMapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    init(realmDatabase: RealmDatabase, dataModelMapping: any RepositorySyncMapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.realmDatabase = realmDatabase
        self.dataModelMapping = dataModelMapping
    }
}

// MARK: - Observe

extension RealmRepositorySyncPersistence {
    
    public func observeCollectionChangesPublisher() -> AnyPublisher<Void, Error> {
        
        do {
            
            let realm: Realm = try realmDatabase.openRealm()
            
            return observeCollectionChangesOnRealmPublisher(
                observeOnRealm: realm
            )
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        }
        catch let error {
            
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
    
    public func observeCollectionChangesOnRealmPublisher(observeOnRealm: Realm) -> AnyPublisher<Void, Never> {
                
        return observeOnRealm
            .objects(PersistObjectType.self)
            .objectWillChange
            .map { _ in
                Void()
            }
            .eraseToAnyPublisher()
    }
}
