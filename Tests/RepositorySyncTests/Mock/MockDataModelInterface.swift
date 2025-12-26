//
//  MockDataModelInterface.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

public protocol MockDataModelInterface {
    
    var id: String { get }
    var name: String { get }
    var position: Int { get }
    var isEvenPosition: Bool { get }
}
