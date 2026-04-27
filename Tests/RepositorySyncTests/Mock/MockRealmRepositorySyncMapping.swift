//
//  MockRealmRepositorySyncMapping.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
@testable import RepositorySync

public final class MockRealmRepositorySyncMapping: Mapping {

    public func toDataModel(externalObject: MockDataModel) -> MockDataModel? {
        return externalObject
    }
    
    public func toDataModel(persistObject: MockRealmObject) -> MockDataModel? {
        return persistObject.toModel()
    }
    
    public func toPersistObject(externalObject: MockDataModel) -> MockRealmObject? {
        return MockRealmObject.createFrom(model: externalObject)
    }
}
