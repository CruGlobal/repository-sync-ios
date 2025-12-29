//
//  MockRepositorySync.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
@testable import RepositorySync

public class MockRepositorySync: RepositorySync<MockDataModel, MockExternalDataFetch, MockRealmObject> {

    @available(iOS 17.4, *)
    public override func getSwiftPersistence(swiftDatabase: SwiftDatabase) -> (any Persistence<MockDataModel, MockDataModel>)? {
        return SwiftRepositorySyncPersistence(
            database: swiftDatabase,
            dataModelMapping: MockSwiftRepositorySyncMapping()
        )
    }
}
