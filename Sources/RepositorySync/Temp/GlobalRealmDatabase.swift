//
//  GlobalRealmDatabase.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/29/25.
//

import Foundation

// TODO: This singleton can be removed once RealmSwift is dropped.
//  Clients should enable realm database by injecting here in enableRealmDatabase method. ~Levi
@MainActor class GlobalRealmDatabase {
        
    static let shared: GlobalRealmDatabase = GlobalRealmDatabase()
    
    private(set) var realmDatabase: RealmDatabase = RealmDatabase(databaseConfig: RealmDatabaseConfig.createInMemoryConfig())
    
    private init() {
        
    }
    
    func enableRealmDatabase(realmDatabase: RealmDatabase) {
        self.realmDatabase = realmDatabase
    }
}
