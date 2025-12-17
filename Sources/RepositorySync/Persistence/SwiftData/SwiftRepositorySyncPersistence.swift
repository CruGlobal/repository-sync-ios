//
//  SwiftRepositorySyncPersistence.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/3/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData
import Combine

@available(iOS 17.4, *)
public final class SwiftRepositorySyncPersistence<DataModelType, ExternalObjectType, PersistObjectType: IdentifiableSwiftDataObject>: Persistence {
    
    private let serialQueue: DispatchQueue = DispatchQueue(label: "swiftdatabase.serial_queue")
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
    
    @MainActor public func observeCollectionChangesPublisher() -> AnyPublisher<Void, Error> {
        
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
                let swiftDatabaseUrl: URL = swiftDatabaseRef.configUrl
                let fromContainer: ModelContainer? = (notification.object as? ModelContext)?.container
                let fromContextConfigurations: Set<ModelConfiguration> = fromContainer?.configurations ?? Set<ModelConfiguration>()
                let fromConfigNames: [String] = fromContextConfigurations.map { $0.name }
                let fromConfigUrls: [URL] = fromContextConfigurations.map { $0.url }
                let isSameContainer: Bool = fromConfigNames.contains(swiftDatabaseConfigName) && fromConfigUrls.contains(swiftDatabaseUrl)
                
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
    
    public func getObjects(getObjectsType: GetObjectsType) throws -> [DataModelType] {
        
        // TODO: Can this be done in the background? ~Levi
                
        let context: ModelContext = database.openContext()
        
        return try getObjects(context: context, getObjectsType: getObjectsType)
    }
    
    public func getObjects(context: ModelContext, getObjectsType: GetObjectsType) throws -> [DataModelType] {
        
        // TODO: Can this be done in the background? ~Levi
        
        let persistObjects: [PersistObjectType]
                
        switch getObjectsType {
            
        case .allObjects:
            persistObjects = try database.getObjects(context: context, query: nil)
            
        case .object(let id):
            
            let object: PersistObjectType? = try database.getObject(context: context, id: id)
            
            if let object = object {
                persistObjects = [object]
            }
            else {
                persistObjects = []
            }
        }
        
        return mapPersistObjects(persistObjects: persistObjects)
    }
    
    public func mapPersistObjects(persistObjects: [PersistObjectType]) -> [DataModelType] {
        
        // TODO: Can this be done in the background? ~Levi
        
        let dataModels: [DataModelType] = persistObjects.compactMap { object in
            self.dataModelMapping.toDataModel(persistObject: object)
        }
        
        return dataModels
    }
}

// MARK: - Write

@available(iOS 17.4, *)
extension SwiftRepositorySyncPersistence {
    
    @MainActor public func writeObjectsAsync(writeClosure: @escaping ((_ context: ModelContext) -> SwiftDatabaseWrite), completion: @escaping ((_ context: ModelContext?, _ error: Error?) -> Void)) {
        
        let database: SwiftDatabase = self.database
        let container: ModelContainer = database.container
        
        serialQueue.async {
            autoreleasepool {
             
                let context = ModelContext(container)
                context.autosaveEnabled = false
                
                let write: SwiftDatabaseWrite = writeClosure(context)
                
                if let error = write.error {
                    completion(nil, error)
                    return
                }
                
                do {
                    
                    try database.writeObjects(
                        context: context,
                        objects: write.updateObjects,
                        deleteObjects: write.deleteObjects
                    )

                    completion(context, nil)
                }
                catch let error {
                    completion(nil, error)
                }
            }
        }
    }
    
    @MainActor public func writeObjectsPublisher(externalObjects: [ExternalObjectType], deleteObjectsNotFoundInExternalObjects: Bool, getObjectsType: GetObjectsType) -> AnyPublisher<[DataModelType], Error> {
        
        return Future { [weak self] promise in
            
            guard let weakSelf = self else {
                promise(.success([]))
                return
            }
            
            weakSelf.writeObjectsAsync(writeClosure: { (context: ModelContext) in
                
                do {
                    
                    var objectsToAdd: [PersistObjectType] = Array()
                    
                    var objectsToRemove: [PersistObjectType] = Array()
                    
                    if deleteObjectsNotFoundInExternalObjects, let weakSelf = self {
                        // store all objects in the collection.
                        objectsToRemove = try weakSelf.database.getObjects(context: context, query: nil)
                    }
                    
                    for externalObject in externalObjects {

                        guard let persistObject = self?.dataModelMapping.toPersistObject(externalObject: externalObject) else {
                            continue
                        }
                        
                        objectsToAdd.append(persistObject)
                        
                        // added persist object can be removed from this list so it won't be deleted from the database.
                        if deleteObjectsNotFoundInExternalObjects, let index = objectsToRemove.firstIndex(where: { $0.id == persistObject.id }) {
                            objectsToRemove.remove(at: index)
                        }
                    }
                    
                    return SwiftDatabaseWrite(
                        updateObjects: objectsToAdd,
                        deleteObjects: objectsToRemove
                    )
                }
                catch let error {
                    
                    return SwiftDatabaseWrite(error: error)
                }
                
            }, completion: { (context: ModelContext?, error: Error?) in
                
                let dataModels: [DataModelType]
                var failure: Error? = error
                
                if let context = context {
                    
                    do {
                        dataModels = try weakSelf.getObjects(context: context, getObjectsType: getObjectsType)
                    }
                    catch let error {
                        dataModels = Array()
                        failure = error
                    }
                }
                else {
                    dataModels = Array()
                }
                
                DispatchQueue.main.async {
                    if let error = failure {
                        promise(.failure(error))
                    }
                    else {
                        promise(.success(dataModels))
                    }
                }
            })
        }
        .eraseToAnyPublisher()
    }
}
