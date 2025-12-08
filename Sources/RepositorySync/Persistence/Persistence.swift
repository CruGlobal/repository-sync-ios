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
    func getObjectCount() throws -> Int
    func getObject(id: String) throws -> DataModelType?
    func getObjects() throws -> [DataModelType]
    func getObjects(ids: [String]) throws -> [DataModelType]
    func writeObjectsPublisher(writeClosure: @escaping (() -> [ExternalObjectType]), deleteObjectsNotFoundInExternalObjects: Bool) -> AnyPublisher<Void, Error>
}
