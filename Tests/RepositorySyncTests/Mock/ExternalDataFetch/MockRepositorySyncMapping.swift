//
//  MockRepositorySyncMapping.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
@testable import RepositorySync

@available(iOS 17.4, *)
class MockRepositorySyncMapping: Mapping {

    func toDataModel(externalObject: MockRepositorySyncDataModel) -> MockRepositorySyncDataModel? {
        
        return externalObject
    }
    
    func toDataModel(persistObject: MockSwiftObject) -> MockRepositorySyncDataModel? {
        
        return MockRepositorySyncDataModel(
            id: persistObject.id,
            name: persistObject.name
        )
    }
    
    func toPersistObject(externalObject: MockRepositorySyncDataModel) -> MockSwiftObject? {
        
        return MockSwiftObject
            .createObject(
                id: externalObject.id,
                name: externalObject.name
            )
    }
}
