//
//  SwiftRepositorySyncPersistence.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData
import Combine

@available(iOS 17.4, *)
public final class SwiftRepositorySyncPersistence<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableSwiftDataObject>: Persistence {
            
    private let collectionObserver: SwiftDataCollectionObserver<PersistObjectType> = SwiftDataCollectionObserver()
    
    public let database: SwiftDatabase
    public let mapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(database: SwiftDatabase, mapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.database = database
        self.mapping = mapping
    }
    
    public func createSwiftDataActorRead() -> SwiftDataActorRead<DataModelType, ExternalObjectType, PersistObjectType> {
        return SwiftDataActorRead(
            container: database.container.modelContainer,
            mapping: mapping
        )
    }
    
    public func createSwiftDataActorWrite() -> SwiftDataActorWrite<DataModelType, ExternalObjectType, PersistObjectType> {
        return SwiftDataActorWrite(
            container: database.container.modelContainer,
            mapping: mapping
        )
    }
}

// MARK: - Observe

@available(iOS 17.4, *)
extension SwiftRepositorySyncPersistence {
    
    @MainActor public func observeCollectionChangesPublisher() -> AnyPublisher<Void, Error> {
        
        return collectionObserver
            .observeCollectionChangesPublisher(database: database)
            .eraseToAnyPublisher()
    }
}

// MARK: Read

@available(iOS 17.4, *)
extension SwiftRepositorySyncPersistence {
    
    public func getObjectCount() throws -> Int {
        
        let context: ModelContext = database.openContext()
        
        return try database
            .read.objectCount(
                context: context,
                query: SwiftDatabaseQuery<PersistObjectType>(
                    fetchDescriptor: FetchDescriptor<PersistObjectType>()
                )
            )
    }
    
    public func getDataModel(id: String) throws -> DataModelType? {
        
        let context: ModelContext = database.openContext()
        
        let persistObjects: [PersistObjectType] = try SwiftDataRead()
            .getObjects(context: context, readObjectsType: .object(id: id))
        
        guard let persistObject = persistObjects.first else {
            return nil
        }
        
        return mapping.toDataModel(persistObject: persistObject)
    }
    
    public func getDataModels(getOption: PersistenceGetOption) async throws -> [DataModelType] {
        
        let readActor = createSwiftDataActorRead()
        
        return try await readActor.getDataModels(
            readObjectsType: getOption.toSwiftDataReadObjectsType()
        )
    }
}

// MARK: - Write

@available(iOS 17.4, *)
extension SwiftRepositorySyncPersistence {

    public func writeObjects(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) async throws -> [DataModelType] {
        
        let writeActor = createSwiftDataActorWrite()
        
        return try await writeActor.writeObjects(
            externalObjects: externalObjects,
            writeOption: writeOption,
            readObjectsType: getOption?.toSwiftDataReadObjectsType()
        )
    }
}
