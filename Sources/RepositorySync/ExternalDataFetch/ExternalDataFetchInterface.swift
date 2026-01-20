//
//  ExternalDataFetchInterface.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation
import Combine

public protocol ExternalDataFetchInterface: Sendable {
    
    associatedtype ExternalObject: Sendable
    associatedtype ExternalDataFetchContext: Sendable
    
    func getObject(id: String, context: ExternalDataFetchContext) async throws -> [ExternalObject]
    func getObjects(context: ExternalDataFetchContext) async throws -> [ExternalObject]
    @available(*, deprecated) func getObjectPublisher(id: String, context: ExternalDataFetchContext) -> AnyPublisher<[ExternalObject], Error>
    @available(*, deprecated) func getObjectsPublisher(context: ExternalDataFetchContext) -> AnyPublisher<[ExternalObject], Error>
}

extension ExternalDataFetchInterface {
    
    public func emptyResponse() async throws -> [ExternalObject] {
        return Array()
    }
    
    @available(*, deprecated)
    public func emptyResponsePublisher() -> AnyPublisher<[ExternalObject], Error> {
        
        return Just(Array<ExternalObject>())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
