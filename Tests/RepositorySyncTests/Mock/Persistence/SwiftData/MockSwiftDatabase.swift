//
//  MockSwiftDatabase.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData
@testable import RepositorySync

@available(iOS 17.4, *)
public class MockSwiftDatabase {
    
    private let fileManager: FileManager = FileManager.default
    
    public init() {
        
    }
    
    private func getDirectory(directoryName: String) -> URL {
        
        return fileManager.temporaryDirectory
            .appendingPathComponent(directoryName)
    }
    
    private func getFileUrl(directoryName: String) -> URL {
        
        return getDirectory(directoryName: directoryName)
            .appendingPathComponent("swift_tests")
            .appendingPathExtension("sqlite")
    }
    
    public func getSharedDatabase(objects: [MockSwiftObject], shouldDeleteExistingObjects: Bool) throws -> SwiftDatabase {
        
        let database = try createDatabase(directoryName: "shared_swift_database", objects: objects)
        
        let context: ModelContext = database.openContext()
        
        if shouldDeleteExistingObjects {
            
            let existingObjects: [MockSwiftObject] = try database.getObjects(context: context, query: nil)
            
            try database.deleteObjects(context: context, objects: existingObjects)
        }
        
        try database.writeObjects(context: context, objects: objects)
        
        return database
    }
    
    public func createDatabase(directoryName: String, objects: [MockSwiftObject]) throws -> SwiftDatabase {
        
        try _ = fileManager.createDirectoryIfNotExists(directoryUrl: getDirectory(directoryName: directoryName))
        
        let url: URL = getFileUrl(directoryName: directoryName)
        
        let config = ModelConfiguration(
            "swift_tests",
            schema: nil,
            url: url,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        
        let database = try SwiftDatabase(
            modelConfiguration: config,
            schema: Schema(versionedSchema: MockSwiftDatabaseSchema.self),
            migrationPlan: nil
        )
             
        return database
    }
    
    public func deleteDatabase(directoryName: String) throws {
        
        try fileManager.removeUrl(url: getDirectory(directoryName: directoryName))
    }
}
