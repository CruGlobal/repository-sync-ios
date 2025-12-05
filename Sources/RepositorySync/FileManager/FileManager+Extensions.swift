//
//  FileManager+Extensions.swift
//  RepositorySync
//
//  Created by Levi Eggert on 7/30/25.
//  Copyright © 2025 Cru. All rights reserved.
//

import Foundation

extension FileManager {
    
    public func getFilePathExists(url: URL) -> Bool {
        return fileExists(atPath: url.path)
    }
    
    public func createDirectoryIfNotExists(directoryUrl: URL) throws -> URL {
        
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
    
    public func removeUrl(url: URL) throws {
        try removeItem(at: url)
    }
}
