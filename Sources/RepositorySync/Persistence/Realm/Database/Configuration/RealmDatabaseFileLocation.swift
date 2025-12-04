//
//  RealmDatabaseFileLocation.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/22/23.
//  Copyright © 2023 Cru. All rights reserved.
//

import Foundation

public enum RealmDatabaseFileLocation {
    
    case fileName(name: String)
    case fileUrl(url: URL)
}
