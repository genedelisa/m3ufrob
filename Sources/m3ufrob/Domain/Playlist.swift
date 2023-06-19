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
    //let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Playlist")
    
    public var id: UUID = UUID()
    
    public var fileURL: URL
    
    @Published var playlistEntries: [PlaylistEntry] = []
    
    @Published var sortedEntries: [PlaylistEntry] = []
    
    lazy var uniqueCount: Int = {
        return self.sortedEntries.count
    }()
    lazy var count: Int = {
        return self.playlistEntries.count
    }()
    
    // TODO: inappropriate mixing. Use a display struct to print to stdout instead.
    // in displayPlaylist when not written to file
    var infFg: XTColorNameString = .cornsilk1
    var infBg: XTColorNameString = .maroon
    var urlFg: XTColorNameString = .darkMagenta
    var urlBg: XTColorNameString = .seaGreen1
    
    public init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    public init(filePath: String) {
        self.fileURL = URL(filePath: filePath)
    }

    public init(entries: [PlaylistEntry]) {
        self.playlistEntries = entries

        // TODO: what about this?
        self.fileURL = URL(filePath: ".")
    }
    
    /// Find all playlists in a directory and load them.
    ///
    /// - Parameter url: the directory url
    /// - Returns: the loaded playlists
    static func readPlaylistDirectory(_ url: URL) async -> [Playlist] {
        Logger.playlist.trace("\(#function)")
        
        let playlistFileEntries = await self.playlistsInDirectory(url)
        var playlists: [Playlist] = []
        for entry in playlistFileEntries {
            let playlist = Playlist(fileURL: entry.fileURL)
            playlists.append(playlist)
        }

        
        for playlist in playlists {
            print("doing \(playlist.id)")
            
            do {
                var lines = [String]()
                for try await var line in playlist.fileURL.lines {
                    if line.hasPrefix("[Log]") {
//                        fatalError("File \(playlist.fileURL.absoluteString) has [Log] statements ")
                        line = line.replacingOccurrences(of: "[Log] ",
                                                         with: "",
                                                         options: .literal, range: nil)
                    }
                    lines.append(line)
                }
                playlist.playlistEntries = parse(lines)
                playlist.removeDuplicates()
            } catch {
                Logger.playlist.error("Could not read contents of \(playlist.fileURL)")
            }

            
//            if let contentsOfFile = try? String(contentsOfFile: playlist.fileURL.path, encoding: .utf8) {
//                let lines = contentsOfFile.components(separatedBy: .newlines)
//                playlist.playlistEntries = parse(lines)
//                playlist.removeDuplicates()
//            } else {
//                Logger.playlist.error("Could not read contents of \(playlist.fileURL)")
//            }
        }
        return playlists
        
        //        for entry in playlistFileEntries {
        //            if let contentsOfFile = try? String(contentsOfFile: entry.fileURL.path, encoding: .utf8) {
        //                let lines = contentsOfFile.components(separatedBy: .newlines)
        //                self.playlistEntries.append(contentsOf: parse(lines) )
        
        //            } else {
        //                self.logger.error("Could not read contents of \(url)")
        //            }
        //        }
    }
    
    @MainActor
    static func playlistsInDirectory(_ url: URL)  -> [FileEntry] {
        Logger.playlist.trace("\(#function)")
        
        let keys: [URLResourceKey] = [
            .isReadableKey
        ]
        
        let options: FileManager.DirectoryEnumerationOptions = [
            .skipsHiddenFiles
        ]

        do {
            let files = try FileManager.default.contentsOfDirectory(at: url,
                                                                    includingPropertiesForKeys: keys,
                                                                    options: options)
            print("File count \(files.count) for directory \(url.absoluteString)")
            
            let playlistFiles = files.filter {
                ["m3u", "m3u8"]
                    .contains($0.pathExtension.lowercased())
            }
            print("Playlist count \(playlistFiles.count) for directory \(url.absoluteString)")
            
            let entries = playlistFiles.map { FileEntry(fileURL: $0) }
//            print("entry count \(entries.count) for ulr \(url.absoluteString)")
            
            return entries
            
        } catch {
            Logger.playlist.error("Error: \(error.localizedDescription)")
        }
        return []
    }
    
    @MainActor
    static func mergePlaylists(playlists: [Playlist]) async -> Playlist {
        Logger.playlist.trace("\(#function)")

        var playlistEntries = [PlaylistEntry]()
        
        for playlist in playlists {
            if playlist.count == 0 {
                await playlist.load()
            }
            playlistEntries.append(contentsOf: playlist.playlistEntries)
        }
        let output = Playlist(entries: playlistEntries)
        output.removeDuplicates()
        return output
    }
    
    @MainActor
    static func mergePlaylists(playlists: [Playlist], mergedFilePath: String ) async -> Playlist {
        Logger.playlist.trace("\(#function)")
        
        if FileManager.default.isWritableFile(atPath: mergedFilePath) {
            print("\(mergedFilePath) is writable file")
        }
        
        if FileManager.default.fileExists(atPath: mergedFilePath) {
            print("\(mergedFilePath) exists")
        } else {
            print("\(mergedFilePath) does not exist")
        }
        
        let output = Playlist(fileURL: URL(fileURLWithPath: mergedFilePath))
        for playlist in playlists {
            
            await playlist.load()
            output.playlistEntries.append(contentsOf: playlist.playlistEntries)
        }
        output.removeDuplicates()
        await Playlist.save(filePath: mergedFilePath, playlist: output)
        return output
    }
    
    @MainActor
    func mergeLoadedPlaylists(filePath: String, playlists: [Playlist] ) async -> Playlist {
        Logger.playlist.trace("\(#function)")
        

//
//        let home = FileManager.default.homeDirectoryForCurrentUser
//        let cwd = FileManager.default.currentDirectoryPath
//
//        let theUrl = home.appendingPathComponent("Desktop/foo.m3u8")
//        let xfileUrl = home
//            .appendingPathComponent("Desktop")
//            .appendingPathComponent("Test file")
//            .appendingPathExtension("txt")
        
        
        if FileManager.default.isWritableFile(atPath: filePath) {
            print("\(filePath) is writable file")
        }
        
        if FileManager.default.fileExists(atPath: filePath) {
            print("\(filePath) exists")
        } else {
            print("\(filePath) does not exist")
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        let output = Playlist(fileURL: fileURL)
        for playlist in playlists {
            await playlist.load()
            output.playlistEntries.append(contentsOf: playlist.playlistEntries)
        }
        output.removeDuplicates()
        await Playlist.save(filePath: filePath, playlist: output)
        return output
        
        
        //        FileManager.default.createFile(atPath: filePath, contents: <#T##Data?#>)
        
        
        
        //        if !FileManager.default.fileExists(atPath: fileURL.path) {
        //            print("\(fileURL.path) does not exist".fg(.red))
        //            do {
        //                try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)
        //            } catch let error as NSError {
        //                print(error.localizedDescription)
        //            }
        //
        //            //MainCommand.exit(withError: ExitCode.failure)
        //        }
        //
        //        let fileURL = folderURL.appendingPathComponent(documentName)

    }
    
    func loadPlaylists(playlists: [Playlist] ) async {
        Logger.playlist.trace("\(#function)")
        
        for playlist in playlists {
            await playlist.load()
        }
    }
    
    static func save(filePath: String, playlist: Playlist) async {
        Logger.playlist.trace("\(#function)")
        
//        print("writing to \(filePath)")
        
        let theString = "#EXTM3U\n" + playlist.asString()
        FileManager.default.createFile(atPath: filePath,
                                       contents: theString.data(using: .utf8))
        
        //let path = playlist.fileURL.absoluteString
        //print("writing to path \(path)")
        //        do {
        //            try "#EXTM3U\n".write(toFile: path, atomically: true, encoding: .utf8)
        //            try playlist.asString().write(toFile: path, atomically: true, encoding: .utf8)
        //        } catch {
        //            print("\(error.localizedDescription)")
        //        }
        
    }
    
    func asString(_ useTerminalColors: Bool = false) -> String {
        
        var s = ""
        if useTerminalColors {
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
        } else {
            s += "# Source: \(self.fileURL.absoluteString)\n"
            s += "# Original Count: \(self.playlistEntries.count)\n"
            s += "# Unique Count: \(self.sortedEntries.count)\n\n"
            for f in sortedEntries {
                s += "\(f.originalExtinf)"
                s += "\n"
                s += "\(f.urlString)"
                s += "\n\n"
            }
        }
        return s
    }
    
    @MainActor
    func load() async {
        Logger.playlist.trace("\(#function)")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            preconditionFailure("file expected at \(fileURL.path) is missing")
        }
        
        guard FileManager.default.isReadableFile(atPath: fileURL.path) else {
            preconditionFailure("file at \(fileURL.absoluteString) is not readable")
        }
        
        do {
            var lines = [String]()
            for try await var line in fileURL.lines {
                if line.hasPrefix("[Log]") {
                    // this is the one
                    stderr.write("File \(fileURL.absoluteString) has [Log] statements \n")
                    line = line.replacingOccurrences(of: "[Log] ",
                                                     with: "",
                                                     options: .literal, range: nil)
                }
                lines.append(line.trimmingCharacters(in: .whitespaces))
            }
            self.playlistEntries = Playlist.parse(lines)
        } catch  {
            Logger.playlist.error("Could not read contents of \(self.fileURL, privacy: .public)")
            Logger.playlist.error("\(error.localizedDescription, privacy: .public)")

            stderr.write("Could not read contents of \(self.fileURL)")
        }
        
//        do {
//            let contentsOfFile = try String(contentsOfFile: fileURL.path, encoding: .utf8)
//            let lines = contentsOfFile.components(separatedBy: .newlines)
//            self.playlistEntries = Playlist.parse(lines)
//        } catch  {
//            Logger.playlist.error("Could not read contents of \(self.fileURL, privacy: .public)")
//            Logger.playlist.error("\(error.localizedDescription, privacy: .public)")
//
//            stderr.write("Could not read contents of \(self.fileURL)")
//        }
        
//        if let contentsOfFile = try? String(contentsOfFile: fileURL.path, encoding: .utf8) {
//            let lines = contentsOfFile.components(separatedBy: .newlines)
//
//            self.playlistEntries = Playlist.parse(lines)
//
//            //            for entry in playlistEntries {
//            //                self.logger.debug("\(entry, privacy: .public)")
//            //            }
//
//        } else {
//            Logger.playlist.error("Could not read contents of \(self.fileURL)")
//        }
        
        
        
        
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
    
    //https://regex101.com
    // given CMD:VALUE return the two components
    static func parseCmdLine(_ line: String) -> (cmd: String, val: String) {
        // #cmd:value
        let extRegexp = #"#([^:]*)\s*:\s*(.*[^ ])"#
        let cmd = line.replacingOccurrences(
            of: extRegexp,
            with: "$1",
            options: .regularExpression,
            range: nil)
        let value = line.replacingOccurrences(
            of: extRegexp,
            with: "$2",
            options: .regularExpression,
            range: nil)
        Logger.playlist.debug("cmd: \(cmd, privacy: .public)")
        Logger.playlist.debug("value: \(value, privacy: .public)")

        return(cmd, value)
    }
    
    // really simple minded. Just the extinf with dur and title and the url on the next line.
    internal static func parse(_ lines: [String]) -> [PlaylistEntry] {
        Logger.playlist.trace("\(#function)")
        //print("\(#function)")
        
        enum ParseState {
            case begin, hasExtInf, hasURL
        }
        
        var parseState: ParseState = .begin
        
        var results = [PlaylistEntry]()
        
        // # is a swift 5 raw string to avoid escaping.
        //        let extinfoRegexp = #"(#EXTINF:)([+-]?([0-9]*[.])?[0-9]+),(.*)"#
        let extinfoRegexp = #"(#EXTINF:)\s*([+-]?([0-9]*[.])?[0-9]+),\s*(.*)"#
        
        // there is also this:
        // #EXTINF:-1 tvg-logo="https://upload.wikimedia.org/wikipedia/commons/thumb/a/a8/Mezzo_Logo.svg/1280px-Mezzo_Logo.svg.png" group-title="Music",Mezzo

        // #EXTIMG: "https etc
        let extImgRegexp = #"(#EXTIMG:)\s*(.*)"#
        
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
            
            if parseState == .begin {
                entry = PlaylistEntry()
            }
            
            if line.hasPrefix("#") {
                Logger.playlist.debug("# \(line, privacy: .public)")
                
                //let (cmd,val) = parseCmdLine(line)
                let tup = parseCmdLine(line)
                Logger.playlist.debug("cmd \(tup.cmd, privacy: .public)")
                Logger.playlist.debug("val \(tup.val, privacy: .public)")
                entry.commmands[tup.cmd] = tup.val
            }
            
            // #EXTINF:0, the title
            if line.hasPrefix("#EXTINF") {
                Logger.playlist.debug("EXTINF: \(line, privacy: .public)")
                
                let durationString = line.replacingOccurrences(of: extinfoRegexp,
                                                               with: "$2",
                                                               options: .regularExpression,
                                                               range: nil)
                
                let titleString = line.replacingOccurrences(of: extinfoRegexp,
                                                            with: "$4",
                                                            options: .regularExpression,
                                                            range: nil)
                
                
                Logger.playlist.debug("title: \(titleString, privacy: .public)")
                Logger.playlist.debug("duration: \(durationString, privacy: .public)")
                
                entry.originalExtinf = line
                entry.title = titleString
                if let d = Double(durationString) {
                    entry.duration = d
                }
                //entry.duration = Double(durationString)!
                parseState = .hasExtInf
                
                //            } else if line.hasPrefix("#") {
                //                logger.debug("comment line: \(line, privacy: .public)")
                //                // continue
                
            } else if line.hasPrefix("http") {
                Logger.playlist.debug("http line: \(line, privacy: .public)")
                entry.urlString = line
                results.append(entry)
                
                // the url is the terminal state.
                // this resets and creates a new entry
                parseState = .begin
                
            } else if line.hasPrefix("#EXTIMG") {
                Logger.playlist.debug("EXTIMG: \(line, privacy: .public)")
                    
                let imgURLString = line.replacingOccurrences(of: extImgRegexp,
                                                             with: "$2",
                                                             options: .regularExpression,
                                                             range: nil)
                //print("imgURLString: \(imgURLString)")
                entry.extImgURLString = imgURLString

                // keep going
                parseState = .hasExtInf
                
            } else if line.hasPrefix("#EXTGRP") {
                Logger.playlist.debug("EXTGRP line: \(line, privacy: .public)")
                parseState = .hasExtInf

            } else {
                
                // doesn't have prefix #EXT i.e. the url
                Logger.playlist.debug("non #EXT line: \(line, privacy: .public)")
                
                //                if parseState == .hasExtInf {
                //                    entry.urlString = line
                //                    results.append(entry)
                //                }
                
                // reset
                parseState = .begin
            }
        } // for
        
        return results
    } // parse
    
    
    
    // TODO: move this to a different struct
    //    func displayPlaylist(_ outputURL: URL? = nil) {
    func displayPlaylist(_ path: String? = nil, comments: Bool = false) {
        

        
        if let path {
            //            print("\(outputURL)")
            //            var urlString = outputURL.relativeString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            //            print("\(urlString)")
            
            var s = "#EXTM3U\n"
            if comments {
                s += "# Source: \(self.fileURL.absoluteString)\n"
                s += "# Original Count: \(self.playlistEntries.count)\n"
                s += "# Unique Count: \(self.sortedEntries.count)\n\n"
            }
//            for f in sortedEntries {
//                s += "\(f.originalExtinf)\n"
//                //s += "\n"
//                s += "\(f.urlString)\n\n"
//            }
            
            for f in sortedEntries {
                for (k,v) in f.commmands {
                    s += "#\(k): "
                    s += "\(v)\n"
                }
                s += "\(f.urlString)\n\n"
            }
            
           
            
            do {
                try s.write(toFile: path, atomically: true, encoding: .utf8)
                //                try s.write(toFile: outputURL.relativePath, atomically: true, encoding: .utf8)
                //                try s.write(toFile: outputURL.absoluteString, atomically: true, encoding: .utf8)
                
            } catch {
                print("\(error.localizedDescription)".fg(.red))
            }
            
        } else {
            
            Terminal.shared.display(entries: sortedEntries)
            
//            var s = "#EXTM3U\n"
//            if comments {
//                s += "# Source: \(self.fileURL.absoluteString)\n"
//                s += "# Original Count: \(self.playlistEntries.count)\n"
//                s += "# Unique Count: \(self.sortedEntries.count)\n\n"
//            }
//            for f in sortedEntries {
//                s += "\(f.originalExtinf)"
//                    //.fg256(infFg).bg256(infBg)
//                s += "\n"
//                s += "\(f.urlString)"
//                    //.fg256(urlFg).bg256(urlBg)
//                s += "\n\n"
//            }
//            print(s)
            
            
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
    
    func totalDuration() -> String {
        let totalDuration = self.sortedEntries.reduce(0) { $0 + $1.duration }
        return TimeUtils.secondsToHMS(Int(totalDuration))
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

extension Playlist: Hashable {
    public static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.fileURL)
        hasher.combine(self.description)
    }
}


