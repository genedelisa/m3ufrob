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

enum TagName: String {
    case green = "Public"
    case red = "Private"
    case yellow = "Favourite"
    case violet = "Link"
    case unknown = "Dev"
}

struct FileTags {
    
    private static let itemUserTagsName = "com.apple.metadata:_kMDItemUserTags"
    
    static func tags(forURL url:URL) -> [String] {
        
        guard let res = (try? url.resourceValues(forKeys: [.tagNamesKey])),
              let tags = res.tagNames else {
            return []
        }
        return tags
    }
    
    func setTag(url: URL, to tagName: TagName = TagName.red) {
        
        do {
            let resourceValues = try url.resourceValues(forKeys: [.tagNamesKey])
            var tags : [String]
            if let tagNames = resourceValues.tagNames {
                tags = tagNames
            } else {
                tags = [String]()
            }
            
            if !tags.contains(tagName.rawValue) {
                tags += [tagName.rawValue]
                try (url as NSURL).setResourceValue(tags, forKey: .tagNamesKey)
            }
            
        } catch {
            print(error)
        }
    }
    
    var tagNames = [String]()
    
    public mutating func saveTags(_ url: URL, string: [String]) -> ([String], [String]) {
        let newTagsClean = string
        var new = [String]()
        var removed = [String]()
        
        for tag in tagNames {
            if !newTagsClean.contains(tag) {
                removed.append(tag)
            }
        }
        
        for newTagClean in newTagsClean {
            if !tagNames.contains(newTagClean) {
                new.append(newTagClean)
            }
        }
        
        //        for n in new { sharedStorage.addTag(n) }
        //
        let removedFromStorage = [String]()
        //        for r in removed {
        //            if sharedStorage.removeTag(r) {
        //                removedFromStorage.append(r)
        //            }
        //        }
        
        tagNames = newTagsClean
        
#if os(OSX)
        try? (url as NSURL).setResourceValue(newTagsClean, forKey: .tagNamesKey)
#else
        let data = NSKeyedArchiver.archivedData(withRootObject: NSMutableArray(array: newTagsClean))
        do {
            try self.url.setExtendedAttribute(data: data, forName: Self.itemUserTagsName )
            //"com.apple.metadata:_kMDItemUserTags")
        } catch {
            print(error)
        }
#endif
        
        return (removedFromStorage, removed)
    }
    
    public mutating func removeAllTags(url: URL) -> [String] {
        let result = saveTags(url, string: [])
        return result.0
    }
    
    public mutating func addTag(_ url: URL, name: String) {
        guard !tagNames.contains(name) else { return }
        
        tagNames.append(name)
        
#if os(OSX)
        try? (url as NSURL).setResourceValue(tagNames, forKey: .tagNamesKey)
#else
        let data = NSKeyedArchiver.archivedData(withRootObject: NSMutableArray(array: self.tagNames))
        do {
            try url.setExtendedAttribute(data: data, forName: "com.apple.metadata:_kMDItemUserTags")
        } catch {
            print(error)
        }
#endif
    }
    
    public mutating func removeTag(_ url: URL, name: String) {
        guard tagNames.contains(name) else { return }
        
        if let i = tagNames.firstIndex(of: name) {
            tagNames.remove(at: i)
        }
        
        //        if sharedStorage.noteList.first(where: {$0.tagNames.contains(name)}) == nil {
        //            if let i = sharedStorage.tagNames.index(of: name) {
        //                sharedStorage.tagNames.remove(at: i)
        //            }
        //        }
        
        _ = saveTags(url, string: tagNames)
    }
    
    public mutating func loadTags(url: URL) {
        
#if os(OSX)
        let tags = try? url.resourceValues(forKeys: [.tagNamesKey])
        if let tagNames = tags?.tagNames {
            for tag in tagNames {
                if !self.tagNames.contains(tag) {
                    self.tagNames.append(tag)
                }
                
                //                if !project.isTrash {
                //                    sharedStorage.addTag(tag)
                //                }
            }
        }
#else
        if let data = try? url.extendedAttribute(forName: "com.apple.metadata:_kMDItemUserTags"),
           let tags = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSMutableArray {
            self.tagNames.removeAll()
            for tag in tags {
                if let tagName = tag as? String {
                    self.tagNames.append(tagName)
                    
                    //                    if !project.isTrash {
                    //                        sharedStorage.addTag(tagName)
                    //                    }
                }
            }
        }
#endif
    }
    
}
