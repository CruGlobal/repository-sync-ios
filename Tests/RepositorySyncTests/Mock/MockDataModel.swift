//
//  MockDataModel.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

public struct MockDataModel: Sendable {
    
    public let id: String
    public let name: String
    public let position: Int
    
    public var isEvenPosition: Bool {
        return position % 2 == 0
    }
            
    public static func createFromStringId(id: String) -> MockDataModel? {
        guard let intId = Int(id) else {
            return nil
        }
        return Self.createFromIntId(id: intId)
    }
    
    public static func createFromIntId(id: Int) -> MockDataModel {
        
        var mutable = MutableMockDataModel()
        
        mutable.id = String(id)
        mutable.name = "name_\(id)"
        mutable.position = id
        
        return mutable.toModel()
    }
    
    public static func createDataModelsFromIds(ids: [String]) -> [MockDataModel] {
        return ids.compactMap {
            return createFromStringId(id: $0)
        }
    }
    
    public static func getIdsSortedByPosition(dataModels: [MockDataModel]) -> [String] {
        
        let sortedDataModels: [MockDataModel] = dataModels.sorted {
            $0.position < $1.position
        }
        
        return sortedDataModels.map { $0.id }
    }
}
