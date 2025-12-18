//
//  MockRealmObject.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
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
    
    public static func createObject(id: String, name: String? = nil, position: Int = -1) -> MockRealmObject {
        
        let object = MockRealmObject()
        
        object.id = id
        object.name = name ?? "name_\(id)"
        object.position = position
        object.isEvenPosition = position % 2 == 0
        
        return object
    }
}
