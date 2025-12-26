//
//  WriteSwiftObjects.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

@available(iOS 17.4, *)
public final class WriteSwiftObjects {
    
    public let deleteObjects: [any IdentifiableSwiftDataObject]?
    public let insertObjects: [any IdentifiableSwiftDataObject]?
    
    public init(deleteObjects: [any IdentifiableSwiftDataObject]?, insertObjects: [any IdentifiableSwiftDataObject]?) {
        
        self.deleteObjects = deleteObjects
        self.insertObjects = insertObjects
    }
}
