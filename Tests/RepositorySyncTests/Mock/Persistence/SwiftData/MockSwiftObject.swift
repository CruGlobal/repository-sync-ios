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
public class MockSwiftObject: IdentifiableSwiftDataObject, MockDataModelInterface {
    
    public var name: String = ""
    public var position: Int = -1
    public var isEvenPosition: Bool = false
    
    @Attribute(.unique) public var id: String = ""
    
    public init() {
        
    }
    
    public func mapFrom(interface: MockDataModelInterface) {
        id = interface.id
        name = interface.name
        position = interface.position
        isEvenPosition = interface.isEvenPosition
    }
    
    public static func createFrom(interface: MockDataModelInterface) -> MockSwiftObject {
        let swiftObject = MockSwiftObject()
        swiftObject.mapFrom(interface: interface)
        return swiftObject
    }
}
