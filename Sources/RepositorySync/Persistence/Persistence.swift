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
    
    @MainActor func observeCollectionChangesPublisher() -> AnyPublisher<Void, Error>
    func getObjectCount() throws -> Int
    // TODO: Once RealmSwift is removed and NSPredicate dropped, can MainActor can be removed here? ~Levi
    @MainActor func getDataModelsAsync(getOption: PersistenceGetOption) async throws -> [DataModelType]
    @MainActor func getDataModelsPublisher(getOption: PersistenceGetOption) -> AnyPublisher<[DataModelType], Error>
    @MainActor func writeObjectsAsync(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) async throws -> [DataModelType]
    @MainActor func writeObjectsPublisher(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) -> AnyPublisher<[DataModelType], Error>
}
