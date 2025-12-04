//
//  RealmDatabaseConfiguration.swift
//  RepositorySync
//
//  Created by Levi Eggert on 11/14/22.
//  Copyright © 2022 Cru. All rights reserved.
//

import Foundation

public final class RealmDatabaseConfiguration {
    
    public let cacheType: RealmDatabaseCacheType
    public let schemaVersion: UInt64
    
    public init(cacheType: RealmDatabaseCacheType, schemaVersion: UInt64) {
        
        self.cacheType = cacheType
        self.schemaVersion = schemaVersion
    }
}
