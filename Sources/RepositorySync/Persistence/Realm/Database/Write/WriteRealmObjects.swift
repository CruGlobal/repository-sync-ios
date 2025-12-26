//
//  WriteRealmObjects.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

public class WriteRealmObjects {
    
    public let deleteObjects: [IdentifiableRealmObject]?
    public let addObjects: [IdentifiableRealmObject]?
    
    public init(deleteObjects: [IdentifiableRealmObject]?, addObjects: [IdentifiableRealmObject]?) {
        
        self.deleteObjects = deleteObjects
        self.addObjects = addObjects
    }
}
