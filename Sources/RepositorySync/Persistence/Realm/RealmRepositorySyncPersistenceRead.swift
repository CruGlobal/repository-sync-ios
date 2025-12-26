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
    
    private func getObjectsAsyncClosure(getObjectsType: GetObjectsType, query: RealmDatabaseQuery?, completion: @escaping ((_ result: Result<[DataModelType], Error>) -> Void)) {
        
        DispatchQueue.global().async {
            
            do {
                
                let realm: Realm = try self.database.openRealm()
                
                let getObjectsByType: RealmRepositorySyncGetObjects<PersistObjectType> = RealmRepositorySyncGetObjects()
                
                let persistObjects: [PersistObjectType] = try getObjectsByType.getObjects(
                    realm: realm,
                    getObjectsType: getObjectsType,
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
    
    @MainActor public func getObjectsAsync(getObjectsType: GetObjectsType, query: RealmDatabaseQuery?) async throws -> [DataModelType] {
        
        return try await withCheckedThrowingContinuation { continuation in
            getObjectsAsyncClosure(getObjectsType: getObjectsType, query: query) { (result: Result<[DataModelType], Error>) in
                switch result {
                case .success(let dataModels):
                    continuation.resume(returning: dataModels)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    @MainActor public func getObjectsPublisher(getObjectsType: GetObjectsType, query: RealmDatabaseQuery?) -> AnyPublisher<[DataModelType], Error> {
        
        return Future { promise in
            
            Task {
                
                do {
                    let dataModels = try await self.getObjectsAsync(getObjectsType: getObjectsType, query: query)
                    
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
