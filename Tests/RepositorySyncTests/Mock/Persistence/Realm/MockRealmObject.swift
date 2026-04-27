//
//  MockRealmObject.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift
@testable import RepositorySync

public class MockRealmObject: Object, IdentifiableRealmObject {
    
    @objc dynamic public var id: String = ""
    @objc dynamic public var name: String = ""
    @objc dynamic public var position: Int = -1
    @objc dynamic public var isEvenPosition: Bool = false
    
    override public static func primaryKey() -> String? {
        return "id"
    }
}

extension MockRealmObject {
    
    public func mapFrom(model: MockDataModel) {
        id = model.id
        name = model.name
        position = model.position
        isEvenPosition = model.isEvenPosition
    }
    
    public static func createFrom(model: MockDataModel) -> MockRealmObject {
        let realmObject = MockRealmObject()
        realmObject.mapFrom(model: model)
        return realmObject
    }
    
    public func toModel() -> MockDataModel {
        
        return MockDataModel(
            id: id,
            name: name,
            position: position
        )
    }
}
