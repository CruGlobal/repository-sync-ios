//
//  MutableMockDataModel.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

public struct MutableMockDataModel {
    
    public var id: String = ""
    public var name: String = ""
    public var position: Int = -1
    public var isEvenPosition: Bool = false
    
    public init() {
        
    }
    
    func toModel() -> MockDataModel {
        
        return MockDataModel(
            id: id,
            name: name,
            position: position
        )
    }
}
