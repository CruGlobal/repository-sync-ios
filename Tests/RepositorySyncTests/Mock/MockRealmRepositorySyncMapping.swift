//
//  MockRealmRepositorySyncMapping.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
@testable import RepositorySync

final class MockRealmRepositorySyncMapping: Mapping {

    func toDataModel(externalObject: MockDataModel) -> MockDataModel? {
        
        return externalObject
    }
    
    func toDataModel(persistObject: MockRealmObject) -> MockDataModel? {
        
        return MockDataModel(
            id: persistObject.id,
            name: persistObject.name
        )
    }
    
    func toPersistObject(externalObject: MockDataModel) -> MockRealmObject? {
        
        return MockRealmObject
            .createObject(
                id: externalObject.id,
                name: externalObject.name
            )
    }
}
