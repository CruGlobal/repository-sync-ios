//
//  SwiftDataContextWrite.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import SwiftData

@available(iOS 17.4, *)
public final class SwiftDataContextWrite {
    
    public let context: ModelContext
    public let write: SwiftDataWrite = SwiftDataWrite()
    
    public init(context: ModelContext) {
        
        self.context = context
    }
    
    public func objects(deleteObjects: [any IdentifiableSwiftDataObject]?, insertObjects: [any IdentifiableSwiftDataObject]?) throws {
        try write.objects(context: context, deleteObjects: deleteObjects, insertObjects: insertObjects)
    }
}
