//
//  RealmRepositorySyncPersistence+NonThrowing.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/7/26.
//

import Foundation

extension RealmRepositorySyncPersistence {
    
    public func newActorReadNonThrowing(
        shouldAssertWhenError: Bool = true
    ) async throws -> RealmActorRead<DataModelType, ExternalObjectType, PersistObjectType>? {
        do {
            return try await newActorRead()
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return nil
        }
    }
    
    public func newActorWriteNonThrowing(
        shouldAssertWhenError: Bool = true
    ) async throws -> RealmActorWrite<DataModelType, ExternalObjectType, PersistObjectType>? {
        do {
            return try await newActorWrite()
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return nil
        }
    }
}
