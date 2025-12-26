//
//  SwiftDatabase.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
public final class SwiftDatabase: Sendable {
    
    public let container: SwiftDataContainer
    public let read: SwiftDataRead = SwiftDataRead()
    public let write: SwiftDataWrite = SwiftDataWrite()
    
    public init(container: SwiftDataContainer) {
        
        self.container = container
    }
    
    public func openContext(autosaveEnabled: Bool = false) -> ModelContext {
        let context = ModelContext(container.modelContainer)
        context.autosaveEnabled = autosaveEnabled
        return context
    }
    
    public var openContextAndRead: SwiftDataContextRead {
        return SwiftDataContextRead(context: openContext())
    }
}
