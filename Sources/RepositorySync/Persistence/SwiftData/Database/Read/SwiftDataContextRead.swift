//
//  SwiftDataContextRead.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
public final class SwiftDataContextRead {
    
    public let context: ModelContext
    public let read: SwiftDataRead = SwiftDataRead()
    
    public init(context: ModelContext) {
        
        self.context = context
    }
    
    public func objectCount<T: IdentifiableSwiftDataObject>(query: SwiftDatabaseQuery<T>) throws -> Int {
        return try read.objectCount(context: context, query: query)
    }
    
    public func object<T: IdentifiableSwiftDataObject>(id: String) throws -> T? {
        return try read.object(context: context, id: id)
    }
    
    public func objects<T: IdentifiableSwiftDataObject>(ids: [String], sortBy: [SortDescriptor<T>]?) throws -> [T] {
        return try read.objects(context: context, ids: ids, sortBy: sortBy)
    }
    
    public func objects<T: IdentifiableSwiftDataObject>(query: SwiftDatabaseQuery<T>?) throws -> [T] {
        return try read.objects(context: context, query: query)
    }
}
