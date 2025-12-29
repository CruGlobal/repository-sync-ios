//
//  RepositorySync.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Combine

@MainActor open class RepositorySync<DataModelType: Sendable, ExternalDataFetchType: ExternalDataFetchInterface, RealmObjectType: IdentifiableRealmObject> {
        
    private let realmMapping: any Mapping<DataModelType, ExternalDataFetchType.ExternalObject, RealmObjectType>
    
    private var cancellables: Set<AnyCancellable> = Set()
    
    public let externalDataFetch: ExternalDataFetchType
    
    public init(externalDataFetch: ExternalDataFetchType, realmMapping: any Mapping<DataModelType, ExternalDataFetchType.ExternalObject, RealmObjectType>) {
        
        self.externalDataFetch = externalDataFetch
        self.realmMapping = realmMapping
    }
    
    public var realmDatabase: RealmDatabase {
        return GlobalRealmDatabase.shared.realmDatabase
    }
    
    public func getRealmPersistence(realmDatabase: RealmDatabase) -> (any Persistence<DataModelType, ExternalDataFetchType.ExternalObject>) {
        return RealmRepositorySyncPersistence(
            database: realmDatabase,
            dataModelMapping: realmMapping
        )
    }
    
    @available(iOS 17.4, *)
    public var swiftDatabase: SwiftDatabase? {
        return GlobalSwiftDatabase.shared.swiftDatabase
    }
    
    @available(iOS 17.4, *)
    open func getSwiftPersistence(swiftDatabase: SwiftDatabase) -> (any Persistence<DataModelType, ExternalDataFetchType.ExternalObject>)? {
        // NOTE: Subclasses should override and return a SwiftRepositorySyncPersistence. ~Levi
        return nil
    }
    
    public func getPersistence() -> (any Persistence<DataModelType, ExternalDataFetchType.ExternalObject>) {
        
        if #available(iOS 17.4, *),
           let swiftDatabase = swiftDatabase,
           let swiftPersistence = getSwiftPersistence(swiftDatabase: swiftDatabase) {
            
            return swiftPersistence
        }

        return RealmRepositorySyncPersistence(
            database: realmDatabase,
            dataModelMapping: realmMapping
        )
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
                writeOption: nil,
                getObjectsType: getObjectsType
            )
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Get Objects

extension RepositorySync {
    
    public func fetchObjectsPublisher(fetchType: FetchType, getObjectsType: GetObjectsType, context: ExternalDataFetchType.ExternalDataFetchContext) -> AnyPublisher<[DataModelType], Error> {
        
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
    
    private func getObjectsPublisher(getObjectsType: GetObjectsType, cachePolicy: GetCachePolicy, context: ExternalDataFetchType.ExternalDataFetchContext) -> AnyPublisher<[DataModelType], Error> {
        
        switch cachePolicy {
            
        case .ignoreCacheData:
            
            return fetchAndStoreObjectsFromExternalDataFetchPublisher(
                getObjectsType: getObjectsType,
                context: context
            )
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            
        case .returnCacheDataDontFetch:
            
            return getPersistence()
                .getObjectsPublisher(getObjectsType: getObjectsType)
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
                .flatMap { _ in
                    return self.getPersistence().getObjectsPublisher(
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
                .flatMap { _ in
                    return self.getPersistence().getObjectsPublisher(
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
                .flatMap { _ in
                    return self.getPersistence().getObjectsPublisher(
                        getObjectsType: getObjectsType
                    )
                }
                .eraseToAnyPublisher()
        }
    }
}
