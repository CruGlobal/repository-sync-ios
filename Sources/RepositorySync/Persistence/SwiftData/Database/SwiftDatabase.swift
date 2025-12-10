//
//  SwiftDatabase.swift
//  godtools
//
//  Created by Levi Eggert on 9/19/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData
import Combine

@available(iOS 17.4, *)
public final class SwiftDatabase {
    
    private let serialQueue: DispatchQueue = DispatchQueue(label: "swiftdatabase.serial_queue")
    private let container: ModelContainer
    
    public let configName: String
    
    public init(modelConfiguration: ModelConfiguration, schema: Schema, migrationPlan: (any SchemaMigrationPlan.Type)?) throws {
                
        let container = try ModelContainer(
            for: schema,
            migrationPlan: migrationPlan,
            configurations: modelConfiguration
        )
        
        self.container = container
        
        configName = modelConfiguration.name
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

    public func writeObjectsPublisher(writeClosure: @escaping ((_ context: ModelContext) -> SwiftDatabaseWrite)) -> AnyPublisher<Void, Error> {
        
        
//        let context: ModelContext = openContext()
//        
//        let write: SwiftDatabaseWrite = writeClosure(context)
//        
//        if let error = write.error {
//            return Fail(error: error)
//                .eraseToAnyPublisher()
//        }
//        
//        do {
//            
//            try self.writeObjects(
//                context: context,
//                objects: write.updateObjects,
//                deleteObjects: write.deleteObjects
//            )
//
//            return Just(Void())
//                .setFailureType(to: Error.self)
//                .eraseToAnyPublisher()
//        }
//        catch let error {
//            return Fail(error: error)
//                .eraseToAnyPublisher()
//        }
        
        return Future { promise in
            
            self.writeObjectsSerialAsync(
                writeClosure: writeClosure,
                completion: { (error: Error?) in
                    
                    if let error = error {
                        promise(.failure(error))
                    }
                    else {
                        promise(.success(Void()))
                    }
                }
            )
        }
        .eraseToAnyPublisher()
    }
    
    public func writeObjectsSerialAsync(writeClosure: @escaping ((_ context: ModelContext) -> SwiftDatabaseWrite), completion: @escaping ((_ error: Error?) -> Void)) {
        
        let container: ModelContainer = self.container
        
        serialQueue.async {
            
            let context = ModelContext(container)
            context.autosaveEnabled = false
            
            let write: SwiftDatabaseWrite = writeClosure(context)
            
            if let error = write.error {
                completion(error)
                return
            }
            
            do {
                
                try self.writeObjects(
                    context: context,
                    objects: write.updateObjects,
                    deleteObjects: write.deleteObjects
                )

                completion(nil)
            }
            catch let error {
                completion(error)
            }
        }
    }
    
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
