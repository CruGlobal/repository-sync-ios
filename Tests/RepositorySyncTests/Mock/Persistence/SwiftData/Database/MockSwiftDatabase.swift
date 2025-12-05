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
    private let defaultIds: [Int] = [0, 1, 2, 3, 4]
    
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
    
    public func createDatabase(directoryName: String, ids: [Int]? = nil) throws -> SwiftDatabase {
        
        let idsToCreate: [Int] = ids ?? defaultIds
        
        var objects: [MockSwiftObject] = Array()
        
        for id in idsToCreate {
            
            objects.append(
                MockSwiftObject.createObject(
                    id: String(id),
                    position: id
                )
            )
        }
        
        return try createDatabase(directoryName: directoryName, objects: objects)
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
        
        let database = SwiftDatabase(
            modelConfiguration: config,
            schema: Schema(versionedSchema: MockSwiftDatabaseSchema.self),
            migrationPlan: nil
        )
        
        let context: ModelContext = database.openContext()
        
        try database.writeObjects(context: context, objects: objects)
             
        return database
    }
    
    public func deleteDatabase(directoryName: String) throws {
        
        try fileManager.removeUrl(url: getDirectory(directoryName: directoryName))
    }
}
