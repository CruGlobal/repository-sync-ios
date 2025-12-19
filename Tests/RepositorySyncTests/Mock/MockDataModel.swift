//
//  MockDataModel.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

public struct MockDataModel: MockDataModelInterface, Sendable {
    
    public let id: String
    public let name: String
    public let position: Int
    
    public var isEvenPosition: Bool {
        return position % 2 == 0
    }
        
    public init(interface: MockDataModelInterface) {
        self.id = interface.id
        self.name = interface.name
        self.position = interface.position
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
        return MockDataModel(interface: mutable)
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
