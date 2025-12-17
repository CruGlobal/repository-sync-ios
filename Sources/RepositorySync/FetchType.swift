//
//  FetchType.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

public enum FetchType {
    
    case get(cachePolicy: GetCachePolicy)
    case observe(cachePolicy: ObserveCachePolicy)
}
