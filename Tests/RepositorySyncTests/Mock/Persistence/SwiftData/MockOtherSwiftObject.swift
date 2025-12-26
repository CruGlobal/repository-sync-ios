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
@Model
public class MockOtherSwiftObject: IdentifiableSwiftDataObject {
    
    public var name: String = ""
    
    @Attribute(.unique) public var id: String = ""
    
    public init() {
        
    }
}
