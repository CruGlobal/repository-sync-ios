//
//  MockExternalDataFetch.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
@testable import RepositorySync
import Combine

public final class MockExternalDataFetch: ExternalDataFetchInterface {
            
    private let objects: [MockDataModel]
    private let delayRequestSeconds: TimeInterval
    
    init(objects: [MockDataModel], delayRequestSeconds: TimeInterval) {
        
        self.objects = objects
        self.delayRequestSeconds = delayRequestSeconds
    }
    
    public func getObject(id: String, context: MockExternalDataFetchContext) async throws -> [MockDataModel] {
        
        try await Task.sleep(for: .seconds(delayRequestSeconds))
        
        let fetchedObjects: [MockDataModel]
        
        if let existingObject = objects.first(where: {$0.id == id}) {
            fetchedObjects = [existingObject]
        }
        else {
            fetchedObjects = Array()
        }
        
        return fetchedObjects
    }
    
    public func getObjects(context: MockExternalDataFetchContext) async throws -> [MockDataModel] {
        
        try await Task.sleep(for: .seconds(delayRequestSeconds))
        
        return objects
    }
    
    public func getObjectPublisher(id: String, context: MockExternalDataFetchContext) -> AnyPublisher<[MockDataModel], Error> {
        
        return Future { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + self.delayRequestSeconds) {
                
                let fetchedObjects: [MockDataModel]
                
                if let existingObject = self.objects.first(where: {$0.id == id}) {
                    fetchedObjects = [existingObject]
                }
                else {
                    fetchedObjects = Array()
                }
                                
                promise(.success(fetchedObjects))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func getObjectsPublisher(context: MockExternalDataFetchContext) -> AnyPublisher<[MockDataModel], Error> {
        
        return Future { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + self.delayRequestSeconds) {
                
                promise(.success(self.objects))
            }
        }
        .eraseToAnyPublisher()
    }
}
