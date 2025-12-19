//
//  Persistence.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Combine

public protocol Persistence<DataModelType, ExternalObjectType> {
    
    associatedtype DataModelType
    associatedtype ExternalObjectType
    
    @MainActor func observeCollectionChangesPublisher() -> AnyPublisher<Void, Error>
    @MainActor func getObjectCount() throws -> Int
    @MainActor func getObjectsAsync(getObjectsType: GetObjectsType) async throws -> [DataModelType]
    @MainActor func getObjectsPublisher(getObjectsType: GetObjectsType) -> AnyPublisher<[DataModelType], Error>
    @MainActor func writeObjectsAsync(externalObjects: [ExternalObjectType], deleteObjectsNotFoundInExternalObjects: Bool, getObjectsType: GetObjectsType) async throws -> [DataModelType]
    @MainActor func writeObjectsPublisher(externalObjects: [ExternalObjectType], deleteObjectsNotFoundInExternalObjects: Bool, getObjectsType: GetObjectsType) -> AnyPublisher<[DataModelType], Error>
}
