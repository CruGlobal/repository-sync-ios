//
//  ExternalDataFetchInterface.swift
//  RepositorySync
//
//  Created by Levi Eggert on 12/1/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

public protocol ExternalDataFetchInterface {
    
    associatedtype ExternalObject: Sendable
    associatedtype ExternalDataFetchContext: Sendable
    
    func getObject(id: String, context: ExternalDataFetchContext) async throws -> [ExternalObject]
    func getObjects(context: ExternalDataFetchContext) async throws -> [ExternalObject]
}

extension ExternalDataFetchInterface {
    
    public func emptyResponse() async throws -> [ExternalObject] {
        return Array()
    }
}
