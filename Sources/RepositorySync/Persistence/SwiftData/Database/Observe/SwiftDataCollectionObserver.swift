//
//  SwiftDataCollectionObserver.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData
import Combine

@available(iOS 17.4, *)
public final class SwiftDataCollectionObserver<PersistObjectType: IdentifiableSwiftDataObject>: Sendable {
    
    private let userInfoKeyPrependNotification: String = "RepositorySync.notificationKey.prepend"
    private let userInfoKeyEntityName: String = "RepositorySync.notificationKey.entityName"
    
    public let entityName: String
    
    public init() {
        
        if #available(iOS 18.0, *) {
            entityName = Schema.entityName(for: PersistObjectType.self)
        }
        else {
            // TODO: Can remove once supporting iOS 18 and up. ~Levi
            entityName = PersistObjectType.entityName
        }
    }

    public func observeCollectionChangesPublisher(database: SwiftDatabase) -> AnyPublisher<Void, Error> {
        
        return observeSwiftDataCollectionChangesPublisher(database: database)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    private func observeSwiftDataCollectionChangesPublisher(database: SwiftDatabase) -> AnyPublisher<Void, Never> {
                
        let swiftDatabaseRef: SwiftDatabase = database
        let swiftDatabaseEntityNameRef: String = entityName
        let userInfoKeyPrependNotification: String = userInfoKeyPrependNotification
        let userInfoKeyEntityName: String = userInfoKeyEntityName
        
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
