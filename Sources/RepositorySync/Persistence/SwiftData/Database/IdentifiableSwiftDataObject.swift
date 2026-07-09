//
//  IdentifiableSwiftDataObject.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
public protocol IdentifiableSwiftDataObject: PersistentModel {

    var id: String { get set }

    static func idPredicate(id: String) -> Predicate<Self>
    static func idsPredicate(ids: Set<String>) -> Predicate<Self>
}

@available(iOS 17.4, *)
extension IdentifiableSwiftDataObject {
    
    // TODO: Can remove this method once supporting min iOS 18 and up in place of Schema.entityName(for: ~Levi
    public static var entityName: String {
        return String(describing: String(describing: self))
    }
}
