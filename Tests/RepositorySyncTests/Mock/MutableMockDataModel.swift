//
//  MutableMockDataModel.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

public struct MutableMockDataModel: MockDataModelInterface {
    
    public var id: String = ""
    public var name: String = ""
    public var position: Int = -1
    public var isEvenPosition: Bool = false
    
    public init() {
        
    }
}
