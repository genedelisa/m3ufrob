//
// File:         Sources
// Project:    m3ufrob
// Package: m3ufrob
// Product:  
//
// Created by Gene De Lisa on 5/4/23
//
// Using Swift 5.0
// Running macOS 13.3
// Github: https://github.com/genedelisa/m3ufrob
// Product: https://rockhoppertech.com/
//
// Follow me on Twitter: @GeneDeLisaDev
//
// Licensed under the MIT License (the "License");
//
// You may not use this file except in compliance with the License.
//
// You may obtain a copy of the License at
//
// https://opensource.org/licenses/MIT


import Foundation
import os.log

class m3ufrobClass {
    
    func list(url: URL) async throws {
        let fm = FileManager.default
        let df = DateFormatter()
        df.dateStyle = .long
        
        do {
            let fileURLS = try fm.contentsOfDirectory(at: url,
                                                      includingPropertiesForKeys: [.attributeModificationDateKey,
                                                                                   .creationDateKey,
                                                                                   .contentTypeKey,
                                                                                   .fileSizeKey
                                                      ],
                                                      options: [.skipsHiddenFiles])
            
            
            let mediaURLS = fileURLS.filter { (url: URL) in
                if ["flac", "mp3", "mp4", "mkv"].contains(url.pathExtension) {
                    return true
                }
                return false
            }
            
            //            print("media files")
            print("#EXTM3U\n")
            
            for fileURL in mediaURLS {
                
                //                    let fileName = fileURL.standardizedFileURL.lastPathComponent
                let fileName = fileURL.standardizedFileURL.absoluteString
                print("\(fileName)")
                print()
                
                //                    let path = fileURL.standardizedFileURL.path
                
                //                    let fileNameNoExt = fileURL.standardizedFileURL.deletingPathExtension().lastPathComponent
                //
                //print("display name: \(fm.displayName(atPath: path)) ")
                
                //                let a = try fm.attributesOfItem(atPath: path)
                //                for (k,v) in a {
                //                    print("\(k) : \(v)")
                //                }
                //                if let cd = a[FileAttributeKey.creationDate]  as? Date {
                //                    print("creation date \(cd)")
                //                    print("creation date \(df.string(from: cd))")
                //                }
                //
                //                let rv = try fileURL.resourceValues(forKeys: [.contentTypeKey])
                //                if let value = rv.contentType {
                //                    print("content type: \(value)")
                //                }
                
            }
            //            }
            
            //            print()
            //            print("all files")
            //            for fileURL in fileURLS {
            //                print("\(fileURL.absoluteString)")
            //                print("\(fileURL.lastPathComponent)")
            //                print("\(fileURL.pathExtension)")
            //            }
            
        } catch {
            print(" \(error)")
        }
        
    }
    
    func list(path: String) {
        let fm = FileManager.default
        let df = DateFormatter()
        df.dateStyle = .long
        
        do {
            let fileNames = try fm.contentsOfDirectory(atPath: path)
            for fileName in fileNames {
                print("\(fileName)")
                print("\(fm.displayName(atPath: fileName))")
                let a = try fm.attributesOfItem(atPath: fileName)
                // print(" \(a)")
                if let cd = a[FileAttributeKey.creationDate]  as? Date {
                    print("creation date \(cd)")
                    print("creation date \(df.string(from: cd))")
                }
                if let v = a[FileAttributeKey.modificationDate]  as? Date {
                    print("modification \(v)")
                }
                if let v = a[FileAttributeKey.size] {
                    print("size \(v)")
                }
                if let v = a[FileAttributeKey.extensionHidden] {
                    print("ext hidden \(v)")
                }
                if let v = a[FileAttributeKey.ownerAccountName] {
                    print("owner \(v)")
                }
                
                if let v = a[FileAttributeKey.groupOwnerAccountName] {
                    print("groupOwnerAccountName \(v)")
                }
                if let v = a[FileAttributeKey.posixPermissions]  as? NSNumber {
                    // print("posixPermissions \(v.int16Value)")
                    let octal = String(format: "%02o", v.int16Value)
                    print("posixPermissions \(octal)")
                }
                if let v = a[FileAttributeKey.immutable] {
                    print("immutable \(v)")
                }
                if let v = a[FileAttributeKey.size] {
                    print("size \(v)")
                }
                
                //                let creationDate = attributes[.creationDate]
                
                print()
                
            }
            
        } catch {
            Logger.service.error("Error: \(error.localizedDescription)")
        }
    }
    
    //    internal func permissionChar(perm: Int16) {
    //        var _: Int16 = 0o755
    //
    //        let userMask: Int16 = 0b00000001_11000000
    //        let groupMask: Int16 = 0b00000000_00111000
    //        let otherMask: Int16 = 0b00000000_00000111
    //
    //        var value: Int16 = perm & userMask
    //        value = perm & groupMask
    //        value = perm & otherMask
    //
    //        if perm & 0b1 != 0 {
    //
    //        }
    //
    //    }
    
    func doSomething() {
        let fm = FileManager.default
        let path = Bundle.main.resourcePath!
        
        do {
            let items = try fm.contentsOfDirectory(atPath: path)
            
            for item in items {
                print("Found \(item)")
            }
            
        } catch {
            Logger.service.error("Error: \(error.localizedDescription)")
        }
        
    }
    
}
