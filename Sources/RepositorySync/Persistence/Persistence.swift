//
//  Persistence.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Combine

public protocol Persistence<DataModelType, ExternalObjectType>: Sendable {
    
    associatedtype DataModelType: Sendable
    associatedtype ExternalObjectType: Sendable
    
    func getObjectCount() throws -> Int
    func getDataModel(id: String) throws -> DataModelType?
    func getDataModels() async throws -> [DataModelType]
    func getDataModels(getOption: PersistenceGetOption) async throws -> [DataModelType]
    func writeObjects(externalObjects: [ExternalObjectType]) async throws
    func writeObjects(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?) async throws -> [DataModelType]
    func deleteCollection() async throws
    func deleteObjectsByIds(ids: Set<String>, getOption: PersistenceGetOption?) async throws -> [DataModelType]
    
    @MainActor func observeCollectionChangesPublisher() -> AnyPublisher<Void, Error>
}
