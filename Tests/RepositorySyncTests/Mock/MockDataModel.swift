//
//  MockDataModel.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

struct MockDataModel: Sendable {
    
    let id: String
    let name: String
        
    static func createDataModelsFromIds(ids: [String]) -> [MockDataModel] {
        
        return ids.map {
            MockDataModel(
                id: $0,
                name: "name_" + $0
            )
        }
    }
    
    static func sortDataModelIds(dataModels: [MockDataModel]) -> [String] {
        
        let sortedDataModels: [MockDataModel] = dataModels.sorted {
            $0.id < $1.id
        }
        
        return sortedDataModels.map { $0.id }
    }
}
