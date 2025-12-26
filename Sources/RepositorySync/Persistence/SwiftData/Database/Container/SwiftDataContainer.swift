//
//  SwiftDataContainer.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
public final class SwiftDataContainer: Sendable {
    
    public let modelContainer: ModelContainer
    public let configName: String
    public let configUrl: URL
    
    public init(modelConfiguration: ModelConfiguration, schema: Schema, migrationPlan: (any SchemaMigrationPlan.Type)?) throws {
                
        let modelContainer = try ModelContainer(
            for: schema,
            migrationPlan: migrationPlan,
            configurations: modelConfiguration
        )
        
        self.modelContainer = modelContainer
        
        configName = modelConfiguration.name
        configUrl = modelConfiguration.url
    }
    
    public static func createInMemoryContainer(name: String = UUID().uuidString, schema: Schema) throws -> SwiftDataContainer {
        
        let config = ModelConfiguration(
            name,
            schema: nil,
            isStoredInMemoryOnly: true,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )
        
        return try SwiftDataContainer(
            modelConfiguration: config,
            schema: schema,
            migrationPlan: nil
        )
    }
}
