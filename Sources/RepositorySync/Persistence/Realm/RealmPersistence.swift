//
//  RealmPersistence.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/3/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift
import Combine

public final class RealmPersistence<DataModelType, ExternalObjectType, PersistObjectType: IdentifiableRealmObject>: RepositorySyncPersistence {
    
    private let dataModelMapping: any RepositorySyncMapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    let realmDatabase: RealmDatabase
    
    init(realmDatabase: RealmDatabase, dataModelMapping: any RepositorySyncMapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.realmDatabase = realmDatabase
        self.dataModelMapping = dataModelMapping
    }
}

// MARK: - Observe

extension RealmPersistence {
    
    public func observeCollectionChangesPublisher() -> AnyPublisher<Void, Never> {
        
        return observeRealmCollectionChangesPublisher(
            observeOnRealm: realmDatabase.openRealm()
        )
    }
    
    private func observeRealmCollectionChangesPublisher(observeOnRealm: Realm) -> AnyPublisher<Void, Never> {
                
        return observeOnRealm
            .objects(PersistObjectType.self)
            .objectWillChange
            .map { _ in
                Void()
            }
            .eraseToAnyPublisher()
    }
}
