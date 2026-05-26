//
//  RealmDatabaseConfigTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 5/22/26.
//  Copyright © 2026 Cru. All rights reserved.
//

import Foundation
import Testing
@testable import RepositorySync
import RealmSwift

struct RealmDatabaseConfigTests {
    
    @Test()
    func createsInMemoryConfig() throws {
        
        let config = try RealmDatabaseConfig.createInMemoryConfig()
        
        #expect(config.isInMemory == true)
    }
    
    @Test()
    func createsConfigWithFilename() throws {
        
        let databaseConfig = try RealmDatabaseConfig(
            fileName: "realm_test_file_name",
            schemaVersion: 1,
            migrationBlock: { (migration: Migration, oldSchemaVersion: UInt64) in
                
            },
            objectTypes: nil
        )
        
        #expect(databaseConfig.isInMemory == false)
        
        let fileUrl: URL = try #require(databaseConfig.config.fileURL)
        
        let fileManager = FileManager.default
        
        #expect(fileManager.getFilePathExists(url: fileUrl) == true)
        
        try fileManager.removeUrl(url: fileUrl)
        
        #expect(fileManager.getFilePathExists(url: fileUrl) == false)
    }
    
    @Test()
    func createsConfigWithFileUrl() throws {
        
        let fileManager = FileManager.default
        
        let directoryName: String = "realm_files_directory"
        
        let directoryUrl: URL = try fileManager.createDirectoryIfNotExists(
            directoryUrl: fileManager.temporaryDirectory.appending(
                path: directoryName,
                directoryHint: URL.DirectoryHint.isDirectory
            )
        )
        
        let realmFileUrl: URL = directoryUrl.appending(path: "realm_tests_file", directoryHint: URL.DirectoryHint.notDirectory).appendingPathExtension("realm")
                
        let databaseConfig = try RealmDatabaseConfig(
            fileUrl: realmFileUrl,
            schemaVersion: 1,
            migrationBlock: { (migration: Migration, oldSchemaVersion: UInt64) in
                
            },
            objectTypes: nil
        )
        
        #expect(databaseConfig.isInMemory == false)
        
        let fileUrl: URL = try #require(databaseConfig.config.fileURL)
        
        #expect(fileManager.getFilePathExists(url: fileUrl) == true)
        
        try fileManager.removeUrl(url: fileUrl)
        
        #expect(fileManager.getFilePathExists(url: fileUrl) == false)
    }
}
