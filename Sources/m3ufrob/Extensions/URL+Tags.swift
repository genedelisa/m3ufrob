// File: File.swift
// Project:
// Package:
// Product:
// https://github.com/genedelisa/
// ~/Library/Developer/Xcode/UserDataIDETemplateMacros.plist
//
// Created by Gene De Lisa on 9/22/23
//
// Copyright © 2023 Rockhopper Technologies, Inc. All rights reserved.
// Licensed under the MIT License (the "License");
// You may not use this file except in compliance with the License.
//
// You may obtain a copy of the License at
// https://opensource.org/licenses/MIT
//
// Follow me on Twitter: @GeneDeLisaDev


import Foundation

// Source Code from: https://github.com/amyspark/xattr
extension URL {
    
    private static let itemUserTagsName = "com.apple.metadata:_kMDItemUserTags"
    
    public func getFileTags() -> [String] {
        do {
#if os(macOS)
            // prefer native tagNames https://stackoverflow.com/a/47340666
            return try resourceValues(forKeys: [.tagNamesKey]).tagNames ?? []
#else
            return try getiOSFileTags()
#endif
        } catch {
            //log.error("Error while getting tag names", metadata: ["error": "\(error)"])
            return []
        }
    }
    
    public func setFileTags(_ tags: [String]) {
        do {
#if os(macOS)
            // https://stackoverflow.com/a/47340666
            try (self as NSURL).setResourceValue(tags, forKey: URLResourceKey.tagNamesKey)
#else
            try setiOSFileTags(tags)
#endif
        } catch {
            //log.error("Error while setting tag names", metadata: ["error": "\(error)"])
        }
    }
    
    // MARK: - iOS finder tags
    
    private func getiOSFileTags() throws -> [String] {
        var tags = [String]()
        let data = try self.getExtendedAttribute(forName: URL.itemUserTagsName)
        if let tagPlist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String] {
            
            tags = tagPlist.map { tag -> String in
                var newTag = tag
                if newTag.suffix(2) == "\n0" {
                    newTag.removeLast(2)
                }
                return newTag
            }
        } else if let newTags = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: data) as? [String] {
            tags = newTags
        }
        return tags
    }
    
    private func setiOSFileTags(_ fileTags: [String]) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: fileTags, requiringSecureCoding: false)
        try setExtendedAttribute(data: data, forName: URL.itemUserTagsName)
    }
    
    /// Get extended attribute.
    private func getExtendedAttribute(forName name: String, follow: Bool = false) throws -> Data {
        var options: Int32 = 0
        if !follow {
            options = options | XATTR_NOFOLLOW
        }
        let data = try withUnsafeFileSystemRepresentation { fileSystemPath -> Data in
            // Determine attribute size:
            let length = getxattr(fileSystemPath, name, nil, 0, 0, options)
            guard length >= 0 else { throw URL.posixError(errno) }
            
            // Create buffer with required size:
            var data = Data(count: length)
            
            // Retrieve attribute:
            let result = data.withUnsafeMutableBytes { [count = data.count] in
                getxattr(fileSystemPath, name, $0.baseAddress, count, 0, 0)
            }
            guard result >= 0 else { throw URL.posixError(errno) }
            return data
        }
        return data
    }
    
    /// Set extended attribute.
    private func setExtendedAttribute(data: Data, forName name: String, follow: Bool = false) throws {
        var options: Int32 = 0
        if !follow {
            options = options | XATTR_NOFOLLOW
        }
        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let result = data.withUnsafeBytes {
                setxattr(fileSystemPath, name, $0.baseAddress, data.count, 0, options)
            }
            guard result >= 0 else { throw URL.posixError(errno) }
        }
    }
    
}
