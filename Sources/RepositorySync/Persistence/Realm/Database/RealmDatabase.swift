//
//  RealmDatabase.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

public final class RealmDatabase: Sendable {
                
    public let databaseConfig: RealmDatabaseConfig
    
    public var config: Realm.Configuration {
        return databaseConfig.config
    }

    public init(databaseConfig: RealmDatabaseConfig) {
        
        self.databaseConfig = databaseConfig
    }
    
    public func openRealm() throws -> Realm {
        
        return try Realm(
            configuration: databaseConfig.config
        )
    }
}
