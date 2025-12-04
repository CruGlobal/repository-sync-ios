//
//  FileManagerTests.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/04/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Testing

struct FileManagerTests {
        
    @Test()
    func directoryIsCreatedIfNotExists() async throws {
        
        let directoryName: String = UUID().uuidString
        
        let fileManager: FileManager = FileManager.default
        
        let directoryUrl: URL = fileManager.temporaryDirectory
            .appendingPathComponent(directoryName)
        
        #expect(!fileManager.getDirectoryExists(directoryUrl: directoryUrl))
        
        try _ =  fileManager.createDirectoryIfNotExists(directoryUrl: directoryUrl)
        
        #expect(fileManager.getDirectoryExists(directoryUrl: directoryUrl))
    }
    
    @Test()
    func directoryIsDeleted() async throws {
        
        let directoryName: String = UUID().uuidString
        
        let fileManager: FileManager = FileManager.default
        
        let directoryUrl: URL = fileManager.temporaryDirectory
            .appendingPathComponent(directoryName)
        
        try _ =  fileManager.createDirectoryIfNotExists(directoryUrl: directoryUrl)
        
        #expect(fileManager.getDirectoryExists(directoryUrl: directoryUrl))
        
        try fileManager.removeUrl(url: directoryUrl)
        
        #expect(!fileManager.getDirectoryExists(directoryUrl: directoryUrl))
    }
}
