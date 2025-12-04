//
//  RepositorySyncMapping.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

public protocol RepositorySyncMapping<DataModelType, ExternalObjectType, PersistObjectType> {
        
    associatedtype DataModelType
    associatedtype ExternalObjectType
    associatedtype PersistObjectType
    
    func toDataModel(externalObject: ExternalObjectType) -> DataModelType?
    func toDataModel(persistObject: PersistObjectType) -> DataModelType?
    func toPersistObject(externalObject: ExternalObjectType) -> PersistObjectType?
}
