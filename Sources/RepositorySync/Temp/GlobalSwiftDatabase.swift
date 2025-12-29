//
//  GlobalSwiftDatabase.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

// TODO: This singleton can be removed once RealmSwift is dropped.
//  This is needed while supporting realm with swift database fallback.
//  Clients should enable swiftdatabase by injecting here in enableSwiftDatabase method. ~Levi
@available(iOS 17.4, *)
@MainActor class GlobalSwiftDatabase {
        
    static let shared: GlobalSwiftDatabase = GlobalSwiftDatabase()
    
    private(set) var swiftDatabase: SwiftDatabase?
    
    private init() {
        
    }

    func enableSwiftDatabase(swiftDatabase: SwiftDatabase) {
        self.swiftDatabase = swiftDatabase
    }
}
