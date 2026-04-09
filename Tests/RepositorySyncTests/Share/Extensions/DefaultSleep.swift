//
//  DefaultSleep.swift
//  RepositorySync
//
//  Created by Levi Eggert on 4/9/26.
//  Copyright © 2026 Cru. All rights reserved.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    
    static func defaultTestSleep() async throws {
        
        try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
    }
}
