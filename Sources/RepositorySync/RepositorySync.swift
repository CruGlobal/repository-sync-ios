//
//  RepositorySync.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Combine

public final class RepositorySync<DataModelType: Sendable, ExternalDataFetchType: ExternalDataFetchInterface> {
    
    private var cancellables: Set<AnyCancellable> = Set()
    
    public let externalDataFetch: ExternalDataFetchType
    public let persistence: any Persistence<DataModelType, ExternalDataFetchType.ExternalObject>
    
    public init(externalDataFetch: ExternalDataFetchType, persistence: any Persistence<DataModelType, ExternalDataFetchType.ExternalObject>) {
        
        self.externalDataFetch = externalDataFetch
        self.persistence = persistence
    }
    
    private func fetchExternalObjects(getObjectsType: GetObjectsType, context: ExternalDataFetchType.ExternalDataFetchContext) async throws -> [ExternalDataFetchType.ExternalObject]  {
        
        switch getObjectsType {
        case .allObjects:
            return try await externalDataFetch
                .getObjects(context: context)
            
        case .object(let id):
            return try await externalDataFetch
                .getObject(id: id, context: context)
        }
    }
    
    private func fetchAndStoreObjectsFromExternalDataFetch(getObjectsType: GetObjectsType, context: ExternalDataFetchType.ExternalDataFetchContext) async throws -> [DataModelType] {
                
        let externalObjects: [ExternalDataFetchType.ExternalObject] = try await fetchExternalObjects(
            getObjectsType: getObjectsType,
            context: context
        )
        
        let dataModels: [DataModelType] = try await persistence.writeObjectsAsync(
            externalObjects: externalObjects,
            writeOption: nil,
            getOption: getObjectsType.toGetOption()
        )
        
        return dataModels
    }
    
    public func getDataModels(getObjectsType: GetObjectsType, cachePolicy: GetCachePolicy, context: ExternalDataFetchType.ExternalDataFetchContext) async throws -> [DataModelType] {
        
        switch cachePolicy {
            
        case .ignoreCacheData:
            
            return try await fetchAndStoreObjectsFromExternalDataFetch(
                getObjectsType: getObjectsType,
                context: context
            )
            
        case .returnCacheDataDontFetch:
            
            return try await persistence
                .getDataModelsAsync(
                    getOption: getObjectsType.toGetOption()
                )

        case .returnCacheDataElseFetch:
            
            let persistedObjectCount: Int
            
            do {
                persistedObjectCount = try persistence.getObjectCount()
            }
            catch let error {
                throw error
            }
            
            if persistedObjectCount == 0 {
                
                return try await getDataModels(
                    getObjectsType: getObjectsType,
                    cachePolicy: .ignoreCacheData,
                    context: context
                )
            }
            else {
                
                return try await getDataModels(
                    getObjectsType: getObjectsType,
                    cachePolicy: .returnCacheDataDontFetch,
                    context: context
                )
            }
        }
    }
    
    /*

    @MainActor public func observeDataModelsPublisher(getObjectsType: GetObjectsType, cachePolicy: ObserveCachePolicy, context: ExternalDataFetchType.ExternalDataFetchContext) -> AnyPublisher<[DataModelType], Error> {
        
        switch cachePolicy {
            
        case .returnCacheDataDontFetch:
            
            return persistence
                .observeCollectionChangesPublisher()
                .receive(on: DispatchQueue.main)
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
                
                return observeDataModelsPublisher(
                    getObjectsType: getObjectsType,
                    cachePolicy: .returnCacheDataAndFetch,
                    context: context
                )
            }
            else {
                
                return observeDataModelsPublisher(
                    getObjectsType: getObjectsType,
                    cachePolicy: .returnCacheDataDontFetch,
                    context: context
                )
            }
        
        case .returnCacheDataAndFetch:
           
            makeSinkingfetchAndStoreObjectsFromExternalDataFetch(
                getObjectsType: getObjectsType,
                context: context
            )

            return persistence
                .observeCollectionChangesPublisher()
                .flatMap { _ in
                    return self.persistence.getDataModelsPublisher(
                        getOption: getObjectsType.toGetOption()
                    )
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    }*/
}
