//
//  SwiftRepositorySyncPersistenceWrite.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData
import Combine

@available(iOS 17.4, *)
public actor SwiftRepositorySyncPersistenceWrite<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableSwiftDataObject> {
        
    private let container: ModelContainer
    private let executor: ModelExecutor
    
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(container: ModelContainer, dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.container = container
        self.executor = DefaultSerialModelExecutor(modelContext: ModelContext(container))
        
        self.dataModelMapping = dataModelMapping
    }
    
    public var context: ModelContext {
        return modelContext
    }

    public func writeObjectsAsync(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) async throws -> [DataModelType] {
        
        let context: ModelContext = self.context

        var objectsToDelete: [PersistObjectType] = Array()
        var objectsToInsert: [PersistObjectType] = Array()
        
        if let writeOption = writeOption {
            
            switch writeOption {
            case .deleteObjectsNotInExternal:
                objectsToDelete = try SwiftDataRead().objects(context: context, query: nil)
            }
        }
        
        for externalObject in externalObjects {
            
            guard let dataModel = self.dataModelMapping.toPersistObject(externalObject: externalObject) else {
                continue
            }
            
            if let index = objectsToDelete.firstIndex(where: { $0.id == dataModel.id }) {
                objectsToDelete.remove(at: index)
            }
            
            objectsToInsert.append(dataModel)
        }

        if objectsToDelete.count > 0 {
            for object in objectsToDelete {
                context.delete(object)
            }
        }
        
        if objectsToInsert.count > 0 {
            for object in objectsToInsert {
                context.insert(object)
            }
        }
        
        if context.hasChanges {
            try context.save()
        }
        
        guard let getOption = getOption else {
            return Array()
        }
                
        let getObjectsByType: SwiftRepositorySyncGetObjects<PersistObjectType> = SwiftRepositorySyncGetObjects()
        
        let getObjects: [PersistObjectType] = try getObjectsByType.getObjects(
            context: context,
            getOption: getOption,
            query: nil
        )
        
        let dataModels: [DataModelType] = getObjects.compactMap { object in
            self.dataModelMapping.toDataModel(persistObject: object)
        }
        
        return dataModels
    }
    
    @MainActor public func writeObjectsPublisher(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) -> AnyPublisher<[DataModelType], Error> {
        
        return Future { promise in
            
            Task {
                
                do {
                    
                    let dataModels = try await self.writeObjectsAsync(
                        externalObjects: externalObjects,
                        writeOption: writeOption,
                        getOption: getOption
                    )
                    
                    promise(.success(dataModels))
                }
                catch let error {
                    
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

@available(iOS 17.4, *)
extension SwiftRepositorySyncPersistenceWrite: ModelActor {
    
    nonisolated
    public var modelContainer: ModelContainer {
        return container
    }
    
    nonisolated
    public var modelExecutor: any ModelExecutor {
        return executor
    }
}
