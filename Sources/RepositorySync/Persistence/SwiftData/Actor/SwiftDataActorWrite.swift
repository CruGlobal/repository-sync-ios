//
//  SwiftDataActorWrite.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
public actor SwiftDataActorWrite<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableSwiftDataObject> {
        
    private let container: ModelContainer
    private let executor: ModelExecutor
    
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
        
    public init(container: ModelContainer, dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.container = container
        self.executor = DefaultSerialModelExecutor(modelContext: ModelContext(container))
        
        self.dataModelMapping = dataModelMapping
    }
    
    public func writeObjects(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) async throws -> [DataModelType] {
                
        let writeOnContext = SwiftRepositorySyncPersistenceWriteOnContext(
            dataModelMapping: dataModelMapping
        )
        
        return try writeOnContext.write(
            context: executor.modelContext,
            externalObjects: externalObjects,
            writeOption: writeOption,
            getOption: getOption
        )
    }
}

@available(iOS 17.4, *)
extension SwiftDataActorWrite: ModelActor {
    
    nonisolated
    public var modelContainer: ModelContainer {
        return container
    }
    
    nonisolated
    public var modelExecutor: any ModelExecutor {
        return executor
    }
}
