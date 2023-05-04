// File:    FileEntry.swift
// Project: MIDIPlayer
// Package: MIDIPlayer
// Product: MIDIPlayer
//
// Created by Gene De Lisa on 10/6/21
//
// Using Swift 5.0
// Running macOS 11.6
// Github: https://github.com/genedelisa/MIDIPlayer
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
//import SwiftUI
import Combine
import os.log


public final class FileEntry: Identifiable, ObservableObject {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "FileEntry")
    
    public var id = UUID()
    
    public var fileURL: URL
    
    @Published var playlistEntries: [PlaylistEntry] = []
    
    public init(fileURL: URL) {
        self.fileURL = fileURL
        self.load()
    }
    
    public func justName() -> String {
        fileURL.deletingPathExtension().lastPathComponent
    }
    
    func load() {
        self.logger.trace("\(#function)")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            preconditionFailure("file expected at \(fileURL.path) is missing")
        }
        
        guard FileManager.default.isReadableFile(atPath: fileURL.path) else {
            preconditionFailure("file at \(fileURL.absoluteString) is not readable")
        }

        if let contentsOfFile = try? String(contentsOfFile: fileURL.path, encoding: .utf8) {
            let components = contentsOfFile.components(separatedBy: .newlines)
            self.playlistEntries = parse(array: components)
            
            for entry in playlistEntries {
                print(" \(entry)")
            }
            
        } else {
            print("Could not read contents of \(fileURL)")
        }
    }
    
    // really simple minded. Just the extinf with dur and title and the url on the next line.
    internal func parse(array: [String]) -> [PlaylistEntry] {
        self.logger.trace("\(#function)")

        enum ParseState {
            case empty, hasExtInf, hasURL
        }
        
        var parseState: ParseState = .empty
        
        var results = [PlaylistEntry]()

        // # is a swift 5 raw string to avoid escaping.
        let extinfoRegexp = #"(#EXTINF:)([+-]?([0-9]*[.])?[0-9]+),(.*)"#

        var entry = PlaylistEntry()
        
        for line in array {
            
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

            if line.hasPrefix("#EXTINF") {
                
                // #EXTINF:0, the title
                
                let durationString = line.replacingOccurrences(of: extinfoRegexp,
                                                               with: "$2",
                                                               options: .regularExpression,
                                                               range: nil)
                
                let titleString = line.replacingOccurrences(of: extinfoRegexp,
                                                            with: "$4",
                                                            options: .regularExpression,
                                                            range: nil)
                
                print("title: '\(titleString)'")
                print("duration: \(durationString)")
                entry.title = titleString
                entry.duration = Double(durationString)!
                parseState = .hasExtInf
            }

            else { // doesn't have prefix #EXT i.e. the url
                print("non #EXT line: \(line)\n")
                
                if parseState == .hasExtInf {
                    entry.urlString = line
                    results.append(entry)
                }

                // reset
                parseState = .empty
            }

            
        } // for
        
       
        
        return results
        
    } // parse

    
}

extension FileEntry: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case fileURL
        //        case urlString = "url_string"
    }
    
}

extension FileEntry: Equatable {
    public static func == (lhs: FileEntry, rhs: FileEntry) -> Bool {
        lhs.id == rhs.id &&
        lhs.fileURL == rhs.fileURL
    }
}

extension FileEntry: Comparable {
    public static func < (lhs: FileEntry, rhs: FileEntry) -> Bool {
        return lhs.fileURL.path < rhs.fileURL.path
    }
}

extension FileEntry: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.fileURL)
    }
}
extension FileEntry: CustomStringConvertible {
    
    public var description: String {
        var s = "\(type(of: self))\n"
        
        s += "id: \(id)\n"
        s += "fileURL: \(fileURL)\n"
        //        s += "urlString: \(urlString)\n"
        
        return s
    }
}
