//
//  ExternalDataFetchInterface.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Combine

public protocol ExternalDataFetchInterface {
    
    associatedtype ExternalObject: Sendable
    associatedtype ExternalDataFetchContext
    
    func getObjectPublisher(id: String, context: ExternalDataFetchContext) -> AnyPublisher<[ExternalObject], Error>
    func getObjectsPublisher(context: ExternalDataFetchContext) -> AnyPublisher<[ExternalObject], Error>
}

extension ExternalDataFetchInterface {
    
    func emptyResponsePublisher() -> AnyPublisher<[ExternalObject], Error> {
        
        return Just(Array<ExternalObject>())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
