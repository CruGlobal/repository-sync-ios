//
//  Persistence.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Combine

public protocol Persistence<DataModelType, ExternalObjectType> {
    
    associatedtype DataModelType
    associatedtype ExternalObjectType
    
    func getObjectCount() throws -> Int
    func getDataModel(id: String) throws -> DataModelType?
    
    @available(*, deprecated) func getDataModelNonThrowing(id: String) -> DataModelType?
    
    // Async Await
    
    func getDataModelsAsync(getOption: PersistenceGetOption) async throws -> [DataModelType]
    func writeObjectsAsync(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) async throws -> [DataModelType]
    
    // Combine Publisher
    
    @MainActor func observeCollectionChangesPublisher() -> AnyPublisher<Void, Error>
    @available(*, deprecated) func getDataModelsPublisher(getOption: PersistenceGetOption) -> AnyPublisher<[DataModelType], Error>
    @available(*, deprecated) func writeObjectsPublisher(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) -> AnyPublisher<[DataModelType], Error>
}
