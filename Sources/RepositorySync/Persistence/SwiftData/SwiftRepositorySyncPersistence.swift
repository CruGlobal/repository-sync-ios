//
//  SwiftRepositorySyncPersistence.swift
//  godtools
//
//  Created by Levi Eggert on 9/23/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData
import Combine

@available(iOS 17.4, *)
public final class SwiftRepositorySyncPersistence<DataModelType, ExternalObjectType, PersistObjectType: IdentifiableSwiftDataObject>: Persistence {
    
    private let userInfoKeyPrependNotification: String = "RepositorySync.notificationKey.prepend"
    private let userInfoKeyEntityName: String = "RepositorySync.notificationKey.entityName"
    
    public let database: SwiftDatabase
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    public let entityName: String
    
    public init(database: SwiftDatabase, dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.database = database
        self.dataModelMapping = dataModelMapping
        
        if #available(iOS 18.0, *) {
            entityName = Schema.entityName(for: PersistObjectType.self)
        }
        else {
            // TODO: Can remove once supporting iOS 18 and up. ~Levi
            entityName = PersistObjectType.entityName
        }
    }
}

// MARK: - Observe

@available(iOS 17.4, *)
extension SwiftRepositorySyncPersistence {
    
    public func observeCollectionChangesPublisher() -> AnyPublisher<Void, Error> {
        
        return observeSwiftDataCollectionChangesPublisher()
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    private func observeSwiftDataCollectionChangesPublisher() -> AnyPublisher<Void, Never> {
                
        let swiftDatabaseRef: SwiftDatabase = self.database
        let swiftDatabaseEntityNameRef: String = self.entityName
        let userInfoKeyPrependNotification: String = self.userInfoKeyPrependNotification
        let userInfoKeyEntityName: String = self.userInfoKeyEntityName
        
        // NOTE: Prepends a notification on first observation in order to trigger changes on first observation.
        let prependNotification = Notification(
            name: ModelContext.didSave,
            object: swiftDatabaseRef.openContext(),
            userInfo: [
                userInfoKeyPrependNotification: true,
                userInfoKeyEntityName: swiftDatabaseEntityNameRef
            ]
        )
        
        return NotificationCenter
            .default
            .publisher(for: ModelContext.didSave)
            .prepend(prependNotification)
            .compactMap { (notification: Notification) in
                                                
                let swiftDatabaseConfigName: String = swiftDatabaseRef.configName
                let fromContextConfigurations: Set<ModelConfiguration> = (notification.object as? ModelContext)?.container.configurations ?? Set<ModelConfiguration>()
                let fromConfigNames: [String] = fromContextConfigurations.map { $0.name }
                let isSameContainer: Bool = fromConfigNames.contains(swiftDatabaseConfigName)
                
                let userInfo: [AnyHashable: Any] = notification.userInfo ?? Dictionary()
                let isPrepend: Bool = userInfo[userInfoKeyPrependNotification] as? Bool ?? false
                let prependEntityNameMatchesSwiftDatabaseEntityName: Bool = swiftDatabaseEntityNameRef == userInfo[userInfoKeyEntityName] as? String
                
                if isPrepend && prependEntityNameMatchesSwiftDatabaseEntityName && isSameContainer {
                    
                    return Void()
                }
                else if isSameContainer,
                        let changedEntityNamesSet = Self.getNotificationChangedEntityNames(notification: notification),
                        changedEntityNamesSet.contains(swiftDatabaseEntityNameRef) {
                    
                    return Void()
                }
                
                return nil
            }
            .eraseToAnyPublisher()
    }
    
    private static func getNotificationChangedEntityNames(notification: Notification) -> Set<String>? {
        
        let userInfo: [AnyHashable: Any]? = notification.userInfo
        
        guard let userInfo = userInfo else {
            return nil
        }
        
        let insertedIds = userInfo[
            ModelContext.NotificationKey.insertedIdentifiers.rawValue
        ] as? [PersistentIdentifier]
        ?? Array()
        
        let deletedIds = userInfo[
            ModelContext.NotificationKey.deletedIdentifiers.rawValue
        ] as? [PersistentIdentifier]
        ?? Array()
        
        let updatedIds = userInfo[
            ModelContext.NotificationKey.updatedIdentifiers.rawValue
        ] as? [PersistentIdentifier]
        ?? Array()
        
        let allIds: [PersistentIdentifier] = insertedIds + deletedIds + updatedIds
        
        guard allIds.count > 0 else {
            return nil
        }
        
        let entityNames: [String] = allIds.map {
            $0.entityName
        }
        
        let changedEntityNamesSet: Set<String> = Set(entityNames)
        
        return changedEntityNamesSet
    }
}

// MARK: Read

@available(iOS 17.4, *)
extension SwiftRepositorySyncPersistence {
    
    public func getObjectCount() throws -> Int {
        
        let context: ModelContext = database.openContext()
        
        return try database
            .getObjectCount(
                context: context,
                query: SwiftDatabaseQuery<PersistObjectType>(
                    fetchDescriptor: FetchDescriptor<PersistObjectType>()
                )
            )
    }
    
    public func getObject(id: String) throws -> DataModelType? {
        
        let context: ModelContext = database.openContext()
        
        let swiftObject: PersistObjectType? = try database.getObject(context: context, id: id)
        
        guard let swiftObject = swiftObject, let dataModel = dataModelMapping.toDataModel(persistObject: swiftObject) else {
            return nil
        }
        
        return dataModel
    }
    
    public func getObjects() throws -> [DataModelType] {
        
        return try getObjects(query: nil)
    }
    
    public func getObjects(query: SwiftDatabaseQuery<PersistObjectType>? = nil) throws -> [DataModelType] {
        
        let context: ModelContext = database.openContext()
        
        let objects: [PersistObjectType] = try database.getObjects(context: context, query: query)
        
        let dataModels: [DataModelType] = objects.compactMap { object in
            self.dataModelMapping.toDataModel(persistObject: object)
        }
        
        return dataModels
    }
    
    public func getObjects(ids: [String]) throws -> [DataModelType] {
        
        let context: ModelContext = database.openContext()
        
        let objects: [PersistObjectType] = try database.getObjects(context: context, ids: ids)
        
        let dataModels: [DataModelType] = objects.compactMap { object in
            self.dataModelMapping.toDataModel(persistObject: object)
        }
        
        return dataModels
    }
}

// MARK: - Write

@available(iOS 17.4, *)
extension SwiftRepositorySyncPersistence {
    
    private func writeObjects(externalObjects: [ExternalObjectType], deleteObjectsNotFoundInExternalObjects: Bool) throws {
        
        let context: ModelContext = self.database.openContext()
                    
        var objectsToAdd: [PersistObjectType] = Array()
        
        var objectsToRemove: [PersistObjectType]
        
        if deleteObjectsNotFoundInExternalObjects {
            // store all objects in the collection.
            objectsToRemove = try self.database.getObjects(context: context, query: nil)
        }
        else {
            objectsToRemove = Array()
        }
        
        for externalObject in externalObjects {

            guard let persistObject = self.dataModelMapping.toPersistObject(externalObject: externalObject) else {
                continue
            }
            
            objectsToAdd.append(persistObject)
            
            // added persist object can be removed from this list so it won't be deleted from the database.
            if deleteObjectsNotFoundInExternalObjects, let index = objectsToRemove.firstIndex(where: { $0.id == persistObject.id }) {
                objectsToRemove.remove(at: index)
            }
        }
        
        for object in objectsToAdd {
            context.insert(object)
        }
        
        for object in objectsToRemove {
            context.delete(object)
        }
        
        if context.hasChanges {
            try context.save()
        }
    }
    
    public func writeObjectsPublisher(writeClosure: @escaping (() -> [ExternalObjectType]), deleteObjectsNotFoundInExternalObjects: Bool) -> AnyPublisher<Void, any Error> {
        
        return Future { promise in
            
            DispatchQueue.global().async {
                
                do {
                    
                    let context: ModelContext = self.database.openContext()
                    
                    let externalObjects: [ExternalObjectType] = writeClosure()
                    
                    var objectsToAdd: [PersistObjectType] = Array()
                    
                    var objectsToRemove: [PersistObjectType]
                    
                    if deleteObjectsNotFoundInExternalObjects {
                        // store all objects in the collection.
                        objectsToRemove = try self.database.getObjects(context: context, query: nil)
                    }
                    else {
                        objectsToRemove = Array()
                    }
                    
                    for externalObject in externalObjects {

                        guard let persistObject = self.dataModelMapping.toPersistObject(externalObject: externalObject) else {
                            continue
                        }
                        
                        objectsToAdd.append(persistObject)
                        
                        // added persist object can be removed from this list so it won't be deleted from the database.
                        if deleteObjectsNotFoundInExternalObjects, let index = objectsToRemove.firstIndex(where: { $0.id == persistObject.id }) {
                            objectsToRemove.remove(at: index)
                        }
                    }
                    
                    for object in objectsToAdd {
                        context.insert(object)
                    }
                    
                    for object in objectsToRemove {
                        context.delete(object)
                    }
                    
                    if context.hasChanges {
                        try context.save()
                    }
    
                    promise(.success(Void()))
                }
                catch let error {
                    
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
