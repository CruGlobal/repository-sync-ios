//
//  RealmConfiguration+IsInMemory.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/22/25.
//

import Foundation
import RealmSwift

extension Realm.Configuration {
    
    public var isInMemory: Bool {
        
        guard let identifier = inMemoryIdentifier else {
            return false
        }
        
        let isInMemory: Bool = !identifier.isEmpty
        
        return isInMemory
    }
}
