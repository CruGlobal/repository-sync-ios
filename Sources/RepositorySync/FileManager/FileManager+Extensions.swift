//
//  FileManager+Extensions.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

extension FileManager {
    
    func createDirectoryIfNotExists(directoryUrl: URL) throws -> URL {
        
        guard !fileExists(atPath: directoryUrl.path) else {
            return directoryUrl
        }
        
        try createDirectory(
            at: directoryUrl,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        return directoryUrl
    }
    
    func removeUrl(url: URL) throws {
        try removeItem(at: url)
    }
}
