//
//  SwiftDataActorWrite+NonThrowing.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/7/26.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
extension SwiftDataActorWrite {
    
    public func addObjectsNonThrowing(
        externalObjects: [ExternalObjectType],
        readObjectsType: SwiftDataReadObjectsType<PersistObjectType>? = nil,
        shouldAssertWhenError: Bool = true
    ) -> [DataModelType] {
        
        do {
            return try addObjects(externalObjects: externalObjects, readObjectsType: readObjectsType)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return Array()
        }
    }
    
    public func deleteObjectsByIdsNonThrowing(
        ids: Set<String>,
        readObjectsType: SwiftDataReadObjectsType<PersistObjectType>? = nil,
        shouldAssertWhenError: Bool = true
    ) -> [DataModelType] {
        
        do {
            return try deleteObjectsByIds(ids: ids, readObjectsType: readObjectsType)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return Array()
        }
    }
    
    public func deleteCollectionNonThrowing(
        readObjectsType: SwiftDataReadObjectsType<PersistObjectType>? = nil,
        shouldAssertWhenError: Bool = true
    ) -> [DataModelType] {
        
        do {
            return try deleteCollection(readObjectsType: readObjectsType)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return Array()
        }
    }
    
    public func writeObjectsNonThrowing(
        externalObjects: [ExternalObjectType],
        writeOption: PersistenceWriteOption?,
        readObjectsType: SwiftDataReadObjectsType<PersistObjectType>? = nil,
        shouldAssertWhenError: Bool = true
    ) -> [DataModelType] {
     
        do {
            return try writeObjects(externalObjects: externalObjects, writeOption: writeOption, readObjectsType: readObjectsType)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return Array()
        }
    }
}
