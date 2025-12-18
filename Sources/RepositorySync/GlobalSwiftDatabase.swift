//
//  GlobalSwiftDatabase.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

// TODO: This singleton can be removed once RealmSwift is dropped.
//  This is needed while supporting realm with swift database fallback.
//  Clients should enable swiftdatabase by injecting here in enableSwiftDatabase method. ~Levi
@available(iOS 17.4, *)
@MainActor public class GlobalSwiftDatabase {
        
    static let shared: GlobalSwiftDatabase = GlobalSwiftDatabase()
    
    private(set) var swiftDatabase: SwiftDatabase?
    
    private init() {
        
    }
    
    public var swiftDatabaseEnabled: Bool {
        return swiftDatabase != nil
    }
    
    public func enableSwiftDatabase(swiftDatabase: SwiftDatabase) {
        self.swiftDatabase = swiftDatabase
    }
}
