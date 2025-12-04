//
//  RealmDatabaseCacheType.swift
//  RepositorySync
//
//  Created by Levi Eggert on 11/14/22.
//  Copyright © 2022 Cru. All rights reserved.
//

import Foundation
import RealmSwift

public enum RealmDatabaseCacheType {
    
    case disk(fileLocation: RealmDatabaseFileLocation, migrationBlock: MigrationBlock)
    case inMemory(identifier: String)
}
