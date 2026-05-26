//
//  RealmDatabaseConfig.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

public final class RealmDatabaseConfig: Sendable {
    
    public let config: Realm.Configuration
    
    public init(config: Realm.Configuration) throws {
        
        self.config = config
        
        try checkForUnsupportedFileFormatVersionAndDeleteRealmFilesIfNeeded(config: config)
    }
    
    public var isInMemory: Bool {
        return config.isInMemory
    }
    
    public func openRealm() throws -> Realm {
        
        return try Realm(configuration: config)
    }
    
    public static func createInMemoryConfig(inMemoryIdentifier: String = UUID().uuidString, schemaVersion: UInt64 = 1) throws -> RealmDatabaseConfig {
        
        let config = Realm.Configuration(
            inMemoryIdentifier: inMemoryIdentifier,
            schemaVersion: schemaVersion
        )
        
        return try RealmDatabaseConfig(config: config)
    }
    
    public convenience init(fileName: String, schemaVersion: UInt64, migrationBlock: @escaping MigrationBlock, objectTypes: [ObjectBase.Type]? = nil) throws {
        
        let fileUrl = URL(fileURLWithPath: RLMRealmPathForFile(fileName), isDirectory: false)
        
        let config = Realm.Configuration(
            fileURL: fileUrl,
            schemaVersion: schemaVersion,
            migrationBlock: migrationBlock,
            objectTypes: objectTypes
        )
        
        try self.init(config: config)
    }
    
    public convenience init(fileUrl: URL, schemaVersion: UInt64, migrationBlock: @escaping MigrationBlock, objectTypes: [ObjectBase.Type]? = nil) throws {
                
        let config = Realm.Configuration(
            fileURL: fileUrl,
            schemaVersion: schemaVersion,
            migrationBlock: migrationBlock,
            objectTypes: objectTypes
        )
        
        try self.init(config: config)
    }
    
    private func checkForUnsupportedFileFormatVersionAndDeleteRealmFilesIfNeeded(config: Realm.Configuration) throws {
        
        do {
            _ = try Realm(configuration: config)
        }
        catch let error {
            
            let errorCode: Int = (error as NSError).code
            
            guard errorCode == Realm.Error.unsupportedFileFormatVersion.rawValue else {
                throw error
            }
            
            _ = try Realm.deleteFiles(for: config)
        }
    }
}
