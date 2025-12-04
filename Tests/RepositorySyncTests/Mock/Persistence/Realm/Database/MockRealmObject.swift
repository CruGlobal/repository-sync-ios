//
//  MockRealmObject.swift
//  RepositorySync
//
//  Created by Levi Eggert on 3/20/20.
//  Copyright © 2020 Cru. All rights reserved.
//

import Foundation
import RealmSwift
@testable import RepositorySync

class MockRealmObject: Object, IdentifiableRealmObject {
    
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var position: Int = -1
    @objc dynamic var isEvenPosition: Bool = false
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func createObject(id: String, name: String? = nil, position: Int = -1) -> MockRealmObject {
        
        let object = MockRealmObject()
        
        object.id = id
        object.name = name ?? "name_\(id)"
        object.position = position
        object.isEvenPosition = position % 2 == 0
        
        return object
    }
}
