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
public final class SwiftRepositorySyncPersistence<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableSwiftDataObject>: Persistence {
    
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
    
    @MainActor private func getObjectsBackground(getObjectsType: GetObjectsType, query: SwiftDatabaseQuery<PersistObjectType>?, completion: @escaping ((_ result: Result<[DataModelType], Error>) -> Void)) {
        
        DispatchQueue.global().async {
            do {
                let context: ModelContext = self.database.openContext()
                let dataModels: [DataModelType] = try self.getObjects(context: context, getObjectsType: getObjectsType, query: query)
                DispatchQueue.main.async {
                    completion(.success(dataModels))
                }
            }
            catch let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    @MainActor public func getObjectsAsync(getObjectsType: GetObjectsType) async throws -> [DataModelType] {
        
        return try await getObjectsAsync(getObjectsType: getObjectsType, query: nil)
    }
    
    @MainActor public func getObjectsAsync(getObjectsType: GetObjectsType, query: SwiftDatabaseQuery<PersistObjectType>?) async throws -> [DataModelType] {
        
        return try await withCheckedThrowingContinuation { continuation in
            getObjectsBackground(getObjectsType: getObjectsType, query: query) { (result: Result<[DataModelType], Error>) in
                switch result {
                case .success(let dataModels):
                    continuation.resume(returning: dataModels)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
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
                        
        let context: ModelContext = database.openContext()
        
        return try getObjects(context: context, getObjectsType: getObjectsType, query: query)
    }
    
    private func getObjects(context: ModelContext, getObjectsType: GetObjectsType, query: SwiftDatabaseQuery<PersistObjectType>?) throws -> [DataModelType] {
           
        // TODO: Should an error be thrown if GetObjectsType is other than all and query is provided since query won't apply to object id? ~Levi
        
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
                
        let dataModels: [DataModelType] = persistObjects.compactMap { object in
            self.dataModelMapping.toDataModel(persistObject: object)
        }
        
        return dataModels
    }
    
    private func mapExternalObjects(externalObjects: [ExternalObjectType]) -> [PersistObjectType] {
        
        return externalObjects.compactMap {
            self.dataModelMapping.toPersistObject(externalObject: $0)
        }
    }
}

// MARK: - Write

@available(iOS 17.4, *)
extension SwiftRepositorySyncPersistence {

    @MainActor private func writeObjectsBackground(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?, completion: @escaping ((_ result: Result<[DataModelType], Error>) -> Void)) {
        
        DispatchQueue.global().async {
            
            do {
                
                let objectsToAdd: [PersistObjectType] = self.mapExternalObjects(externalObjects: externalObjects)
                
                try self.database.asyncWrite.objects(writeObjects: WriteSwiftObjects(deleteObjects: nil, insertObjects: objectsToAdd))
                
                let dataModels: [DataModelType]
                
                if let getObjectsType = getObjectsType {
                    let context: ModelContext = self.database.asyncWrite.context
                    dataModels = try self.getObjects(context: context, getObjectsType: getObjectsType, query: nil)
                }
                else {
                    dataModels = Array()
                }
                
                DispatchQueue.main.async {
                    completion(.success(dataModels))
                }
            }
            catch let error {
                
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    @MainActor public func writeObjectsAsync(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?) async throws -> [DataModelType] {
        
        return try await withCheckedThrowingContinuation { continuation in
            writeObjectsBackground(externalObjects: externalObjects, getObjectsType: getObjectsType) { (result: Result<[DataModelType], Error>) in
                switch result {
                case .success(let dataModels):
                    continuation.resume(returning: dataModels)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    @MainActor public func writeObjectsPublisher(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?) -> AnyPublisher<[DataModelType], any Error> {
                
        return Future { promise in
            
            self.writeObjectsBackground(externalObjects: externalObjects, getObjectsType: getObjectsType) { result in
                switch result {
                case .success(let dataModels):
                    promise(.success(dataModels))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
