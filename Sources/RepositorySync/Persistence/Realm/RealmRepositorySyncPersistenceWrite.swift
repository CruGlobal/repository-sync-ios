//
//  RealmRepositorySyncPersistenceWrite.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift

public final class RealmRepositorySyncPersistenceWrite<DataModelType: Sendable, ExternalObjectType: Sendable, PersistObjectType: IdentifiableRealmObject> {
    
    public let read: RealmRepositorySyncPersistenceRead<DataModelType, ExternalObjectType, PersistObjectType>
    public let asyncWrite: RealmDataAsyncWrite
    public let dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>
    
    public init(read: RealmRepositorySyncPersistenceRead<DataModelType, ExternalObjectType, PersistObjectType>, asyncWrite: RealmDataAsyncWrite, dataModelMapping: any Mapping<DataModelType, ExternalObjectType, PersistObjectType>) {
        
        self.read = read
        self.asyncWrite = asyncWrite
        self.dataModelMapping = dataModelMapping
    }
    
    @MainActor private func writeObjectsBackground(externalObjects: [ExternalObjectType], getObjectsType: GetObjectsType?, completion: @escaping ((_ result: Result<[DataModelType], Error>) -> Void)) {
     
        asyncWrite.objects(writeClosure: { (realm: Realm) in
            
            do {
                
                for externalObject in externalObjects {
                    
                    guard let persistObject = self.dataModelMapping.toPersistObject(externalObject: externalObject) else {
                        continue
                    }
                    
                    realm.add(persistObject, update: .modified)
                }
                                        
                let dataModels: [DataModelType]
                
                if let getObjectsType = getObjectsType {
                    dataModels = try self.read.getObjects(realm: realm, getObjectsType: getObjectsType, query: nil)
                }
                else {
                    dataModels = Array()
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
            self.writeObjectsBackground(externalObjects: externalObjects, getObjectsType: getObjectsType) { result in
                switch result {
                case .success(let dataModels):
                    continuation.resume(returning: dataModels)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
