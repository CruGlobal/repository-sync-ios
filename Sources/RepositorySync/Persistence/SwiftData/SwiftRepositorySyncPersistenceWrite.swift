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

    public func writeObjectsAsync(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?) async throws -> [DataModelType] {
        
        let context: ModelContext = self.context
        
        let persistObjects: [PersistObjectType] = externalObjects.compactMap {
            self.dataModelMapping.toPersistObject(externalObject: $0)
        }
        
        if persistObjects.count > 0 {
            for object in persistObjects {
                context.insert(object)
            }
        }
                
        guard context.hasChanges else {
            return Array()
        }
        
        try context.save()
        
        guard let getObjectsType = getObjectsType else {
            return Array()
        }
        
        // Get Objects
        
        let read = SwiftDataRead()
        let getObjects: [PersistObjectType]
                        
        switch getObjectsType {
            
        case .allObjects:
            getObjects = try read.objects(context: context, query: nil)
            
        case .object(let id):
            
            let object: PersistObjectType? = try read.object(context: context, id: id)
            
            if let object = object {
                getObjects = [object]
            }
            else {
                getObjects = []
            }
        }
        
        let dataModels: [DataModelType] = getObjects.compactMap { object in
            self.dataModelMapping.toDataModel(persistObject: object)
        }
        
        return dataModels
    }
    
    @MainActor public func writeObjectsPublisher(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?) -> AnyPublisher<[DataModelType], Error> {
        
        return Future { promise in
            
            Task {
                
                do {
                    let dataModels = try await self.writeObjectsAsync(externalObjects: externalObjects, getObjectsType: getObjectsType)
                    
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
