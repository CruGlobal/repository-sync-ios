//
//  RealmRepositorySyncPersistenceWrite.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift
import Combine

public final class RealmRepositorySyncPersistenceWrite<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableRealmObject> {
    
    public let asyncWrite: RealmDataAsyncWrite
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(asyncWrite: RealmDataAsyncWrite, dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.asyncWrite = asyncWrite
        self.dataModelMapping = dataModelMapping
    }
    
    private func writeObjectsAsyncClosure(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?, completion: @escaping ((_ result: Result<[DataModelType], Error>) -> Void)) {
     
        asyncWrite.write(writeAsync: { (realm: Realm) in
            
            do {
                
                for externalObject in externalObjects {
                    
                    guard let persistObject = self.dataModelMapping.toPersistObject(externalObject: externalObject) else {
                        continue
                    }
                    
                    realm.add(persistObject, update: .modified)
                }
                
                guard let getObjectsType = getObjectsType else {
                    completion(.success(Array()))
                    return
                }
                  
                let getObjectsByType: RealmRepositorySyncGetObjects<PersistObjectType> = RealmRepositorySyncGetObjects()
                
                let getObjects: [PersistObjectType] = try getObjectsByType.getObjects(
                    realm: realm,
                    getObjectsType: getObjectsType,
                    query: nil
                )
                
                let dataModels: [DataModelType] = getObjects.compactMap { object in
                    self.dataModelMapping.toDataModel(persistObject: object)
                }
                
                completion(.success(dataModels))
            }
            catch let error {
                
                completion(.failure(error))
            }
            
        }, writeError: { (error: Error) in
            
            completion(.failure(error))
        })
    }
    
    @MainActor public func writeObjectsAsync(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?) async throws -> [DataModelType] {
        
        return try await withCheckedThrowingContinuation { continuation in
            self.writeObjectsAsyncClosure(externalObjects: externalObjects, getObjectsType: getObjectsType) { result in
                switch result {
                case .success(let dataModels):
                    continuation.resume(returning: dataModels)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    @MainActor func writeObjectsPublisher(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?) -> AnyPublisher<[DataModelType], Error> {
                        
        return Future { promise in
            
            Task {
                
                do {
                    
                    let dataModels: [DataModelType] = try await self.writeObjectsAsync(externalObjects: externalObjects, getObjectsType: getObjectsType)
                    
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
