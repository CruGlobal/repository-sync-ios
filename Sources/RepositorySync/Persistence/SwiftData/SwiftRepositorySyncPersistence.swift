//
//  SwiftRepositorySyncPersistence.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData
import Combine

@available(iOS 17.4, *)
public final class SwiftRepositorySyncPersistence<DataModelType, ExternalObjectType: Sendable, PersistObjectType: IdentifiableSwiftDataObject>: Persistence {
    
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
                                                
                let swiftDatabaseConfigName: String = swiftDatabaseRef.container.configName
                let swiftDatabaseUrl: URL = swiftDatabaseRef.container.configUrl
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
    
    @MainActor public func getObjectCount() throws -> Int {
        
        let context: ModelContext = database.openContext()
        
        return try database
            .read.objectCount(
                context: context,
                query: SwiftDatabaseQuery<PersistObjectType>(
                    fetchDescriptor: FetchDescriptor<PersistObjectType>()
                )
            )
    }
    
    @MainActor public func getObjectsAsync(getObjectsType: GetObjectsType) async throws -> [DataModelType] {
        
        return try await getObjectsAsync(getObjectsType: getObjectsType, query: nil)
    }
    
    @MainActor public func getObjectsAsync(getObjectsType: GetObjectsType, query: SwiftDatabaseQuery<PersistObjectType>?) async throws -> [DataModelType] {
        
        return Array()
    }
    
    @MainActor public func getObjectsPublisher(getObjectsType: GetObjectsType) -> AnyPublisher<[DataModelType], Error> {
        
        return getObjectsPublisher(getObjectsType: getObjectsType, query: nil)
    }
    
    @MainActor public func getObjectsPublisher(getObjectsType: GetObjectsType, query: SwiftDatabaseQuery<PersistObjectType>?) -> AnyPublisher<[DataModelType], Error> {
        
        return Future { promise in
         
            do {
             
                let dataModels: [DataModelType] = try self.getObjects(getObjectsType: getObjectsType, query: query)
                promise(.success(dataModels))
            }
            catch let error {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func getObjects(getObjectsType: GetObjectsType, query: SwiftDatabaseQuery<PersistObjectType>?) throws -> [DataModelType] {
        
        // TODO: Can this be done in the background? ~Levi
                
        let context: ModelContext = database.openContext()
        
        return try getObjects(context: context, getObjectsType: getObjectsType, query: query)
    }
    
    private func getObjects(context: ModelContext, getObjectsType: GetObjectsType, query: SwiftDatabaseQuery<PersistObjectType>?) throws -> [DataModelType] {
        
        // TODO: Can this be done in the background? ~Levi
        
        let persistObjects: [PersistObjectType]
                
        switch getObjectsType {
            
        case .allObjects:
            persistObjects = try database.read.objects(context: context, query: query)
            
        case .object(let id):
            
            let object: PersistObjectType? = try database.read.object(context: context, id: id)
            
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
    
    @MainActor public func writeObjectsAsync(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?) async throws -> [DataModelType] {
        
        return Array()
    }
    
    @MainActor public func writeObjectsAsync(writeClosure: @escaping ((_ context: ModelContext) -> SwiftPersistenceWrite), completion: @escaping ((_ context: ModelContext?, _ error: Error?) -> Void)) {
        
        let database: SwiftDatabase = self.database
        let container: ModelContainer = database.container.modelContainer
        
        serialQueue.async {
            autoreleasepool {
             
                let context = ModelContext(container)
                context.autosaveEnabled = false
                
                let write: SwiftPersistenceWrite = writeClosure(context)
                            
                do {
                    
                    try database.write.objects(
                        context: context,
                        deleteObjects: write.deleteObjects,
                        insertObjects: write.insertObjects
                    )

                    completion(context, nil)
                }
                catch let error {
                    completion(nil, error)
                }
            }
        }
    }
    
    @MainActor public func writeObjectsPublisher(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?) -> AnyPublisher<[DataModelType], Error> {
        
        return Future { [weak self] promise in
            
            guard let weakSelf = self else {
                promise(.success([]))
                return
            }
            
            weakSelf.writeObjectsAsync(writeClosure: { (context: ModelContext) in
                
                var objectsToAdd: [PersistObjectType] = Array()
                
                for externalObject in externalObjects {

                    guard let persistObject = self?.dataModelMapping.toPersistObject(externalObject: externalObject) else {
                        continue
                    }
                    
                    objectsToAdd.append(persistObject)
                }
                
                return SwiftPersistenceWrite(
                    deleteObjects: nil,
                    insertObjects: objectsToAdd
                )
                
            }, completion: { (context: ModelContext?, error: Error?) in
                
                let dataModels: [DataModelType]
                var failure: Error? = error
                
                if let context = context, let getObjectsType = getObjectsType {
                    
                    do {
                        dataModels = try weakSelf.getObjects(context: context, getObjectsType: getObjectsType, query: nil)
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
