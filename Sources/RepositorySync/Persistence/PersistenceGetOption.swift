//
//  PersistenceGetOption.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

public enum PersistenceGetOption: Sendable {
    
    case allObjects
    case object(id: String)
    case objectsByIds(ids: Set<String>)
}

extension PersistenceGetOption {
    
    public func toRealmReadObjectsType() -> RealmReadObjectsType {
        
        switch self {
        case .allObjects:
            return .allObjects
        case .object(let id):
            return .object(id: id)
        case .objectsByIds(let ids):
            return .objectsByIds(ids: ids, sortByKeyPath: nil)
        }
    }
}
