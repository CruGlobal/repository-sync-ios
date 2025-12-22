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

final class MockExternalDataFetch: ExternalDataFetchInterface {
            
    private let objects: [MockDataModel]
    private let delayRequestSeconds: TimeInterval
    
    init(objects: [MockDataModel], delayRequestSeconds: TimeInterval) {
        
        self.objects = objects
        self.delayRequestSeconds = delayRequestSeconds
    }
    
    func getObjectPublisher(id: String, context: MockExternalDataFetchContext) -> AnyPublisher<[MockDataModel], Error> {
        
        return delayPublisher()
            .map { _ in
                
                let fetchedObjects: [MockDataModel]
                
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
    
    func getObjectsPublisher(context: MockExternalDataFetchContext) -> AnyPublisher<[MockDataModel], Error> {
        
        let allObjects: [MockDataModel] = objects
        
        return delayPublisher()
            .map { _ in
                return allObjects
            }
            .eraseToAnyPublisher()
    }
    
    private func delayPublisher() -> AnyPublisher<Void, Error> {
        
        let delayRequestSeconds: TimeInterval = self.delayRequestSeconds

        return getSuccessPublisher()
            .delay(
                for: .seconds(delayRequestSeconds),
                scheduler: RunLoop.current
            )
            .eraseToAnyPublisher()
    }
    
    private func getSuccessPublisher() -> AnyPublisher<Void, Error> {
        
        return Future { promise in
            
            promise(.success(Void()))
        }
        .eraseToAnyPublisher()
    }
}
