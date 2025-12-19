//
//  InMemoryRealmDatabase.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/22/23.
//  Copyright © 2023 Cru. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

@MainActor open class InMemoryRealmDatabase: RealmDatabase {
    
    public let mainRealm: Realm
    
    public init(inMemoryId: String = UUID().uuidString) throws {
        
        let config = Realm.Configuration(inMemoryIdentifier: inMemoryId)
        
        let databaseConfig = RealmDatabaseConfig(config: config)
        
        do {
            try mainRealm = Realm(configuration: config)
        }
        
        super.init(databaseConfig: databaseConfig)
    }
}
