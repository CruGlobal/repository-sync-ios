//
//  RealmDatabase+NonThrowing.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/7/26.
//

import Foundation
import RealmSwift

extension RealmDatabase {
    
    public func openRealmNonThrowing(shouldAssertWhenError: Bool = true) -> Realm? {
        do {
            return try openRealm()
        }
        catch let error {
            if shouldAssertWhenError {
                assertionFailure(error.localizedDescription)
            }
            return nil
        }
    }
}
