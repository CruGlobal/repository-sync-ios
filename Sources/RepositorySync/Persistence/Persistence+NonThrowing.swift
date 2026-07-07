//
//  Persistence+NonThrowing.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/7/26.
//

import Foundation
import Combine

extension Persistence {
    
    public func getObjectCountNonThrowing(shouldAssertWhenError: Bool = true) -> Int {
        do {
            return try getObjectCount()
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return 0
        }
    }
    
    public func getDataModelNonThrowing(id: String, shouldAssertWhenError: Bool = true) -> DataModelType? {
        do {
            return try getDataModel(id: id)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return nil
        }
    }
    
    public func getDataModelsNonThrowing(shouldAssertWhenError: Bool = true) async -> [DataModelType] {
        do {
            return try await getDataModels()
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return Array()
        }
    }
    
    public func getDataModelsNonThrowing(getOption: PersistenceGetOption, shouldAssertWhenError: Bool = true) async -> [DataModelType] {
        do {
            return try await getDataModels(getOption: getOption)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return Array()
        }
    }
    
    public func writeObjectsNonThrowing(externalObjects: [ExternalObjectType], shouldAssertWhenError: Bool = true) async {
        do {
            try await writeObjects(externalObjects: externalObjects)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
        }
    }
    
    public func writeObjectsNonThrowing(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getOption: PersistenceGetOption?, shouldAssertWhenError: Bool = true) async -> [DataModelType]{
        do {
            return try await writeObjects(externalObjects: externalObjects, writeOption: writeOption, getOption: getOption)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return Array()
        }
    }
    
    public func deleteCollectionNonThrowing(shouldAssertWhenError: Bool = true) async {
        do {
            try await deleteCollection()
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
        }
    }
    
    public func deleteObjectsByIdsNonThrowing(ids: Set<String>, getOption: PersistenceGetOption?, shouldAssertWhenError: Bool = true) async -> [DataModelType] {
        do {
            return try await deleteObjectsByIds(ids: ids, getOption: getOption)
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return Array()
        }
    }
    
    @MainActor public func observeCollectionChangesNonThrowingPublisher(shouldAssertWhenError: Bool = true) -> AnyPublisher<Void, Never> {
        return observeCollectionChangesPublisher()
            .catch { (error: Error) in
                if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
                return Just(Void())
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
