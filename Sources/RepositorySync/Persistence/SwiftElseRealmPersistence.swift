//
//  SwiftElseRealmPersistence.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

// TODO: This class can be removed once RealmSwift is removed in place of SwiftData for iOS 17.4 minimum and up. ~Levi
@MainActor open class SwiftElseRealmPersistence<DataModelType, ExternalObjectType, RealmObjectType: IdentifiableRealmObject> {
    
    public let realmDatabase: RealmDatabase
    public let realmDataModelMapping: any Mapping<DataModelType, ExternalObjectType, RealmObjectType>
    
    public init(realmDatabase: RealmDatabase, realmDataModelMapping: any Mapping<DataModelType, ExternalObjectType, RealmObjectType>) {
        
        self.realmDatabase = realmDatabase
        self.realmDataModelMapping = realmDataModelMapping
    }
    
    func getPersistence() -> any Persistence<DataModelType, ExternalObjectType> {
        
        if #available(iOS 17.4, *),
           let swiftDatabase = getSwiftDatabase(),
           let swiftPersistence = getAnySwiftPersistence(swiftDatabase: swiftDatabase) {
            
            return swiftPersistence
        }
        else {
            
            return RealmRepositorySyncPersistence<DataModelType, ExternalObjectType, RealmObjectType>(
                database: realmDatabase,
                dataModelMapping: realmDataModelMapping
            )
        }
    }

    @available(iOS 17.4, *)
    func getSwiftDatabase() -> SwiftDatabase? {
        return GlobalSwiftDatabase.shared.swiftDatabase
    }
    
    @available(iOS 17.4, *)
    func getAnySwiftPersistence(swiftDatabase: SwiftDatabase) -> (any Persistence<DataModelType, ExternalObjectType>)? {
        // NOTE: Subclasses should override and return a SwiftRepositorySyncPersistence. ~Levi
        return nil
    }
    
    func getRealmPersistence() -> RealmRepositorySyncPersistence<DataModelType, ExternalObjectType, RealmObjectType> {
        
        return RealmRepositorySyncPersistence<DataModelType, ExternalObjectType, RealmObjectType>(
            database: realmDatabase,
            dataModelMapping: realmDataModelMapping
        )
    }
}
