//
//  Mapping.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

public protocol Mapping<DataModelType, ExternalObjectType, PersistObjectType> {
        
    associatedtype DataModelType: Sendable
    associatedtype ExternalObjectType: Sendable
    associatedtype PersistObjectType
    
    func toDataModel(externalObject: ExternalObjectType) -> DataModelType?
    func toDataModel(persistObject: PersistObjectType) -> DataModelType?
    func toPersistObject(externalObject: ExternalObjectType) -> PersistObjectType?
}
