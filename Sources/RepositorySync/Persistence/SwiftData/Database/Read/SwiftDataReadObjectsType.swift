//
//  SwiftDataReadObjectsType.swift
//  RepositorySync
//
//  Created by Levi Eggert on 5/22/26.
//  Copyright © 2026 Cru. All rights reserved.
//

import Foundation

@available(iOS 17.4, *)
public enum SwiftDataReadObjectsType<T: IdentifiableSwiftDataObject>: Sendable {
    
    case allObjects
    case object(id: String)
    case objectsByIds(ids: Set<String>, sortBy: [SortDescriptor<T>]?)
    case objectsByQuery(query: SwiftDatabaseQuery<T>)
}
