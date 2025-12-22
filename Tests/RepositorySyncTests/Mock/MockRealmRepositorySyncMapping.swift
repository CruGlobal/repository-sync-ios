//
//  MockRealmRepositorySyncMapping.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
@testable import RepositorySync

final class MockRealmRepositorySyncMapping: Mapping {

    func toDataModel(externalObject: MockDataModel) -> MockDataModel? {
        return externalObject
    }
    
    func toDataModel(persistObject: MockRealmObject) -> MockDataModel? {
        return MockDataModel(interface: persistObject)
    }
    
    func toPersistObject(externalObject: MockDataModel) -> MockRealmObject? {
        return MockRealmObject.createFrom(interface: externalObject)
    }
}
