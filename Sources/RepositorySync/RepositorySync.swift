//
//  RepositorySync.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Combine

open class RepositorySync<DataModelType, ExternalDataFetchType: ExternalDataFetchInterface> {
    
    private var cancellables: Set<AnyCancellable> = Set()
    
    let externalDataFetch: ExternalDataFetchType
    let persistence: any Persistence<DataModelType, ExternalDataFetchType.ExternalObject>
    
    public init(externalDataFetch: ExternalDataFetchType, persistence: any Persistence<DataModelType, ExternalDataFetchType.ExternalObject>) {
        
        self.externalDataFetch = externalDataFetch
        self.persistence = persistence
    }
}

// MARK: - External Data Fetch

extension RepositorySync {
    
    private func fetchExternalObjects(getObjectsType: GetObjectsType, context: ExternalDataFetchType.ExternalDataFetchContext) -> AnyPublisher<[ExternalDataFetchType.ExternalObject], Error>  {
        
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
    
    private func fetchAndStoreObjectsFromExternalDataFetchPublisher(getObjectsType: GetObjectsType, context: ExternalDataFetchType.ExternalDataFetchContext) -> AnyPublisher<Void, Error> {
                
        return fetchExternalObjects(
            getObjectsType: getObjectsType,
            context: context
        )
        .flatMap { (externalObjects: [ExternalDataFetchType.ExternalObject]) in
            
            return self.persistence
                .writeObjectsPublisher(writeClosure: {
                    return externalObjects
                }, deleteObjectsNotFoundInExternalObjects: false)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Get Objects

extension RepositorySync {
    
    private func getDataModels(getObjectsType: GetObjectsType) throws -> [DataModelType] {
                
        switch getObjectsType {
            
        case .allObjects:
            
            return try self.persistence.getObjects()
            
        case .object(let id):
           
            guard let dataModel = try self.persistence.getObject(id: id) else {
                return []
            }
            
            return [dataModel]
        }
    }
    
    private func getDataModelsPublisher(getObjectsType: GetObjectsType) -> AnyPublisher<[DataModelType], Error> {
        
        do {
            
            let dataModels: [DataModelType] = try getDataModels(getObjectsType: getObjectsType)
            
            return Just(dataModels)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        catch let error {
            
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
    
    // TODO: Questions, Unknowns, Etc.
    /*
        - How do we handle more complex external data fetching?  For instance, a url request could contain query parameters and http body. Do we force that on subclasses of repository sync?  Do we provide methods for subclasses to hook into for observing, pushing data models for syncing, etc?
     */
    
    @MainActor public func getObjectsPublisher(getObjectsType: GetObjectsType, cachePolicy: CachePolicy, context: ExternalDataFetchType.ExternalDataFetchContext) -> AnyPublisher<[DataModelType], Error> {
                
        switch cachePolicy {
            
        case .fetchIgnoringCacheData:
            
            return fetchAndStoreObjectsFromExternalDataFetchPublisher(
                getObjectsType: getObjectsType,
                context: context
            )
            .tryMap { _ in
                return try self.getDataModels(
                    getObjectsType: getObjectsType
                )
            }
            .eraseToAnyPublisher()
            
        case .returnCacheDataDontFetch(let observeChanges):
            
            if observeChanges {
               
                return persistence
                    .observeCollectionChangesPublisher()
                    .tryMap { _ in
                        return try self.getDataModels(
                            getObjectsType: getObjectsType
                        )
                    }
                    .eraseToAnyPublisher()
            }
            else {
                               
                return self.getDataModelsPublisher(
                    getObjectsType: getObjectsType
                )
            }
        
        case .returnCacheDataElseFetch(let observeChanges):
            
            let persistedObjectCount: Int
            
            do {
                persistedObjectCount = try persistence.getObjectCount()
            }
            catch let error {
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
            
            if observeChanges {

                if persistedObjectCount == 0 {

                    makeSinkingfetchAndStoreObjectsFromExternalDataFetch(
                        getObjectsType: getObjectsType,
                        context: context
                    )
                }

                return persistence
                    .observeCollectionChangesPublisher()
                    .tryMap { _ in
                        return try self.getDataModels(
                            getObjectsType: getObjectsType
                        )
                    }
                    .eraseToAnyPublisher()
            }
            else {

                if persistedObjectCount == 0 {

                    return fetchAndStoreObjectsFromExternalDataFetchPublisher(
                        getObjectsType: getObjectsType,
                        context: context
                    )
                    .tryMap { _ in
                        return try self.getDataModels(
                            getObjectsType: getObjectsType
                        )
                    }
                    .eraseToAnyPublisher()
                }
                else {

                    return self.getDataModelsPublisher(
                        getObjectsType: getObjectsType
                    )
                }
            }
        
        case .returnCacheDataAndFetch:
           
            makeSinkingfetchAndStoreObjectsFromExternalDataFetch(
                getObjectsType: getObjectsType,
                context: context
            )

            return persistence
                .observeCollectionChangesPublisher()
                .tryMap { _ in
                    return try self.getDataModels(
                        getObjectsType: getObjectsType
                    )
                }
                .eraseToAnyPublisher()
        }
    }
}
