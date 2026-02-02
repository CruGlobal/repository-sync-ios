//
//  SyncInvalidatorTimeInterval.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

enum SyncInvalidatorTimeInterval {
    
    case minutes(minute: TimeInterval)
    case hours(hour: TimeInterval)
    case days(day: TimeInterval)
}
