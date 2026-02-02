//
//  MockSyncInvalidatorPersistence.swift
//  RepositorySync
//
//  Created by Levi Eggert on 2/2/26.
//

import Foundation
@testable import RepositorySync

class MockSyncInvalidatorPersistence: SyncInvalidatorPersistenceInterface {
   
    private var storedDates: [String: Date] = Dictionary()
    
    init() {
        
    }
    
    func getDate(id: String) -> Date? {
        return storedDates[id]
    }
    
    func saveDate(id: String, date: Date?) {
        storedDates[id] = date
    }
    
    func deleteDate(id: String) {
        storedDates[id] = nil
    }
}
