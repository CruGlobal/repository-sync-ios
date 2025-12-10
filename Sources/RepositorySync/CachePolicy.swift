//
//  CachePolicy.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

public enum CachePolicy {
    
    // Fetches remote data and stores remote data to cache.
    // Will not observe changes. Can use returnCacheDataAndFetch if observe changes is needed.
    case fetchIgnoringCacheData
    
    // Fetches cached data, doesn't fetch data from remote.
    case returnCacheDataDontFetch
    
    // Fetches cached data, if no cached data, fetches data from remote and stores remote data to cache.
    case returnCacheDataElseFetch
    
    // Fetches cached data and fetches remote data and stores remote data to cache.
    // By default will observe changes.
    case returnCacheDataAndFetch
}
