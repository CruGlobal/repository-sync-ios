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
    case objectsByIds(ids: [String])
}
