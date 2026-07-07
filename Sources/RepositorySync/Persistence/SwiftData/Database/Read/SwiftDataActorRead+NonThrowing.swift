//
//  SwiftDataActorRead+NonThrowing.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/7/26.
//

import Foundation

@available(iOS 17.4, *)
extension SwiftDataActorRead {
    
    public func getDataModelNonThrowing(id: String, shouldAssertWhenError: Bool = true) -> DataModelType? {
        do {
            return try getDataModel(id: id)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return nil
        }
    }
    
    public func getDataModelsNonThrowing(ids: Set<String>, sortBy: [SortDescriptor<PersistObjectType>]?, shouldAssertWhenError: Bool = true) -> [DataModelType] {
        do {
            return try getDataModels(ids: ids, sortBy: sortBy)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return Array()
        }
    }
    
    public func getDataModelsNonThrowing(query: SwiftDatabaseQuery<PersistObjectType>?, shouldAssertWhenError: Bool = true) -> [DataModelType] {
        do {
            return try getDataModels(query: query)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return Array()
        }
    }
    
    public func getDataModelsNonThrowing(readObjectsType: SwiftDataReadObjectsType<PersistObjectType>, shouldAssertWhenError: Bool = true) -> [DataModelType] {
        do {
            return try getDataModels(readObjectsType: readObjectsType)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return Array()
        }
    }
}
