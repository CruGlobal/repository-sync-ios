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
public final class SwiftRepositorySyncPersistence<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableSwiftDataObject>: Persistence, Sendable {
        
    private let serialQueue: DispatchQueue = DispatchQueue(label: "swift.write.serial_queue")
    
    private let collectionObserver: SwiftDataCollectionObserver<PersistObjectType> = SwiftDataCollectionObserver()
    private let actorRead: SwiftDataActorRead<DataModelType, ExternalObjectType, PersistObjectType>
    public let database: SwiftDatabase
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(database: SwiftDatabase, dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.database = database
        self.dataModelMapping = dataModelMapping
                
        self.actorRead = SwiftDataActorRead(
            container: database.container.modelContainer,
            dataModelMapping: dataModelMapping
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
    
    @available(*, deprecated)
    public func getDataModelNonThrowing(id: String) -> DataModelType? {
        
        do {
            return try getDataModel(id: id)
        }
        catch _ {
            return nil
        }
    }
    
    public func getDataModel(id: String) throws -> DataModelType? {
        
        let context: ModelContext = database.openContext()
        
        let getObjectsByType = SwiftRepositorySyncGetObjects<PersistObjectType>()
        
        let persistObjects: [PersistObjectType] = try getObjectsByType.getObjects(
            context: context,
            getOption: .object(id: id),
            query: nil
        )
        
        guard let persistObject = persistObjects.first else {
            return nil
        }
        
        return dataModelMapping.toDataModel(persistObject: persistObject)
    }
    
    @available(*, deprecated)
    public func getDataModelsPublisher(getOption: PersistenceGetOption) -> AnyPublisher<[DataModelType], Error> {
        return getDataModelsPublisher(getOption: getOption, query: nil)
    }
    
    @available(*, deprecated)
    public func getDataModelsPublisher(getOption: PersistenceGetOption, query: SwiftDatabaseQuery<PersistObjectType>?) -> AnyPublisher<[DataModelType], Error> {
        
        return Future { promise in
            DispatchQueue.global().async {
                
                do {
                    
                    let context: ModelContext = self.database.openContext()
                    
                    let getObjectsByType = SwiftRepositorySyncGetObjects<PersistObjectType>()
                    
                    let persistObjects: [PersistObjectType] = try getObjectsByType.getObjects(
                        context: context,
                        getOption: getOption,
                        query: query
                    )

                    let dataModels: [DataModelType] = persistObjects.compactMap { object in
                        self.dataModelMapping.toDataModel(persistObject: object)
                    }
                    
                    promise(.success(dataModels))
                }
                catch let error {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func getDataModelsAsync(getOption: PersistenceGetOption) async throws -> [DataModelType] {
        return try await getDataModelsAsync(getOption: getOption, query: nil)
    }
    
    public func getDataModelsAsync(getOption: PersistenceGetOption, query: SwiftDatabaseQuery<PersistObjectType>?) async throws -> [DataModelType] {
        
        return try await actorRead.getDataModels(
            getOption: getOption,
            query: query
        )
    }
}

// MARK: - Write

@available(iOS 17.4, *)
extension SwiftRepositorySyncPersistence {

    public func writeObjectsAsync(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) async throws -> [DataModelType] {
        
        let actorWrite = SwiftDataActorWrite<DataModelType, ExternalObjectType, PersistObjectType>(
            container: database.container.modelContainer,
            dataModelMapping: dataModelMapping
        )
        
        return try await actorWrite.writeObjects(
            externalObjects: externalObjects,
            writeOption: writeOption,
            getOption: getOption
        )
    }
    
    @available(*, deprecated)
    public func writeObjectsPublisher(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) -> AnyPublisher<[DataModelType], Error> {
        
//        return Future { promise in
//            
//            Task {
//                
//                do {
//                    
//                    let dataModels = try await self.write
//                        .writeObjects(
//                            externalObjects: externalObjects,
//                            writeOption: writeOption,
//                            getOption: getOption
//                        )
//                    
//                    promise(.success(dataModels))
//                }
//                catch let error {
//                    promise(.failure(error))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
        
        return Future { promise in
            self.serialQueue.async {
                autoreleasepool {
                    do {
                        let context: ModelContext = self.database.openContext()
                        
                        let writeOnContext = SwiftRepositorySyncPersistenceWriteOnContext(
                            dataModelMapping: self.dataModelMapping
                        )
                        
                        let dataModels = try writeOnContext.write(
                            context: context,
                            externalObjects: externalObjects,
                            writeOption: writeOption,
                            getOption: getOption
                        )
                        
                        promise(.success(dataModels))
                    }
                    catch let error {
                        print("\n DID CATCH ERROR: \(error)")
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
