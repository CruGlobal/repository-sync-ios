//
//  RepositorySyncPersistence.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Combine

public protocol RepositorySyncPersistence<DataModelType, ExternalObjectType> {
    
    associatedtype DataModelType
    associatedtype ExternalObjectType
    
    func observeCollectionChangesPublisher() -> AnyPublisher<Void, Never>
//    func getObjectCount() -> Int
//    func getObject(id: String) -> DataModelType?
//    func getObjects() -> [DataModelType]
//    func getObjects(ids: [String]) -> [DataModelType]
//    func writeObjects(externalObjects: [ExternalObjectType], deleteObjectsNotFoundInExternalObjects: Bool) -> [DataModelType]
//    func deleteAllObjects()
}
