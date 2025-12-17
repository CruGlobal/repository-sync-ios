//
//  SwiftElseRealmPersistence.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftData

// TODO: This class can be removed once RealmSwift is removed in place of SwiftData for iOS 17.4 minimum and up. ~Levi
@MainActor open class SwiftElseRealmPersistence<DataModelType: Sendable, ExternalObjectType: Sendable, RealmObjectType: IdentifiableRealmObject> {
    
    public let realmPersistence: RealmRepositorySyncPersistence<DataModelType, ExternalObjectType, RealmObjectType>
    
    public init(realmPersistence: RealmRepositorySyncPersistence<DataModelType, ExternalObjectType, RealmObjectType>) {
        
        self.realmPersistence = realmPersistence
    }
    
    public func getPersistence() -> any Persistence<DataModelType, ExternalObjectType> {
        
        if #available(iOS 17.4, *),
           let swiftDatabase = getSwiftDatabase(),
           let swiftPersistence = getSwiftPersistence(swiftDatabase: swiftDatabase) {
            
            return swiftPersistence
        }
        else {
            
            return realmPersistence
        }
    }

    @available(iOS 17.4, *)
    public func getSwiftDatabase() -> SwiftDatabase? {
        return GlobalSwiftDatabase.shared.swiftDatabase
    }
    
    @available(iOS 17.4, *)
    public func getSwiftPersistence(swiftDatabase: SwiftDatabase) -> (any Persistence<DataModelType, ExternalObjectType>)? {
        // NOTE: Subclasses should override and return a SwiftRepositorySyncPersistence. ~Levi
        return nil
    }
}
