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
    private let read: SwiftRepositorySyncPersistenceRead<DataModelType, ExternalObjectType, PersistObjectType>
    private let write: SwiftRepositorySyncPersistenceWrite<DataModelType, ExternalObjectType, PersistObjectType>
    
    public let database: SwiftDatabase
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(database: SwiftDatabase, dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.database = database
        self.dataModelMapping = dataModelMapping
                
        self.read = SwiftRepositorySyncPersistenceRead(dataModelMapping: dataModelMapping)
        self.write = SwiftRepositorySyncPersistenceWrite(container: database.container.modelContainer, dataModelMapping: dataModelMapping)
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
    
    @MainActor public func getObjectCount() throws -> Int {
        
        let context: ModelContext = database.openContext()
        
        return try database
            .read.objectCount(
                context: context,
                query: SwiftDatabaseQuery<PersistObjectType>(
                    fetchDescriptor: FetchDescriptor<PersistObjectType>()
                )
            )
    }
    
    @MainActor public func getObjectsAsync(getObjectsType: GetObjectsType) async throws -> [DataModelType] {
        
        return try await getObjectsAsync(getObjectsType: getObjectsType, query: nil)
    }
    
    @MainActor public func getObjectsAsync(getObjectsType: GetObjectsType, query: SwiftDatabaseQuery<PersistObjectType>?) async throws -> [DataModelType] {
        
        return try await withCheckedThrowingContinuation { continuation in
            getObjectsBackground(getObjectsType: getObjectsType, query: query) { (result: Result<[DataModelType], Error>) in
                switch result {
                case .success(let dataModels):
                    continuation.resume(returning: dataModels)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    @MainActor public func getObjectsPublisher(getObjectsType: GetObjectsType) -> AnyPublisher<[DataModelType], Error> {
        
        return getObjectsPublisher(getObjectsType: getObjectsType, query: nil)
    }
    
    @MainActor public func getObjectsPublisher(getObjectsType: GetObjectsType, query: SwiftDatabaseQuery<PersistObjectType>?) -> AnyPublisher<[DataModelType], Error> {
        
        return Future { promise in
         
            self.getObjectsBackground(getObjectsType: getObjectsType, query: query, completion: { (result: Result<[DataModelType], Error>) in
                switch result {
                case .success(let dataModels):
                    promise(.success(dataModels))
                case .failure(let error):
                    promise(.failure(error))
                }
            })
        }
        .eraseToAnyPublisher()
    }
    
    @MainActor private func getObjectsBackground(getObjectsType: GetObjectsType, query: SwiftDatabaseQuery<PersistObjectType>?, completion: @escaping ((_ result: Result<[DataModelType], Error>) -> Void)) {
        
        Task {
            do {
                
                let context: ModelContext = self.database.openContext()
                let dataModels = try await read.getObjects(context: context, getObjectsType: getObjectsType, query: query)
                
                await MainActor.run {
                    completion(.success(dataModels))
                }
            }
            catch let error {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Write

@available(iOS 17.4, *)
extension SwiftRepositorySyncPersistence {

    @MainActor public func writeObjectsAsync(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?) async throws -> [DataModelType] {
        return try await write.writeObjectsAsync(externalObjects: externalObjects, getObjectsType: getObjectsType)
    }
    
    @MainActor public func writeObjectsPublisher(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?) -> AnyPublisher<[DataModelType], any Error> {
        return write.writeObjectsPublisher(externalObjects: externalObjects, getObjectsType: getObjectsType)
    }
}
