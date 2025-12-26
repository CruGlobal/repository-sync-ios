//
//  MockSwiftRepositorySyncMapping.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
@testable import RepositorySync

@available(iOS 17.4, *)
public final class MockSwiftRepositorySyncMapping: Mapping {

    public func toDataModel(externalObject: MockDataModel) -> MockDataModel? {
        return externalObject
    }
    
    public func toDataModel(persistObject: MockSwiftObject) -> MockDataModel? {
        return MockDataModel(interface: persistObject)
    }
    
    public func toPersistObject(externalObject: MockDataModel) -> MockSwiftObject? {
        return MockSwiftObject.createFrom(interface: externalObject)
    }
}
