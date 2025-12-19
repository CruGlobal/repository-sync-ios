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

public class MockRealmObject: Object, IdentifiableRealmObject, MockDataModelInterface {
    
    @objc dynamic public var id: String = ""
    @objc dynamic public var name: String = ""
    @objc dynamic public var position: Int = -1
    @objc dynamic public var isEvenPosition: Bool = false
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    public func mapFrom(interface: MockDataModelInterface) {
        id = interface.id
        name = interface.name
        position = interface.position
        isEvenPosition = interface.isEvenPosition
    }
    
    public static func createFrom(interface: MockDataModelInterface) -> MockRealmObject {
        let realmObject = MockRealmObject()
        realmObject.mapFrom(interface: interface)
        return realmObject
    }
}
