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
    associatedtype PersistObjectType
    associatedtype QueryType
    associatedtype SortByType
    
    @MainActor func observeCollectionChangesPublisher() -> AnyPublisher<Void, Error>
    func getObjectCount() throws -> Int
    func getPersistedObject(id: String) throws -> PersistObjectType?
    func getPersistedObjects(query: QueryType?) throws -> [PersistObjectType]
    func getPersistedObjects(ids: [String], sortBy: SortByType?) throws -> [PersistObjectType]
    // TODO: Once RealmSwift is removed and NSPredicate dropped, MainActor can be removed here. ~Levi
    @MainActor func getObjectsAsync(getObjectsType: GetObjectsType) async throws -> [DataModelType]
    @MainActor func getObjectsPublisher(getObjectsType: GetObjectsType) -> AnyPublisher<[DataModelType], Error>
    @MainActor func writeObjectsAsync(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getObjectsType: GetObjectsType?) async throws -> [DataModelType]
    @MainActor func writeObjectsPublisher(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getObjectsType: GetObjectsType?) -> AnyPublisher<[DataModelType], Error>
}
