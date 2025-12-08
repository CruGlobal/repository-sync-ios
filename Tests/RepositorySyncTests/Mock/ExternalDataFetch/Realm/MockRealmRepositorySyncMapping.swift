//
//  MockRealmRepositorySyncMapping.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
@testable import RepositorySync

class MockRealmRepositorySyncMapping: Mapping {

    func toDataModel(externalObject: MockRepositorySyncDataModel) -> MockRepositorySyncDataModel? {
        
        return externalObject
    }
    
    func toDataModel(persistObject: MockRealmObject) -> MockRepositorySyncDataModel? {
        
        return MockRepositorySyncDataModel(
            id: persistObject.id,
            name: persistObject.name
        )
    }
    
    func toPersistObject(externalObject: MockRepositorySyncDataModel) -> MockRealmObject? {
        
        return MockRealmObject
            .createObject(
                id: externalObject.id,
                name: externalObject.name
            )
    }
}
