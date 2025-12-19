//
//  SortByKeyPath.swift
//  RepositorySync
//
//  Created by Levi Eggert on 9/19/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

public struct SortByKeyPath: Sendable {
    
    public let keyPath: String
    public let ascending: Bool
    
    public init(keyPath: String, ascending: Bool) {
        self.keyPath = keyPath
        self.ascending = ascending
    }
}
