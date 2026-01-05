//
//  RealmRepositorySyncPersistenceRead.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift
import Combine

public final class RealmRepositorySyncPersistenceRead<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableRealmObject> {
    
    public let database: RealmDatabase
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(database: RealmDatabase, dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.database = database
        self.dataModelMapping = dataModelMapping
    }
    
    @MainActor public func getDataModel(id: String) throws -> DataModelType? {
        
        let realm: Realm = try database.openRealm()
        
        let getObjectsByType = RealmRepositorySyncGetObjects<PersistObjectType>()
        
        let persistObjects: [PersistObjectType] = try getObjectsByType.getObjects(
            realm: realm,
            getOption: .object(id: id),
            query: nil
        )
        
        guard let persistObject = persistObjects.first else {
            return nil
        }
        
        return dataModelMapping.toDataModel(persistObject: persistObject)
    }
    
    @available(*, deprecated)
    @MainActor public func getDataModelNonThrowing(id: String) -> DataModelType? {
        
        do {
            return try getDataModel(id: id)
        }
        catch _ {
            return nil
        }
    }
    
    private func getDataModelsAsyncClosure(getOption: PersistenceGetOption, query: RealmDatabaseQuery?, completion: @escaping ((_ result: Result<[DataModelType], Error>) -> Void)) {
        
        DispatchQueue.global().async {
            
            do {
                
                let realm: Realm = try self.database.openRealm()
                
                let getObjectsByType = RealmRepositorySyncGetObjects<PersistObjectType>()
                
                let persistObjects: [PersistObjectType] = try getObjectsByType.getObjects(
                    realm: realm,
                    getOption: getOption,
                    query: query
                )

                let dataModels: [DataModelType] = persistObjects.compactMap { object in
                    self.dataModelMapping.toDataModel(persistObject: object)
                }
                
                completion(.success(dataModels))
            }
            catch let error {
                completion(.failure(error))
            }
        }
    }
    
    @MainActor public func getDataModelsAsync(getOption: PersistenceGetOption, query: RealmDatabaseQuery?) async throws -> [DataModelType] {
        
        return try await withCheckedThrowingContinuation { continuation in
            getDataModelsAsyncClosure(getOption: getOption, query: query) { (result: Result<[DataModelType], Error>) in
                switch result {
                case .success(let dataModels):
                    continuation.resume(returning: dataModels)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    @MainActor public func getDataModelsPublisher(getOption: PersistenceGetOption, query: RealmDatabaseQuery?) -> AnyPublisher<[DataModelType], Error> {
        
        return Future { promise in
            
            Task {
                
                do {
                    let dataModels = try await self.getDataModelsAsync(getOption: getOption, query: query)
                    
                    promise(.success(dataModels))
                }
                catch let error {
                    
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
