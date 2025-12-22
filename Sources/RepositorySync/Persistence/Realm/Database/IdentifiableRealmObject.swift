//
//  IdentifiableRealmObject.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import RealmSwift

public protocol IdentifiableRealmObject: Object {
    
    var id: String { get set }
}
