//
//  RealmDataWrite.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift

public final class RealmDataWrite {
    
    private let writeSerialQueue: DispatchQueue = DispatchQueue(label: "realm.write.serial_queue")
    
    public let config: Realm.Configuration
    
    public init(config: Realm.Configuration) {
        
        self.config = config
    }
    
    public func serialAsync(asyncClosure: @escaping ((_ result: Result<Realm, Error>) -> Void)) {
        
        let config: Realm.Configuration = self.config
        
        guard config.isInMemory == false else {
            
            let description: String = "Unable to perform async write on in memory realm.  In memory realm's require a shared realm instance."
            let error: Error = NSError(domain: String(describing: RealmDataWrite.self), code: -1, userInfo: [NSLocalizedDescriptionKey: description])
            
            asyncClosure(.failure(error))
            
            return
        }
        
        writeSerialQueue.async {
            autoreleasepool {
                do {
                    let realm: Realm = try Realm(configuration: config)
                    asyncClosure(.success(realm))
                }
                catch let error {
                    asyncClosure(.failure(error))
                }
            }
        }
    }
    
    public func async(writeAsync: @escaping ((_ realm: Realm) -> Void), writeError: @escaping ((_ error: Error) -> Void)) {
        
        serialAsync { (result: Result<Realm, Error>) in
            
            switch result {
            
            case .success(let realm):
                
                do {
                    
                    try realm.write {
                        writeAsync(realm)
                    }
                }
                catch let error {
                    writeError(error)
                }
            
            case .failure(let error):
                writeError(error)
            }
        }
    }
    
    public func realm(realm: Realm, writeClosure: ((_ realm: Realm) -> WriteRealmObjects), updatePolicy: Realm.UpdatePolicy, completion: ((_ realm: Realm) -> Void)? = nil) throws {
        
        try realm.write {
            
            let writeRealmObjects: WriteRealmObjects = writeClosure(realm)
             
            if let objectsToDelete = writeRealmObjects.deleteObjects, objectsToDelete.count > 0 {
                realm.delete(objectsToDelete)
            }
            
            if let objectsToAdd = writeRealmObjects.addObjects, objectsToAdd.count > 0 {
                realm.add(objectsToAdd, update: updatePolicy)
            }
            
            completion?(realm)
        }
    }
}
