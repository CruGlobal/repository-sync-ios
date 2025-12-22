//
//  MockRepositorySync.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
@testable import RepositorySync

class MockRepositorySync: RepositorySync<MockDataModel, MockExternalDataFetch, MockRealmObject> {
    
    init(externalDataFetch: MockExternalDataFetch, swiftElseRealmPersistence: MockSwiftElseRealmPersistence) {
        
        super.init(
            externalDataFetch: externalDataFetch,
            swiftElseRealmPersistence: swiftElseRealmPersistence
        )
    }
}
