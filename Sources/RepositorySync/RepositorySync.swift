//
//  RepositorySync.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Combine

@MainActor open class RepositorySync<DataModelType, ExternalDataFetchType: ExternalDataFetchInterface, RealmObjectType: IdentifiableRealmObject> {
    
    private var cancellables: Set<AnyCancellable> = Set()
    
    public let externalDataFetch: ExternalDataFetchType
    public let swiftElseRealmPersistence: SwiftElseRealmPersistence<DataModelType, ExternalDataFetchType.ExternalObject, RealmObjectType>
    
    public init(externalDataFetch: ExternalDataFetchType, swiftElseRealmPersistence: SwiftElseRealmPersistence<DataModelType, ExternalDataFetchType.ExternalObject, RealmObjectType>) {
        
        self.externalDataFetch = externalDataFetch
        self.swiftElseRealmPersistence = swiftElseRealmPersistence
    }
    
    public var realmDatabase: RealmDatabase {
        return swiftElseRealmPersistence.realmPersistence.database
    }
    
    @available(iOS 17.4, *)
    public var swiftDatabase: SwiftDatabase? {
        return swiftElseRealmPersistence.getSwiftDatabase()
    }
    
    public func getPersistence() -> any Persistence<DataModelType, ExternalDataFetchType.ExternalObject> {
        return swiftElseRealmPersistence.getPersistence()
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
    
    private func makeSinkingfetchAndStoreObjectsFromExternalDataFetch(getObjectsType: GetObjectsType, context: ExternalDataFetchType.ExternalDataFetchContext) {
        
        fetchAndStoreObjectsFromExternalDataFetchPublisher(
            getObjectsType: getObjectsType,
            context: context
        )
        .sink(receiveCompletion: { completion in
            
        }, receiveValue: { _ in
            
        })
        .store(in: &cancellables)
    }
    
    private func fetchAndStoreObjectsFromExternalDataFetchPublisher(getObjectsType: GetObjectsType, context: ExternalDataFetchType.ExternalDataFetchContext) -> AnyPublisher<[DataModelType], Error> {
                
        return fetchExternalObjectsPublisher(
            getObjectsType: getObjectsType,
            context: context
        )
        .receive(on: DispatchQueue.main)
        .flatMap { (externalObjects: [ExternalDataFetchType.ExternalObject]) in
            
            return self.getPersistence().writeObjectsPublisher(
                externalObjects: externalObjects,
                deleteObjectsNotFoundInExternalObjects: false,
                getObjectsType: getObjectsType
            )
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Get Objects

extension RepositorySync {
    
    // TODO: Questions, Unknowns, Etc.
    /*
        - How do we handle more complex external data fetching?  For instance, a url request could contain query parameters and http body. Do we force that on subclasses of repository sync?  Do we provide methods for subclasses to hook into for observing, pushing data models for syncing, etc?
     */
    
    public func fetchObjectsPublisher(fetchType: FetchType, getObjectsType: GetObjectsType, context: ExternalDataFetchType.ExternalDataFetchContext) -> AnyPublisher<[DataModelType], Error> {
        
        switch fetchType {
            
        case .get(let getCachePolicy):
            
            return getObjects(
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
    
    private func getObjects(getObjectsType: GetObjectsType, cachePolicy: GetCachePolicy, context: ExternalDataFetchType.ExternalDataFetchContext) -> AnyPublisher<[DataModelType], Error> {
        
        switch cachePolicy {
            
        case .ignoreCacheData:
            
            return fetchAndStoreObjectsFromExternalDataFetchPublisher(
                getObjectsType: getObjectsType,
                context: context
            )
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            
        case .returnCacheDataDontFetch:
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        
        case .returnCacheDataElseFetch:
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
    
    private func observeObjects(getObjectsType: GetObjectsType, cachePolicy: ObserveCachePolicy, context: ExternalDataFetchType.ExternalDataFetchContext) -> AnyPublisher<[DataModelType], Error> {
                
        switch cachePolicy {
            
        case .returnCacheDataDontFetch:
            
            return getPersistence()
                .observeCollectionChangesPublisher()
                .tryMap { _ in
                    return try self.getPersistence().getObjects(
                        getObjectsType: getObjectsType
                    )
                }
                .eraseToAnyPublisher()
        
        case .returnCacheDataElseFetch:
            
            let persistedObjectCount: Int
            
            do {
                persistedObjectCount = try getPersistence().getObjectCount()
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

            return getPersistence()
                .observeCollectionChangesPublisher()
                .map { _ in
                    print("\n DID OBSERVE CHANGES : \(cachePolicy)")
                    return Void()
                }
                .tryMap { _ in
                    return try self.getPersistence().getObjects(
                        getObjectsType: getObjectsType
                    )
                }
                .eraseToAnyPublisher()
        
        case .returnCacheDataAndFetch:
           
            makeSinkingfetchAndStoreObjectsFromExternalDataFetch(
                getObjectsType: getObjectsType,
                context: context
            )

            return getPersistence()
                .observeCollectionChangesPublisher()
                .tryMap { _ in
                    return try self.getPersistence().getObjects(
                        getObjectsType: getObjectsType
                    )
                }
                .eraseToAnyPublisher()
        }
    }
}
