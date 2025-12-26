//
//  SwiftRepositorySyncPersistenceRead.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
public actor SwiftRepositorySyncPersistenceRead<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableSwiftDataObject> {
    
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.dataModelMapping = dataModelMapping
    }
    
    public func getObjects(context: ModelContext, getObjectsType: GetObjectsType, query: SwiftDatabaseQuery<PersistObjectType>?) throws -> [DataModelType] {
                   
        let read = SwiftDataRead()
        
        let persistObjects: [PersistObjectType]
                
        switch getObjectsType {
            
        case .allObjects:
            persistObjects = try read.objects(context: context, query: query)
            
        case .object(let id):
            
            let object: PersistObjectType? = try read.object(context: context, id: id)
            
            if let object = object {
                persistObjects = [object]
            }
            else {
                persistObjects = []
            }
        }
        
        let dataModels: [DataModelType] = persistObjects.compactMap { object in
            self.dataModelMapping.toDataModel(persistObject: object)
        }
        
        return dataModels
    }
}
