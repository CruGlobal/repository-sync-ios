//
//  SwiftDataRead+NonThrowing.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/7/26.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
extension SwiftDataRead {
    
    public func objectCountNonThrowing<T: IdentifiableSwiftDataObject>(context: ModelContext, query: SwiftDatabaseQuery<T>, shouldAssertWhenError: Bool = true) -> Int {
        do {
            return try objectCount(context: context, query: query)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return 0
        }
    }
    
    public func objectNonThrowing<T: IdentifiableSwiftDataObject>(context: ModelContext, id: String, shouldAssertWhenError: Bool = true) -> T? {
        do {
            return try object(context: context, id: id)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return nil
        }
    }
    
    public func objectsNonThrowing<T: IdentifiableSwiftDataObject>(context: ModelContext, ids: Set<String>, sortBy: [SortDescriptor<T>]?, shouldAssertWhenError: Bool = true) -> [T] {
        do {
            return try objects(context: context, ids: ids, sortBy: sortBy)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return Array()
        }
    }
    
    public func objectsNonThrowing<T: IdentifiableSwiftDataObject>(context: ModelContext, query: SwiftDatabaseQuery<T>?, shouldAssertWhenError: Bool = true) -> [T] {
        do {
            return try objects(context: context, query: query)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return Array()
        }
    }
    
    public func getObjectsNonThrowing<T: IdentifiableSwiftDataObject>(context: ModelContext, readObjectsType: SwiftDataReadObjectsType<T>, shouldAssertWhenError: Bool = true) -> [T] {
        do {
            return try getObjects(context: context, readObjectsType: readObjectsType)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return Array()
        }
    }
}
