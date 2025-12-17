//
//  GetObjectsType.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

public enum GetObjectsType: Sendable {
    case allObjects
    case object(id: String)
}
