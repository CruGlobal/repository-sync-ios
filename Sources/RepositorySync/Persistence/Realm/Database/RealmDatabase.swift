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

public final class RealmDatabase {
            
    public let databaseConfig: RealmDatabaseConfig
    public let read: RealmDataRead = RealmDataRead()
    public let write: RealmDataWrite = RealmDataWrite()
    public let asyncWrite: RealmDataAsyncWrite
        
    public init(databaseConfig: RealmDatabaseConfig) {
        
        self.databaseConfig = databaseConfig
        
        asyncWrite = RealmDataAsyncWrite(config: databaseConfig.config)
    }
    
    public func openRealm() throws -> Realm {
        
        return try Realm(
            configuration: databaseConfig.config
        )
    }
    
    public var openRealmAndRead: RealmDataRealmRead {
        get throws {
            return RealmDataRealmRead(realm: try openRealm())
        }
    }
}
