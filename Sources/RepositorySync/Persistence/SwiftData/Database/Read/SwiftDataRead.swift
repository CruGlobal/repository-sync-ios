//
//  SwiftDataRead.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
public final class SwiftDataRead: Sendable {
    
    public init() {
        
    }
    
    public func fetchDescriptor<T: IdentifiableSwiftDataObject>(query: SwiftDatabaseQuery<T>?) -> FetchDescriptor<T> {
        
        return query?.fetchDescriptor ?? FetchDescriptor<T>()
    }
    
    public func objectCount<T: IdentifiableSwiftDataObject>(context: ModelContext, query: SwiftDatabaseQuery<T>) throws -> Int {
        
        return try context
            .fetchCount(fetchDescriptor(query: query))
    }
    
    public func object<T: IdentifiableSwiftDataObject>(context: ModelContext, id: String) throws -> T? {

        let query = SwiftDatabaseQuery.filter(filter: T.idPredicate(id: id))

        return try objects(context: context, query: query).first
    }

    public func objects<T: IdentifiableSwiftDataObject>(context: ModelContext, ids: Set<String>, sortBy: [SortDescriptor<T>]?) throws -> [T] {

        let query = SwiftDatabaseQuery(
            filter: T.idsPredicate(ids: ids),
            sortBy: sortBy
        )

        return try objects(context: context, query: query)
    }
    
    public func objects<T: IdentifiableSwiftDataObject>(context: ModelContext, query: SwiftDatabaseQuery<T>?) throws -> [T] {
        
        let objects: [T] = try context.fetch(fetchDescriptor(query: query))
        
        return objects
    }
    
    public func getObjects<T: IdentifiableSwiftDataObject>(context: ModelContext, readObjectsType: SwiftDataReadObjectsType<T>) throws -> [T] {
                
        let persistObjects: [T]
                
        switch readObjectsType {
            
        case .allObjects:
            persistObjects = try objects(context: context, query: nil)
            
        case .object(let id):
            
            let object: T? = try object(context: context, id: id)
            
            if let object = object {
                persistObjects = [object]
            }
            else {
                persistObjects = []
            }
            
        case .objectsByIds(let ids, let sortBy):
            persistObjects = try objects(context: context, ids: ids, sortBy: sortBy)
            
        case .objectsByQuery(let query):
            persistObjects = try objects(context: context, query: query)
        }
        
        return persistObjects
    }
}
