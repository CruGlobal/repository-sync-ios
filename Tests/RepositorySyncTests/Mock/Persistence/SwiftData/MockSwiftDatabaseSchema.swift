//
//  MockSwiftDatabaseSchema.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
enum MockSwiftDatabaseSchema: VersionedSchema {
    
    static let versionIdentifier = Schema.Version(1, 0, 0)
        
    static var models: [any PersistentModel.Type] {
        return [
            MockSwiftObject.self
        ]
    }
}
