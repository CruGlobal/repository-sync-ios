//
//  SwiftDatabase.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/3/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
public final class SwiftDatabase: Sendable {
    
    public let container: ModelContainer
    public let configName: String
    public let configUrl: URL
    
    public init(modelConfiguration: ModelConfiguration, schema: Schema, migrationPlan: (any SchemaMigrationPlan.Type)?) throws {
                
        let container = try ModelContainer(
            for: schema,
            migrationPlan: migrationPlan,
            configurations: modelConfiguration
        )
        
        self.container = container
        
        configName = modelConfiguration.name
        configUrl = modelConfiguration.url
    }
    
    public func openContext(autosaveEnabled: Bool = false) -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = autosaveEnabled
        return context
    }
}

// MARK: - Read

@available(iOS 17.4, *)
extension SwiftDatabase {
    
    public func getFetchDescriptor<T: IdentifiableSwiftDataObject>(query: SwiftDatabaseQuery<T>?) -> FetchDescriptor<T> {
        
        return query?.fetchDescriptor ?? FetchDescriptor<T>()
    }
    
    public func getObjectCount<T: IdentifiableSwiftDataObject>(context: ModelContext, query: SwiftDatabaseQuery<T>) throws -> Int {
        
        return try context
            .fetchCount(getFetchDescriptor(query: query))
    }
    
    public func getObject<T: IdentifiableSwiftDataObject>(context: ModelContext, id: String) throws -> T? {
        
        let idPredicate = #Predicate<T> { object in
            object.id == id
        }
        
        let query = SwiftDatabaseQuery.filter(filter: idPredicate)
        
        return try getObjects(context: context, query: query).first
    }
    
    public func getObjects<T: IdentifiableSwiftDataObject>(context: ModelContext, ids: [String], sortBy: [SortDescriptor<T>]? = nil) throws -> [T] {
        
        let filter = #Predicate<T> { object in
            ids.contains(object.id)
        }
        
        let query = SwiftDatabaseQuery(
            filter: filter,
            sortBy: sortBy
        )
        
        return try getObjects(context: context, query: query)
    }
    
    public func getObjects<T: IdentifiableSwiftDataObject>(context: ModelContext, query: SwiftDatabaseQuery<T>?) throws -> [T] {
        
        let objects: [T] = try context.fetch(getFetchDescriptor(query: query))
        
        return objects
    }
}

// MARK: - Write

@available(iOS 17.4, *)
extension SwiftDatabase {
    
    public func writeObjects(context: ModelContext, objects: [any IdentifiableSwiftDataObject], deleteObjects: [any IdentifiableSwiftDataObject]? = nil) throws {
        
        for object in objects {
            context.insert(object)
        }
        
        if let deleteObjects = deleteObjects, deleteObjects.count > 0 {
            for object in deleteObjects {
                context.delete(object)
            }
        }
        
        guard context.hasChanges else {
            return
        }
        
        try context.save()
    }
}

// MARK: - Delete

@available(iOS 17.4, *)
extension SwiftDatabase {
    
    public func deleteObjects(context: ModelContext, objects: [any IdentifiableSwiftDataObject]) throws {
        
        guard objects.count > 0 else {
            return
        }
        
        for object in objects {
            context.delete(object)
        }
        
        try context.save()
    }
}
