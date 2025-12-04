//
//  RealmDatabaseConfiguration+RealmConfig.swift
//  RepositorySync
//
//  Created by Levi Eggert on 11/14/22.
//  Copyright © 2022 Cru. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

extension RealmDatabaseConfiguration {
    
    public func toRealmConfig() -> Realm.Configuration {
        
        var realmConfig: Realm.Configuration
        
        switch cacheType {
            
        case .disk(let fileLocation, let migrationBlock):
            
            let fileUrl: URL
            
            switch fileLocation {
            case .fileName( let name):
                fileUrl = URL(fileURLWithPath: RLMRealmPathForFile(name), isDirectory: false)
            case .fileUrl(let url):
                fileUrl = url
            }
            
            realmConfig = Realm.Configuration(
                fileURL: fileUrl,
                schemaVersion: schemaVersion,
                migrationBlock: migrationBlock
            )
        
        case .inMemory(let identifier):
            
            realmConfig = Realm.Configuration(
                inMemoryIdentifier: identifier,
                schemaVersion: schemaVersion
            )
        }
        
        return realmConfig
    }
}
