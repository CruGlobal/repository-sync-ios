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
    
    public init(config: Realm.Configuration) {
        
        self.config = config
        
        _ = checkForUnsupportedFileFormatVersionAndDeleteRealmFilesIfNeeded(config: config)
    }
    
    public var isInMemory: Bool {
        return config.isInMemory
    }
    
    public static func createInMemoryConfig(inMemoryIdentifier: String = UUID().uuidString, schemaVersion: UInt64 = 1) -> RealmDatabaseConfig {
        
        let config = Realm.Configuration(
            inMemoryIdentifier: inMemoryIdentifier,
            schemaVersion: schemaVersion
        )
        
        return RealmDatabaseConfig(config: config)
    }
    
    public convenience init(fileName: String, schemaVersion: UInt64, migrationBlock: @escaping MigrationBlock) {
        
        let fileUrl = URL(fileURLWithPath: RLMRealmPathForFile(fileName), isDirectory: false)
        
        let config = Realm.Configuration(
            fileURL: fileUrl,
            schemaVersion: schemaVersion,
            migrationBlock: migrationBlock
        )
        
        self.init(config: config)
    }
    
    public convenience init(fileUrl: URL, schemaVersion: UInt64, migrationBlock: @escaping MigrationBlock) {
                
        let config = Realm.Configuration(
            fileURL: fileUrl,
            schemaVersion: schemaVersion,
            migrationBlock: migrationBlock
        )
        
        self.init(config: config)
    }
    
    private func checkForUnsupportedFileFormatVersionAndDeleteRealmFilesIfNeeded(config: Realm.Configuration) -> Error? {
        
        do {
            _ = try Realm(configuration: config)
        }
        catch let realmConfigError as NSError {
            
            if realmConfigError.code == Realm.Error.unsupportedFileFormatVersion.rawValue {
                
                do {
                    _ = try Realm.deleteFiles(for: config)
                }
                catch let deleteFilesError {
                    return deleteFilesError
                }
            }
            else {
                return realmConfigError
            }
        }
        
        return nil
    }
}
