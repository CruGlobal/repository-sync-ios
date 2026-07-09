//
//  MockOtherSwiftObject.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData
@testable import RepositorySync

@available(iOS 17.4, *)
public typealias MockOtherSwiftObject = MockOtherSwiftObjectV1.MockOtherSwiftObject

@available(iOS 17.4, *)
public enum MockOtherSwiftObjectV1 {
 
    @Model
    public class MockOtherSwiftObject: IdentifiableSwiftDataObject {
        
        public var name: String = ""
        
        @Attribute(.unique) public var id: String = ""

        public init() {

        }
    }
}

@available(iOS 17.4, *)
extension MockOtherSwiftObject {

    public static func idPredicate(id: String) -> Predicate<MockOtherSwiftObject> {
        return #Predicate<MockOtherSwiftObject> { object in
            object.id == id
        }
    }

    public static func idsPredicate(ids: Set<String>) -> Predicate<MockOtherSwiftObject> {
        return #Predicate<MockOtherSwiftObject> { object in
            ids.contains(object.id)
        }
    }
}
