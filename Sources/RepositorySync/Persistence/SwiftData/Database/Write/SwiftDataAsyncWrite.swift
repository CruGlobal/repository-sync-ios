//
//  SwiftDataAsyncWrite.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
public actor SwiftDataAsyncWrite: ModelActor {
    
    private let container: ModelContainer
    private let executor: ModelExecutor
    
    nonisolated
    private let write: SwiftDataWrite = SwiftDataWrite()
    
    public init(container: ModelContainer) {
        
        self.container = container
        self.executor = DefaultSerialModelExecutor(modelContext: ModelContext(container))
    }
    
    nonisolated
    public var modelContainer: ModelContainer {
        return container
    }
    
    nonisolated
    public var modelExecutor: any ModelExecutor {
        return executor
    }
    
    nonisolated
    public var context: ModelContext {
        return executor.modelContext
    }
    
    nonisolated
    public func objects(deleteObjects: [any IdentifiableSwiftDataObject]?, insertObjects: [any IdentifiableSwiftDataObject]?) throws {
        try write.objects(context: executor.modelContext, deleteObjects: deleteObjects, insertObjects: insertObjects)
    }
}
