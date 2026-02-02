//
//  SyncInvalidator.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

class SyncInvalidator {
    
    private let id: String
    private let timeInterval: SyncInvalidatorTimeInterval
    private let persistence: SyncInvalidatorPersistenceInterface
    
    init(id: String, timeInterval: SyncInvalidatorTimeInterval, persistence: SyncInvalidatorPersistenceInterface) {
        
        self.id = id
        self.timeInterval = timeInterval
        self.persistence = persistence
    }
    
    private var keyLastSyncDate: String {
        return String(describing: SyncInvalidator.self) + ".keyLastSyncDate.\(id)"
    }
    
    var shouldSync: Bool {
        
        let shouldSync: Bool
        
        if let lastSync = getLastSyncDate() {
            
            let elapsedTimeInSeconds: TimeInterval = Date().timeIntervalSince(lastSync)
            let elapsedTimeInMinutes: TimeInterval = elapsedTimeInSeconds / 60
            let elapsedTimeInHours: TimeInterval = elapsedTimeInMinutes / 60
            let elapsedTimeInDays: TimeInterval = elapsedTimeInHours / 24
            
            switch timeInterval {
            case .minutes(let minute):
                shouldSync = elapsedTimeInMinutes >= minute
            case .hours(let hour):
                shouldSync = elapsedTimeInHours >= hour
            case .days(let day):
                shouldSync = elapsedTimeInDays >= day
            }
        }
        else {
            
            shouldSync = true
        }
        
        return shouldSync
    }
    
    func didSync(lastSyncDate: Date = Date()) {
        storeLastSyncDate(date: lastSyncDate)
    }
    
    func resetSync() {
        persistence.deleteDate(id: keyLastSyncDate)
    }
    
    private func getLastSyncDate() -> Date? {
        return persistence.getDate(id: keyLastSyncDate)
    }
    
    private func storeLastSyncDate(date: Date) {
        persistence.saveDate(id: keyLastSyncDate, date: date)
    }
}
