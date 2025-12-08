//
//  MockRepositorySyncExternalDataFetch.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
@testable import RepositorySync
import Combine

final class MockRepositorySyncExternalDataFetch: ExternalDataFetchInterface {
            
    private let objects: [MockRepositorySyncDataModel]
    private let delayRequestSeconds: TimeInterval
    
    init(objects: [MockRepositorySyncDataModel], delayRequestSeconds: TimeInterval) {
        
        self.objects = objects
        self.delayRequestSeconds = delayRequestSeconds
    }
    
    func getObjectPublisher(id: String, context: MockExternalDataFetchContext) -> AnyPublisher<[MockRepositorySyncDataModel], Error> {
        
        return delayPublisher()
            .map { _ in
                
                let fetchedObjects: [MockRepositorySyncDataModel]
                
                if let existingObject = self.objects.first(where: {$0.id == id}) {
                    fetchedObjects = [existingObject]
                }
                else {
                    fetchedObjects = Array()
                }
                
                return fetchedObjects
            }
            .eraseToAnyPublisher()
    }
    
    func getObjectsPublisher(context: MockExternalDataFetchContext) -> AnyPublisher<[MockRepositorySyncDataModel], Error> {
        
        let allObjects: [MockRepositorySyncDataModel] = objects
        
        return delayPublisher()
            .map { _ in
                return allObjects
            }
            .eraseToAnyPublisher()
    }
    
    private func delayPublisher() -> AnyPublisher<Void, Error> {
        
        let delayRequestSeconds: TimeInterval = self.delayRequestSeconds
        
        return Future { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + delayRequestSeconds) {
                promise(.success(Void()))
            }
        }
        .eraseToAnyPublisher()
    }
}
