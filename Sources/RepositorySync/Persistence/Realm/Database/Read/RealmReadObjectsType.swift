//
//  RealmReadObjectsType.swift
//  RepositorySync
//
//  Created by Levi Eggert on 5/22/26.
//  Copyright © 2026 Cru. All rights reserved.
//

import Foundation

public enum RealmReadObjectsType {
    
    case allObjects
    case object(id: String)
    case objectsByIds(ids: Set<String>, sortByKeyPath: SortByKeyPath?)
    case objectsByQuery(query: RealmDatabaseQuery)
}
