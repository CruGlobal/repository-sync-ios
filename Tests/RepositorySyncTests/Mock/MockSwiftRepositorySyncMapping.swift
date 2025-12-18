//
//  MockSwiftRepositorySyncMapping.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
@testable import RepositorySync

@available(iOS 17.4, *)
final class MockSwiftRepositorySyncMapping: Mapping {

    func toDataModel(externalObject: MockDataModel) -> MockDataModel? {
        
        return externalObject
    }
    
    func toDataModel(persistObject: MockSwiftObject) -> MockDataModel? {
        
        return MockDataModel(
            id: persistObject.id,
            name: persistObject.name
        )
    }
    
    func toPersistObject(externalObject: MockDataModel) -> MockSwiftObject? {
        
        return MockSwiftObject
            .createObject(
                id: externalObject.id,
                name: externalObject.name
            )
    }
}
