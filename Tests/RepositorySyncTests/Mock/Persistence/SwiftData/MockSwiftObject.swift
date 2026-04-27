//
//  MockSwiftObject.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
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
}

@available(iOS 17.4, *)
extension MockSwiftObject {
    
    public func mapFrom(model: MockDataModel) {
        id = model.id
        name = model.name
        position = model.position
        isEvenPosition = model.isEvenPosition
    }
    
    public static func createFrom(model: MockDataModel) -> MockSwiftObject {
        let swiftObject = MockSwiftObject()
        swiftObject.mapFrom(model: model)
        return swiftObject
    }
    
    public func toModel() -> MockDataModel {
        
        return MockDataModel(
            id: id,
            name: name,
            position: position
        )
    }
}
