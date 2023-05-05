//
// File:         File.swift
// Project:    
// Package: 
// Product:  
//
// Created by Gene De Lisa on 5/4/23
//
// Using Swift 5.0
// Running macOS 13.3
// Github: https://github.com/genedelisa/
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
import Combine
import os.log
import GDTerminalColor

public class Playlist: Identifiable, ObservableObject {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Playlist")
    
    public var id: UUID = UUID()
    
    public var fileURL: URL
    
    @Published var playlistEntries: [PlaylistEntry] = []
    
    @Published var sortedEntries: [PlaylistEntry] = []
    
    // in displayPlaylist when not written to file
    var infFg: XTColorNameString = .cornsilk1
    var infBg: XTColorNameString = .maroon
    var urlFg: XTColorNameString = .darkMagenta
    var urlBg: XTColorNameString = .seaGreen1
    
    
    public init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    //    public init(fileURL: URL) async {
    //        self.fileURL = fileURL
    //        await self.load()
    //    }
    
    func load() async {
        self.logger.trace("\(#function)")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            preconditionFailure("file expected at \(fileURL.path) is missing")
        }
        
        guard FileManager.default.isReadableFile(atPath: fileURL.path) else {
            preconditionFailure("file at \(fileURL.absoluteString) is not readable")
        }
        
        if let contentsOfFile = try? String(contentsOfFile: fileURL.path, encoding: .utf8) {
            let lines = contentsOfFile.components(separatedBy: .newlines)
            
            self.playlistEntries = parse(lines)
            
            //            for entry in playlistEntries {
            //                self.logger.debug("\(entry, privacy: .public)")
            //            }
            
        } else {
            self.logger.error("Could not read contents of \(self.fileURL)")
        }
        
        
        
        //self.playlistEntries.sort()
        
        // self.playlistEntries = self.playlistEntries.sorted { $0.title < $1.title }
        //        self.playlistEntries = self.playlistEntries.sorted { $0.urlString < $1.urlString }
        
        //        self.playlistEntries.sort { a, b in
        //            a.urlString < b.urlString
        //        }
        
        
        //        let titleDescriptor = SortDescriptor<PlaylistEntry>(\PlaylistEntry.title,
        //                                             comparator: .localizedStandard)
        //        let sorted = self.playlistEntries.sorted(by: titleDescriptor)
        //        let sorted = self.playlistEntries.sorted(using: titleDescriptor)
        
        
        //        let sortByTitle: SortDescriptor<PlaylistEntry> =
        //        sortDescriptor(key: { $0.title }, String.localizedCaseInsensitiveCompare)
        
        
        // introspection problem
        //        let urlSortDescriptor = SortDescriptor(\PlaylistEntry.urlString, order: .forward)
        //        self.playlistEntries.sort(using: urlSortDescriptor)
        //
        //        let titleSortDescriptor = SortDescriptor(\PlaylistEntry.title, order: .forward)
        //        self.playlistEntries.sort(using: titleSortDescriptor)
    }
    
    // really simple minded. Just the extinf with dur and title and the url on the next line.
    internal func parse(_ lines: [String]) -> [PlaylistEntry] {
        self.logger.trace("\(#function)")
        
        enum ParseState {
            case empty, hasExtInf, hasURL
        }
        
        var parseState: ParseState = .empty
        
        var results = [PlaylistEntry]()
        
        // # is a swift 5 raw string to avoid escaping.
//        let extinfoRegexp = #"(#EXTINF:)([+-]?([0-9]*[.])?[0-9]+),(.*)"#
        let extinfoRegexp = #"(#EXTINF:)\s*([+-]?([0-9]*[.])?[0-9]+),\s*(.*)"#
        
        var entry = PlaylistEntry()
        
        for var line in lines {
            line = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if line.isEmpty {
                continue
            }
            
            // the "header"
            if line.hasPrefix("#EXTM3U") {
                continue
            }
            
            if parseState == .empty {
                entry = PlaylistEntry()
            }

            // #EXTINF:0, the title
            if line.hasPrefix("#EXTINF") {
                logger.debug("EXTINF: \(line, privacy: .public)")
                
                let durationString = line.replacingOccurrences(of: extinfoRegexp,
                                                               with: "$2",
                                                               options: .regularExpression,
                                                               range: nil)
                
                let titleString = line.replacingOccurrences(of: extinfoRegexp,
                                                            with: "$4",
                                                            options: .regularExpression,
                                                            range: nil)
                

                logger.debug("title: \(titleString, privacy: .public)")
                logger.debug("duration: \(durationString, privacy: .public)")
                
                entry.originalExtinf = line
                entry.title = titleString
                entry.duration = Double(durationString)!
                parseState = .hasExtInf
                
//            } else if line.hasPrefix("#") {
//                logger.debug("comment line: \(line, privacy: .public)")
//                // continue
                
            } else if line.hasPrefix("http") {
                logger.debug("http line: \(line, privacy: .public)")
                entry.urlString = line
                results.append(entry)
                parseState = .empty

            } else {
                
                // doesn't have prefix #EXT i.e. the url
                logger.debug("non #EXT line: \(line, privacy: .public)")
                
//                if parseState == .hasExtInf {
//                    entry.urlString = line
//                    results.append(entry)
//                }
                
                // reset
                parseState = .empty
            }
        } // for
        
        return results
    } // parse

 

    
//    func displayPlaylist(_ outputURL: URL? = nil) {
    func displayPlaylist(_ path: String? = nil) {
        
        if let path {
//            print("\(outputURL)")
//            var urlString = outputURL.relativeString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
//            print("\(urlString)")
            
            var s = "#EXTM3U\n"
            s += "# Source: \(self.fileURL.absoluteString)\n"
            s += "# Original Count: \(self.playlistEntries.count)\n"
            s += "# Unique Count: \(self.sortedEntries.count)\n\n"
            for f in sortedEntries {
                s += "\(f.originalExtinf)\n"
                s += "\n"
                s += "\(f.urlString)\n\n"
            }
            
            do {
                try s.write(toFile: path, atomically: true, encoding: .utf8)
//                try s.write(toFile: outputURL.relativePath, atomically: true, encoding: .utf8)
//                try s.write(toFile: outputURL.absoluteString, atomically: true, encoding: .utf8)
                
            } catch {
                print("\(error.localizedDescription)")
            }
            
        } else {
            
            var s = "#EXTM3U\n"
            s += "# Source: \(self.fileURL.absoluteString)\n"

            s += "# Original Count: \(self.playlistEntries.count)\n"
            s += "# Unique Count: \(self.sortedEntries.count)\n\n"
            for f in sortedEntries {
                s += "\(f.originalExtinf)"
                .fg256(infFg).bg256(infBg)
                s += "\n"
                s += "\(f.urlString)"
                .fg256(urlFg).bg256(urlBg)
                s += "\n\n"
            }
            
            
            print(s)
            
//            print("#EXTM3U\n")
//
//            print("# Source: \(self.fileURL.absoluteString)")
//            print("# Original Count: \(self.playlistEntries.count)")
//            print("# Unique Count: \(self.sortedEntries.count)\n")
//
//            for f in sortedEntries {
//                print("\(f.originalExtinf)")
//                print("\(f.urlString)\n")
//            }
        }
    }
    
    func removeDuplicates() {
        // unlike Unix uniq, it doesn't have to be sorted first
        //        self.playlistEntries.sort { a, b in
        //            a.urlString < b.urlString
        //        }
        
        let unique = Array<PlaylistEntry>(Set<PlaylistEntry>(self.playlistEntries))
        
        self.sortedEntries = unique
        
        // the Set changed the order
        self.sortedEntries.sort { a, b in
            a.urlString < b.urlString
        }
    }
}

extension Playlist: CustomStringConvertible {
    public var description: String {
        var s = "\(type(of: self))\n"
        s += "fileURL: \(fileURL)\n\n"
        for f in playlistEntries {
            s += f.description
            s += "\n"
        }
        return s
    }
}
