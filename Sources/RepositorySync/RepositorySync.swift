//
//  RepositorySync.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Combine

open class RepositorySync<DataModelType: Sendable, ExternalDataFetchType: ExternalDataFetchInterface> {
    
    private var cancellables: Set<AnyCancellable> = Set()
    
    public let externalDataFetch: ExternalDataFetchType
    public let persistence: any Persistence<DataModelType, ExternalDataFetchType.ExternalObject>
    
    public init(externalDataFetch: ExternalDataFetchType, persistence: any Persistence<DataModelType, ExternalDataFetchType.ExternalObject>) {
        
        self.externalDataFetch = externalDataFetch
        self.persistence = persistence
    }
    
    // MARK: - Persistence
    
    open func getRealmPersistence<T: IdentifiableRealmObject>() -> RealmRepositorySyncPersistence<DataModelType, ExternalDataFetchType.ExternalObject, T>? {
        return persistence as? RealmRepositorySyncPersistence<DataModelType, ExternalDataFetchType.ExternalObject, T>
    }
    
    @available(iOS 17.4, *)
    open func getSwiftPersistence<T: IdentifiableSwiftDataObject>() -> SwiftRepositorySyncPersistence<DataModelType, ExternalDataFetchType.ExternalObject, T>? {
        return persistence as? SwiftRepositorySyncPersistence<DataModelType, ExternalDataFetchType.ExternalObject, T>
    }
}

// MARK: - External Data Fetch

extension RepositorySync {
    
    private func fetchExternalObjectsPublisher(getObjectsType: GetObjectsType, context: ExternalDataFetchType.ExternalDataFetchContext) -> AnyPublisher<[ExternalDataFetchType.ExternalObject], Error>  {
        
        switch getObjectsType {
        case .allObjects:
            return externalDataFetch
                .getObjectsPublisher(context: context)
                .eraseToAnyPublisher()
            
        case .object(let id):
            return externalDataFetch
                .getObjectPublisher(id: id, context: context)
                .eraseToAnyPublisher()
        }
    }
    
    @MainActor private func makeSinkingfetchAndStoreObjectsFromExternalDataFetch(getObjectsType: GetObjectsType, context: ExternalDataFetchType.ExternalDataFetchContext) {
        
        fetchAndStoreObjectsFromExternalDataFetchPublisher(
            getObjectsType: getObjectsType,
            context: context
        )
        .sink(receiveCompletion: { completion in
            
        }, receiveValue: { _ in
            
        })
        .store(in: &cancellables)
    }
    
    @MainActor private func fetchAndStoreObjectsFromExternalDataFetchPublisher(getObjectsType: GetObjectsType, context: ExternalDataFetchType.ExternalDataFetchContext) -> AnyPublisher<[DataModelType], Error> {
                
        return fetchExternalObjectsPublisher(
            getObjectsType: getObjectsType,
            context: context
        )
        .receive(on: DispatchQueue.main)
        .flatMap { (externalObjects: [ExternalDataFetchType.ExternalObject]) in
            
            return self.persistence.writeObjectsPublisher(
                externalObjects: externalObjects,
                writeOption: nil,
                getObjectsType: getObjectsType
            )
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Get Objects

extension RepositorySync {
    
    @MainActor public func fetchObjectsPublisher(fetchType: FetchType, getObjectsType: GetObjectsType, context: ExternalDataFetchType.ExternalDataFetchContext) -> AnyPublisher<[DataModelType], Error> {
        
        switch fetchType {
            
        case .get(let getCachePolicy):
            
            return getObjectsPublisher(
                getObjectsType: getObjectsType,
                cachePolicy: getCachePolicy,
                context: context
            )
            
        case .observe(let observeCachePolicy):
            
            return observeObjects(
                getObjectsType: getObjectsType,
                cachePolicy: observeCachePolicy,
                context: context
            )
        }
    }
    
    @MainActor private func getObjectsPublisher(getObjectsType: GetObjectsType, cachePolicy: GetCachePolicy, context: ExternalDataFetchType.ExternalDataFetchContext) -> AnyPublisher<[DataModelType], Error> {
        
        switch cachePolicy {
            
        case .ignoreCacheData:
            
            return fetchAndStoreObjectsFromExternalDataFetchPublisher(
                getObjectsType: getObjectsType,
                context: context
            )
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            
        case .returnCacheDataDontFetch:
            
            return persistence
                .getObjectsPublisher(getObjectsType: getObjectsType)
                .eraseToAnyPublisher()
        
        case .returnCacheDataElseFetch:
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
    
    @MainActor private func observeObjects(getObjectsType: GetObjectsType, cachePolicy: ObserveCachePolicy, context: ExternalDataFetchType.ExternalDataFetchContext) -> AnyPublisher<[DataModelType], Error> {
                
        switch cachePolicy {
            
        case .returnCacheDataDontFetch:
            
            return persistence
                .observeCollectionChangesPublisher()
                .flatMap { _ in
                    return self.persistence.getObjectsPublisher(
                        getObjectsType: getObjectsType
                    )
                }
                .eraseToAnyPublisher()
        
        case .returnCacheDataElseFetch:
            
            let persistedObjectCount: Int
            
            do {
                persistedObjectCount = try persistence.getObjectCount()
            }
            catch let error {
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
            
            if persistedObjectCount == 0 {

                makeSinkingfetchAndStoreObjectsFromExternalDataFetch(
                    getObjectsType: getObjectsType,
                    context: context
                )
            }

            return persistence
                .observeCollectionChangesPublisher()
                .flatMap { _ in
                    return self.persistence.getObjectsPublisher(
                        getObjectsType: getObjectsType
                    )
                }
                .eraseToAnyPublisher()
        
        case .returnCacheDataAndFetch:
           
            makeSinkingfetchAndStoreObjectsFromExternalDataFetch(
                getObjectsType: getObjectsType,
                context: context
            )

            return persistence
                .observeCollectionChangesPublisher()
                .flatMap { _ in
                    return self.persistence.getObjectsPublisher(
                        getObjectsType: getObjectsType
                    )
                }
                .eraseToAnyPublisher()
        }
    }
}
