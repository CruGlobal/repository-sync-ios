//
//  SwiftDatabaseWrite.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

@available(iOS 17.4, *)
public final class SwiftDatabaseWrite {
    
    public let updateObjects: [any IdentifiableSwiftDataObject]
    public let deleteObjects: [any IdentifiableSwiftDataObject]?
    public let error: Error?
    
    public init(updateObjects: [any IdentifiableSwiftDataObject], deleteObjects: [any IdentifiableSwiftDataObject]?, error: Error? = nil) {
        
        self.updateObjects = updateObjects
        self.deleteObjects = deleteObjects
        self.error = error
    }
    
    public init(error: Error) {
        
        self.updateObjects = Array()
        self.deleteObjects = nil
        self.error = error
    }
}
