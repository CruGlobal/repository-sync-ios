//
//  MockSwiftObject.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData
@testable import RepositorySync

@available(iOS 17.4, *)
@Model
public class MockSwiftObject: IdentifiableSwiftDataObject {
    
    public var name: String = ""
    public var position: Int = -1
    public var isEvenPosition: Bool = false
    
    @Attribute(.unique) public var id: String = ""
    
    public init() {
        
    }
    
    public static func createObject(id: String, name: String? = nil, position: Int = -1) -> MockSwiftObject {
        
        let object = MockSwiftObject()
        
        object.id = id
        object.name = name ?? "name_\(id)"
        object.position = position
        object.isEvenPosition = position % 2 == 0
        
        return object
    }
}
