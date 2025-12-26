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
    
    private func writeObjectsAsyncClosure(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getObjectsType: GetObjectsType?, completion: @escaping ((_ result: Result<[DataModelType], Error>) -> Void)) {
     
        asyncWrite.write(writeAsync: { (realm: Realm) in
            
            do {
                
                var objectsToDelete: [PersistObjectType] = Array()
                var objectsToInsert: [PersistObjectType] = Array()
                
                if let writeOption = writeOption {
                    
                    switch writeOption {
                    case .deleteObjectsNotInExternal:
                        objectsToDelete = RealmDataRead().objects(realm: realm, query: nil)
                    }
                }
                
                for externalObject in externalObjects {
                    
                    guard let dataModel = self.dataModelMapping.toPersistObject(externalObject: externalObject) else {
                        continue
                    }
                    
                    if let index = objectsToDelete.firstIndex(where: { $0.id == dataModel.id }) {
                        objectsToDelete.remove(at: index)
                    }
                    
                    objectsToInsert.append(dataModel)
                }

                if objectsToDelete.count > 0 {
                    for object in objectsToDelete {
                        realm.delete(object)
                    }
                }
                
                if objectsToInsert.count > 0 {
                    for object in objectsToInsert {
                        realm.add(object, update: .modified)
                    }
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
    
    @MainActor public func writeObjectsAsync(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getObjectsType: GetObjectsType?) async throws -> [DataModelType] {
        
        return try await withCheckedThrowingContinuation { continuation in
            self.writeObjectsAsyncClosure(externalObjects: externalObjects, writeOption: writeOption, getObjectsType: getObjectsType) { result in
                switch result {
                case .success(let dataModels):
                    continuation.resume(returning: dataModels)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    @MainActor func writeObjectsPublisher(externalObjects: [ExternalObjectType], writeOption: PersistenceWriteOption?, getObjectsType: GetObjectsType?) -> AnyPublisher<[DataModelType], Error> {
                        
        return Future { promise in
            
            Task {
                
                do {
                    
                    let dataModels: [DataModelType] = try await self.writeObjectsAsync(
                        externalObjects: externalObjects,
                        writeOption: writeOption,
                        getObjectsType: getObjectsType
                    )
                    
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
