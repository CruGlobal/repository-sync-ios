//
//  RealmDatabaseWrite.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/22/23.
//  Copyright © 2023 Cru. All rights reserved.
//

import Foundation

public class RealmDatabaseWrite {
    
    public let updateObjects: [IdentifiableRealmObject]
    public let deleteObjects: [IdentifiableRealmObject]?
    
    public init(updateObjects: [IdentifiableRealmObject], deleteObjects: [IdentifiableRealmObject]? = nil) {
        
        self.updateObjects = updateObjects
        self.deleteObjects = deleteObjects
    }
}
