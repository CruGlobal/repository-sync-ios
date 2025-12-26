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
        
        let idPredicate = #Predicate<T> { object in
            object.id == id
        }
        
        let query = SwiftDatabaseQuery.filter(filter: idPredicate)
        
        return try objects(context: context, query: query).first
    }
    
    public func objects<T: IdentifiableSwiftDataObject>(context: ModelContext, ids: [String], sortBy: [SortDescriptor<T>]?) throws -> [T] {
        
        let filter = #Predicate<T> { object in
            ids.contains(object.id)
        }
        
        let query = SwiftDatabaseQuery(
            filter: filter,
            sortBy: sortBy
        )
        
        return try objects(context: context, query: query)
    }
    
    public func objects<T: IdentifiableSwiftDataObject>(context: ModelContext, query: SwiftDatabaseQuery<T>?) throws -> [T] {
        
        let objects: [T] = try context.fetch(fetchDescriptor(query: query))
        
        return objects
    }
}
