//
//  SwiftRepositorySyncPersistenceWrite.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
public actor SwiftRepositorySyncPersistenceWrite<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableSwiftDataObject> {
    
    public let asyncWrite: SwiftDataAsyncWrite
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(asyncWrite: SwiftDataAsyncWrite, dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.asyncWrite = asyncWrite
        self.dataModelMapping = dataModelMapping
    }
    
    @MainActor private func writeObjectsBackground(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?, completion: @escaping ((_ result: Result<[DataModelType], Error>) -> Void)) {
        
    }
    
    @MainActor public func writeObjectsAsync(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?) async throws -> [DataModelType] {
        
        return Array()
    }
    
    private func mapExternalObjects(externalObjects: [ExternalObjectType]) -> [PersistObjectType] {
        
        return externalObjects.compactMap {
            self.dataModelMapping.toPersistObject(externalObject: $0)
        }
    }
}
