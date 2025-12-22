//
//  RealmDataAsyncWrite.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift

public final class RealmDataAsyncWrite {
    
    private let writeSerialQueue: DispatchQueue = DispatchQueue(label: "realm.write.serial_queue")
    private let write: RealmDataWrite = RealmDataWrite()
    
    public let config: Realm.Configuration
    
    public init(config: Realm.Configuration) {
        
        self.config = config
    }
    
    @MainActor public func objects(writeClosure: @escaping ((_ realm: Realm) -> Void), completion: @escaping ((_ result: Result<Realm, Error>) -> Void)) {
                        
        let config: Realm.Configuration = self.config
        
        guard config.isInMemory == false else {
            let description: String = "Unable to perform async write on in memory realm.  In memory realm's require a shared realm instance."
            let error: Error = NSError(domain: String(describing: RealmDataAsyncWrite.self), code: -1, userInfo: [NSLocalizedDescriptionKey: description])
            completion(.failure(error))
            return
        }
        
        writeSerialQueue.async {
            autoreleasepool {
                do {
                    let realm: Realm = try Realm(configuration: config)
                    
                    try realm.write {
                        writeClosure(realm)
                        completion(.success(realm))
                    }
                }
                catch let error {
                    completion(.failure(error))
                }
            }
        }
    }
    
    @MainActor public func objects(writeClosure: @escaping ((_ realm: Realm) -> Void)) async throws {
        
        return try await withCheckedThrowingContinuation { continuation in
            objects(writeClosure: writeClosure) { (result: Result<Realm, Error>) in
                switch result {
                case .success( _):
                    continuation.resume(returning: Void())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
