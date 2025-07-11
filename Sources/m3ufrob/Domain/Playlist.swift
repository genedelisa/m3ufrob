// File:       Playlist.swift
// Project:    m3u8frob
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
import RegexBuilder

//: NSObject, NSCopying {
//func copy(with zone: NSZone? = nil) -> Any {
//    let copy = Playlist(entries: this.playlistEntries)
//    return copy
//}

public class Playlist: Identifiable, ObservableObject {
    //let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Playlist")
    
//    enum SortField: CaseIterable {
//        case urlString
//        case title
//    }
    
    static let parser = PlaylistParser()

    public var id: UUID = UUID()

    public var fileURL: URL?
    
    public var readFromStdin = false

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

    public init() {

    }
    
    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public init(filePath: String) {
        self.fileURL = URL(filePath: filePath)
    }

    public init(entries: [PlaylistEntry], sortedEntries: [PlaylistEntry] = []) {
        self.playlistEntries = entries
        self.sortedEntries = sortedEntries
        
        // TODO: what about this?
        // self.fileURL = URL(filePath: ".")
    }

    func foo() {
//        NSURL *fileURL = [NSURL fileURLWithPath:@"/Users/[username]/Documents/[some_file]"];
//        NSError *resourceError;
//        if (![fileURL setResourceValue:@(2) forKey:NSURLLabelNumberKey error:&resourceError]) {
//            NSLog(@"Error while setting file resource: %@", [resourceError localizedDescription]);
//        }
//        var values = URLResourceValues()
//        values.tagNames = [""]
//        self.fileURL.setResourceValues(values)
        
        
//        let resourceKeys: [URLResourceKey] = [
//            .tagNamesKey
//        ]
//        var resourceValues: URLResourceValues
//        do {
//            if let fileURL {
//                resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
//                //if let tagNames = resourceValues.tagNames {
//                    //                tagNames
//                //}
//            }
//        } catch let error {
//            debugPrint("error: \(error.localizedDescription)")
//        }
        
        
        
        
    }
    
    func setTag(name: String) async throws {
        var tagValues: [String]
        if let fileURL {
            let tags = try fileURL.resourceValues(forKeys: [URLResourceKey.tagNamesKey])
            if let tagNames = tags.tagNames {
                tagValues = tagNames
                if tagValues.contains(name) {
                    return
                }
                tagValues.append(name)
            } else {
                tagValues = [name]
            }
            
            //try fileURL.setResourceValue(tagValues, forKey: .tagNamesKey)
            
            let url = fileURL as NSURL
            try url.setResourceValue(tagValues, forKey: .tagNamesKey)
        }
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
            //print("doing \(playlist.id)")
            
            if let purl = playlist.fileURL {
                Logger.playlist.debug("\tat path \(purl.path())")
                do {
                    var lines = [String]()
                    for try await var line in purl.lines {
                        if line.hasPrefix("[Log]") {
                            // fatalError("File \(playlist.fileURL.absoluteString) has [Log] statements ")
                            line = line.replacingOccurrences(of: "[Log] ",
                                                             with: "",
                                                             options: .literal, range: nil)
                        }
                        lines.append(line)
                    }
                    
                    playlist.playlistEntries = parser.parse(lines)
                    playlist.removeDuplicates()
                } catch {
                    Logger.playlist.error("Could not read contents of \(purl)")
                }
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
            print("Playlist count \(playlistFiles.count) for directory \(url.path())")

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

        // this will also sort
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
//            s += "# Source: \(self.fileURL.absoluteString)\n"
            s += "# Original Count: \(self.playlistEntries.count)\n"
            s += "# Unique Count: \(self.sortedEntries.count)\n\n"
            for f in sortedEntries {
//                s += "\(f.originalExtinf)"
                s += "\(f.extInf)"
                    .fg256(infFg).bg256(infBg)
                s += "\n"
                s += "\(f.urlString)"
                    .fg256(urlFg).bg256(urlBg)
                s += "\n\n"
            }
        } else {
//            s += "# Source: \(self.fileURL.absoluteString)\n"
            s += "# Original Count: \(self.playlistEntries.count)\n"
            s += "# Unique Count: \(self.sortedEntries.count)\n\n"
            for f in sortedEntries {
//                s += "\(f.originalExtinf)"
                s += "\(f.extInf)"
                s += "\n"
                s += "\(f.urlString)"
                s += "\n\n"
            }
        }
        return s
    }

    @MainActor
    func loadFromStdin() async {
        Logger.playlist.trace("\(#function)")
        
        do {
            var lines = [String]()
            
            while var line = readLine() {
//            for try await var line in fileURL.lines {
                
                if line.hasPrefix("[Log]") {
                    line = line.replacingOccurrences(of: "[Log] ",
                                                     with: "",
                                                     options: .literal, range: nil)
                }
                lines.append(line.trimmingCharacters(in: .whitespaces))
            }
            self.playlistEntries = Playlist.parser.parse(lines)
        } catch  {
            Logger.playlist.error("Could not read stdin")
            Logger.playlist.error("\(error.localizedDescription, privacy: .public)")
            stderr.write("Could not read stdin")
        }
    }
    
    @MainActor
    func load() async {
        Logger.playlist.trace("\(#function)")
        if let fileURL {
            Logger.playlist.debug("calling loading from \(fileURL)")
            do {
                try await load(fileURL: fileURL)

            } catch CommandError.notARegularFile(let errorMessage) {
                stderr.write("\(errorMessage)\n".fg(.red))
                MainCommand.exit(withError: .none)
            } catch {
                stderr.write("\(error.localizedDescription)\n")
                MainCommand.exit(withError: .none)
            }
            
        }
    }
    
    @MainActor
    func load(fileURL: URL) async throws {
        Logger.playlist.trace("\(#function)")
        Logger.playlist.debug("loading from \(fileURL)")

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir) else {
            preconditionFailure("file expected at \(fileURL.path) is missing")
        }
        if isDir.boolValue {
            throw CommandError.notARegularFile("Cannot read a directory: \(fileURL.path)")
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
                
                // TODO: remove this eventually
                if let s = lineWithDupeRemoved(line) {
                    line = s
                }
                
                lines.append(line.trimmingCharacters(in: .whitespaces))
            }
            self.playlistEntries = Playlist.parser.parse(lines)
            
        } catch  {
            Logger.playlist.error("Could not read contents of \(fileURL, privacy: .public)")
            Logger.playlist.error("\(error.localizedDescription, privacy: .public)")

            stderr.write("Could not read contents of \(fileURL)")
        }
        //print(self)

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
    
    
    // I had files with the EXTINF duplicated on each info line
    // #EXTINF:10,the title #EXTINF:10,the title
    
    func lineWithDupeRemoved(_ line: String) -> String? {

        do {
            let multiPattern = #"#EXTINF:"#
            
            let multiRegex = try NSRegularExpression(
                pattern: multiPattern,
                options: []
            )
            
            let lineRange = NSRange(
                line.startIndex..<line.endIndex,
                in: line
            )
            
            let multiMatches = multiRegex.matches(
                in: line,
                options: [],
                range: lineRange
            )
            //print("There are \(multiMatches.count) multi matches in\n\(line)")
            
            if multiMatches.count > 1 {
                let ranges = line.ranges(of: "#EXTINF:")
                if ranges.count > 1 {
                    let r = line.startIndex..<ranges[1].lowerBound
                    let sub = String(line[r])
                    //print("sub: |\(sub)|")
                    return sub
                }
            } else {
                return nil
            }
        } catch {
            print("\(error)")
            return nil
        }
        return nil
    }
    
    static func parseCmdLine(_ line: String) throws -> (cmd: String, dur:Double, title: String) {
//    func extinfoParse(info: String) throws -> (cmd:String, dur:Float, title:String) {
        //let regexp1 = /^#(?<cmd>.+?:)\s*(?<dur>[-+]?[0-9]+\.[0-9]+?|\.[0-9]+)\s*:(?<title>.*)/
        
        //let regexp = #/^#(?<cmd>.+?):\s*(?<dur>[-+]?[0-9]*\.*[0-9]+?|\.[0-9]+),\s*(?<title>[^:]*)/#
//        let regexp =         ^(?<cmd>#EXTINF):\s*(?<dur>[-+]?[0-9]*\.*[0-9]+?|\.[0-9]+),\s*(?<title>[[:space:][:alnum:]\.]*)/
        
        

       // /^(?<cmd>#EXTINF):\s*(?<dur>[-+]?[0-9]*\.*[0-9]+?|\.[0-9]+),\s*(?<title>[[:space:][:alnum:]'&\.\#\:-]*)/
//        /(#EXTINF:)?([+-]?[[:space:][:digit:]\.]*),([:alnum:][:space:]['&.-]*)/
        
//        let regexp =
//        /(?<cmd>#EXTINF:)?(?<dur>[+-]?[[:space:][:digit:]\.]*),(?<title>[[:alnum:][:space:]['&.-]]*)/
        

//        /(?<cmd>#EXTINF:)?(?<dur>[+-]?[[:space:][:digit:]\.]*)\s*,\s*(?<title>[a-zA-Z0-9&;,.[:space:]]*)/


//        /(?<cmd>#EXTINF:)?(?<dur>[+-]?[[:space:][:digit:]\.]*)\s*,\s*(?<title>[[:space:]À-úa-zA-Z0-9&?:|;,.'()!-]*)/

        let regexp =
        /(?<cmd>#EXTINF:)?(?<dur>[+-]?[[:space:][:digit:]\.]*)\s*,\s*(?<title>.*)/
        
        if line.contains("EXTINF") {
            do {
                
//                if let result = try regexp.wholeMatch(in: line.dropFirst()) {
                if let result = try regexp.wholeMatch(in: line) {
//                    print("Cmd: \(result.cmd)")
//                    print("Dur: \(result.dur)")
//                    print("Title: \(result.title)")
                    if let d = Double(result.dur),
                       let cmd=result.cmd {
                       // print("returning \(cmd) \(d) \(result.title)")
                        return (String(cmd), d, String(result.title) )
                    }
                    throw PlaylistError.badInput(message: "cannot parse:\(line)")
                } else {
                    //print("no regexp match for:")
                    print("\(line)\n")
                    //print("\(regexp)\n")
                }
            } catch {
                print("\(error.localizedDescription)")
                throw error
            }
            throw PlaylistError.badInput(message: "Shouldn't get here")
        }
        throw PlaylistError.badInput(message: "Shouldn't get here")

        
//        if line.contains("EXTIMG") {
//            print("Why am I getting an image?")
//            print("\(line)")
//        }

       
        
    }


    //https://regex101.com
    // given CMD:VALUE return the two components
//    static func xparseCmdLine(_ line: String) -> (cmd: String, val: String) {
//        // #cmd:value
////        let extRegexp = #"#([^:]*)\s*:\s*(.*[^ ])"#
//
////        let extRegexp = #"#([^:]*)\s*:-?(\d*\.\d+),\s*(.*[^ ])"#
//        let extImgRegexp = #"#(EXTIMG:)\s*(.*)"#
////        let extRegexp =   #"^(#EXTINF:+)[\s]*(-?\d+),+([[:alnum:] ()-\.]*)"#
//       // let extRegexp = #"(#EXTINF):\s*(-?\d*\.?\d+),(.*)"#
//        let extRegexp  = #/^#(?<cmd>.+?):\s*(?<dur>[-+]?[0-9]*\.*[0-9]+?|\.[0-9]+)\s*:(?<title>[^:]*)/#
//
//        var regexp = extRegexp
//        
////        if line.prefix == "EXTINFO" {
////        } else if line.prefix == "EXTIMG" {
////            
////        } else if line.prefix == "" {
////            
////        } else {
////            print("wtf line: \(line)")
////        }
//
//        if line.contains("EXTINF") {
//            regexp = extRegexp
//        }
//        
//        if line.contains("EXTIMG") {
//            regexp = extImgRegexp
//        }
//        
//        let cmd = line.replacingOccurrences(
//            of: regexp,
//            with: "$1",
//            options: .regularExpression,
//            range: nil)
//        let dur = line.replacingOccurrences(
//            of: regexp,
//            with: "$2",
//            options: .regularExpression,
//            range: nil)
//        let value = line.replacingOccurrences(
//            of: regexp,
//            with: "$3",
//            options: .regularExpression,
//            range: nil)
//        Logger.playlist.debug("cmd: \(cmd, privacy: .public)")
//        Logger.playlist.debug("dur: \(dur, privacy: .public)")
//        Logger.playlist.debug("value: \(value, privacy: .public)")
//
//        return(cmd, value)
//    }
    
    static func parseImgCmdLine(_ line: String) -> (cmd: String, val: String) {

        let regexp = #"(#EXTIMG):\s*(.*)"#
        
        let cmd = line.replacingOccurrences(
            of: regexp,
            with: "$1",
            options: .regularExpression,
            range: nil)

        let value = line.replacingOccurrences(
            of: regexp,
            with: "$2",
            options: .regularExpression,
            range: nil)
        Logger.playlist.debug("cmd: \(cmd, privacy: .public)")
        Logger.playlist.debug("value: \(value, privacy: .public)")

        return(cmd, value)
    }

    // really simple minded. Just the extinf with dur and title and the url on the next line.
    internal static func xparse(_ lines: [String]) -> [PlaylistEntry] {
        Logger.playlist.trace("\(#function)")
        //print("\(#function)")

        enum ParseState {
            case begin, hasExtInf, hasURL
        }

        var parseState: ParseState = .begin

        var results = [PlaylistEntry]()

        // # is a swift 5 raw string to avoid escaping.
        //        let extinfoRegexp = #"(#EXTINF:)([+-]?([0-9]*[.])?[0-9]+),(.*)"#
//        let extinfoRegexp = #"(#EXTINF:)\s*([+-]?([0-9]*[.])?:[0-9]+),\s*(.*)"#
//        let extinfoRegexp = #"^(#EXTINF:+)[\s]*(-?\d+),+([[:alnum:] ()-\.]*)"#

        //let extinfoRegexp = #"#([^:]*)\s*:(-?\d*\.\d+),\s*(.*[^ ])"#
        //let extinfoRegexp = #"(#EXTINF):\s*-?(\d*\.?\d+),(.*)"#
        // there is also this:
        // #EXTINF:-1 tvg-logo="https://upload.wikimedia.org/wikipedia/commons/thumb/a/a8/Mezzo_Logo.svg/1280px-Mezzo_Logo.svg.png" group-title="Music",Mezzo

        // #EXTIMG: "https etc
//        let extImgRegexp = #"(#EXTIMG:)\s*(.*)"#
        let extImgRegexp = #"#(EXTIMG:)\s*(.*)"#

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
                
                if line.hasPrefix("#EXTIMG") {
                    let tup = parseImgCmdLine(line)
                    Logger.playlist.debug("cmd \(tup.cmd, privacy: .public)")
                    Logger.playlist.debug("val \(tup.val, privacy: .public)")
                    entry.commmands[tup.cmd] = tup.val
                }
                if line.hasPrefix("#EXTINF") {
                    do {
                        let tup = try parseCmdLine(line)
                        Logger.playlist.debug("cmd: \(tup.cmd, privacy: .public)")
                        Logger.playlist.debug("dur: \(tup.dur, privacy: .public)")
                        Logger.playlist.debug("title: \(tup.title, privacy: .public)")

                        entry.originalExtinf = line
                        entry.title = tup.title
                        entry.duration = tup.dur
                        entry.commmands[tup.cmd] = tup.title
                        
                        parseState = .hasExtInf
                    } catch {
                        print("\(error.localizedDescription)")
                    }
                }
//            } else if line.hasPrefix("http") {
             if line.hasPrefix("http") {
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
            } // has prefix
            
//            let videoduration=nodeElement.querySelector('[data-testid="video-duration"]');

            // #EXTINF:0, the title
//            if line.hasPrefix("#EXTINF") {
//                Logger.playlist.debug("EXTINF: \(line, privacy: .public)")
//                
//               // let regexp = /^(?<cmd>.+?):\s+(?<dur>[-+]?([0-9]+(\.[0-9]+)?|\.[0-9]+))\s+:\s+(?<title>.+?)$/
//                
//                let regexp = #/^(?<cmd>.+?):\s+(?<dur>[-+]?([0-9]+(\.[0-9]+)?|\.[0-9]+))\s+\,\s+(?<title>.+?)$/#
//                
//                do {
//                    if let result = try regexp.wholeMatch(in: line) {
//                        print("Cmd: \(result.cmd)")
//                        print("Dur: \(result.dur)")
//                        print("Title: \(result.title)")
//                    } else {
//                        print("Could not get regexp duration")
//                    }
//                } catch {
//                    print("\(error.localizedDescription)")
//                }
//
//                
//                
//
//                let durationString = line.replacingOccurrences(of: extinfoRegexp,
//                                                               with: "$2",
//                                                               options: .regularExpression,
//                                                               range: nil)
//
//                let titleString = line.replacingOccurrences(of: extinfoRegexp,
//                                                            with: "$3",
//                                                            options: .regularExpression,
//                                                            range: nil)
//
//
//                Logger.playlist.debug("title: \(titleString, privacy: .public)")
//                Logger.playlist.debug("duration: \(durationString, privacy: .public)")
//
//                entry.originalExtinf = line
//                entry.title = titleString
//                if let d = Double(durationString) {
//                    entry.duration = d
//                }
//                //entry.duration = Double(durationString)!
//                parseState = .hasExtInf
//
//                //            } else if line.hasPrefix("#") {
//                //                logger.debug("comment line: \(line, privacy: .public)")
//                //                // continue
//
////            } else if line.hasPrefix("http") {
//            
//             if line.hasPrefix("http") {
//                Logger.playlist.debug("http line: \(line, privacy: .public)")
//                entry.urlString = line
//                results.append(entry)
//
//                // the url is the terminal state.
//                // this resets and creates a new entry
//                parseState = .begin
//
//            } else if line.hasPrefix("#EXTIMG") {
//                Logger.playlist.debug("EXTIMG: \(line, privacy: .public)")
//
//                let imgURLString = line.replacingOccurrences(of: extImgRegexp,
//                                                             with: "$2",
//                                                             options: .regularExpression,
//                                                             range: nil)
//                //print("imgURLString: \(imgURLString)")
//                entry.extImgURLString = imgURLString
//
//                // keep going
//                parseState = .hasExtInf
//
//            } else if line.hasPrefix("#EXTGRP") {
//                Logger.playlist.debug("EXTGRP line: \(line, privacy: .public)")
//                parseState = .hasExtInf
//
//            } else {
//
//                // doesn't have prefix #EXT i.e. the url
//                Logger.playlist.debug("non #EXT line: \(line, privacy: .public)")
//
//                //                if parseState == .hasExtInf {
//                //                    entry.urlString = line
//                //                    results.append(entry)
//                //                }
//
//                // reset
//                parseState = .begin
//            }
        } // for

        return results
    } // parse


    func displayPlaylistAsHTML(_ path: String? = nil, comments: Bool = false) {

//        public var title: String = ""
//        public var duration: Double = 0.0
//        public var urlString: String = ""
//        public var extImgURLString: String = ""
//        public var originalExtinf: String = ""

        var s = "<html>\n<body>\n"
        for f in sortedEntries {
//            for (k,v) in f.commmands {
//                s += "#\(k): \n"
//                s += "\(v)\n"
//            }

//            if let title = f.commmands["#EXTINF:"] {
//                s += "<p>\(title)\"</p>\n"
//            } else {
//                s += "<p>\(f.title)\"</p>\n"
//            }

            s += "<div>\n"
            s += "<p>\(f.title) - \(f.duration)</p>\n"
            s += "<a href=\"\(f.urlString)\">\n"
//            s += "<img src=\"\(f.extImgURLString)\"</img>\n"

            // <img src="img_girl.jpg" alt="Girl in a jacket" width="500" height="600">
            s += "<img src=\(f.extImgURLString) alt=\"\(f.title)\"></img>\n"
            s += "</a>\n"
            s += "</div>\n\n"
        }
         s += "</body>\n<html>\n"

        print(s)



    }

    // TODO: move this to a different struct
    //    func displayPlaylist(_ outputURL: URL? = nil) {
    func displayPlaylist(_ path: String? = nil, comments: Bool = false) {


        if let path {
            //            print("\(outputURL)")
            //            var urlString = outputURL.relativeString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            //            print("\(urlString)")

            var s = "#EXTM3U\n"
            if comments {
                let d = Date().ISO8601Format()
                s += "# Date: \(d)\n"
                //s += "# Source: \(self.fileURL.absoluteString)\n"
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
                    if k == "#EXTINF:" {
                        s += f.extInf
                        s += "\n"
                    } else {
                        s += "\(k) "
                        s += "\(v)\n"
                    }
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
    

    func sortEntries(entries: [PlaylistEntry],
                     sortField: SortField = .sortByURLString,
                     sortOp: SortOp = .ascending) {

       // print("removeDuplicates \(sortField)")
       // print("\(#function)".bg(.yellow).fg(.red) )
        
        switch sortField {
            
        case .sortByURLString:
           // print("sorting by urlstring")
            // want to take care of numbers. i.e. 10 does not come before 2
            
            self.sortedEntries = entries.sorted {(s1, s2) -> Bool in
                if sortOp == .ascending {
                    Logger.domain.debug("Sorting ascending by urlString")
                    return (s1.urlString.localizedStandardCompare(s2.urlString) == .orderedAscending)
                } else {
                    Logger.domain.debug("Sorting descending by urlString")
                    return (s1.urlString.localizedStandardCompare(s2.urlString) == .orderedDescending)
                }

            }
        case .sortByTitle:
           // print("sorting by title")
            
            self.sortedEntries = entries.sorted {(s1, s2) -> Bool in
                if sortOp == .ascending {
                    Logger.domain.debug("Sorting ascending by title")
                    return (s1.title.localizedStandardCompare(s2.title) == .orderedAscending)
                } else {
                    Logger.domain.debug("Sorting descending by title")
                    return (s1.title.localizedStandardCompare(s2.title) == .orderedDescending)
                }
            }
        case .sortByDuration:
           // print("sorting by duration")
            
            self.sortedEntries = entries.sorted {(s1, s2) -> Bool in

                if sortOp == .ascending {
                    Logger.domain.debug("Sorting ascending by duration")
                    Logger.domain.debug("\(s1.duration) < \(s2.duration)")
                    //print("|\(s1.duration)| < |\(s2.duration)| \(s1.duration <= s2.duration)")
                    return s1.duration <= s2.duration
                } else {
                    Logger.domain.debug("Sorting descending by duration")
                    Logger.domain.debug("\(s1.duration) > \(s2.duration)")
                    //print("|\(s1.duration)| > |\(s2.duration)|  \(s1.duration > s2.duration)")
                    return s1.duration > s2.duration
                }
            }
            
           // print("self.sortedEntries\(self.sortedEntries)")
        }
    }
    
    func removeDuplicates(sortField: SortField = .sortByURLString, sortOp: SortOp = .ascending) {
        // unlike Unix uniq, it doesn't have to be sorted first
        //        self.playlistEntries.sort { a, b in
        //            a.urlString < b.urlString
        //        }

        let unique = Array<PlaylistEntry>(Set<PlaylistEntry>(self.playlistEntries))
        
        sortEntries(entries: unique, sortField: sortField, sortOp: sortOp)
        
        
        
//        unique.sort(using: .localizedStandard)
//        self.sortedEntries = unique
        
       // print("removeDuplicates \(sortField)")
        
       // print("\(#function)".bg(.yellow).fg(.red) )
        
//        switch sortField {
//            
//        case .sortByURLString:
//           // print("sorting by urlstring")
//            // want to take care of numbers. i.e. 10 does not come before 2
//            
//            self.sortedEntries = unique.sorted {(s1, s2) -> Bool in
//                if sortOp == .ascending {
//                    Logger.domain.debug("Sorting ascending by urlString")
//                    return (s1.urlString.localizedStandardCompare(s2.title) == .orderedAscending)
//                } else {
//                    Logger.domain.debug("Sorting descending by urlString")
//                    return (s1.urlString.localizedStandardCompare(s2.title) == .orderedDescending)
//                }
//
//            }
//        case .sortByTitle:
//           // print("sorting by title")
//            
//            self.sortedEntries = unique.sorted {(s1, s2) -> Bool in
//                if sortOp == .ascending {
//                    Logger.domain.debug("Sorting ascending by title")
//                    return (s1.title.localizedStandardCompare(s2.title) == .orderedAscending)
//                } else {
//                    Logger.domain.debug("Sorting descending by title")
//                    return (s1.title.localizedStandardCompare(s2.title) == .orderedDescending)
//                }
//            }
//        case .sortByDuration:
//           // print("sorting by duration")
//            
//            self.sortedEntries = unique.sorted {(s1, s2) -> Bool in
//
//                if sortOp == .ascending {
//                    Logger.domain.debug("Sorting ascending by duration")
//                    Logger.domain.debug("\(s1.duration) < \(s2.duration)")
//                    //print("|\(s1.duration)| < |\(s2.duration)| \(s1.duration <= s2.duration)")
//                    return s1.duration <= s2.duration
//                } else {
//                    Logger.domain.debug("Sorting descending by duration")
//                    Logger.domain.debug("\(s1.duration) > \(s2.duration)")
//                    //print("|\(s1.duration)| > |\(s2.duration)|  \(s1.duration > s2.duration)")
//                    return s1.duration > s2.duration
//                }
//            }
//            
//           // print("self.sortedEntries\(self.sortedEntries)")
//        }
        
       

//        let urlDescriptor = SortDescriptor(\PlaylistEntry.urlString,
//          comparator: .localizedStandard)
//        self.sortedEntries = unique.sorted(using: urlDescriptor)

        // the Set changed the order
//        self.sortedEntries.sort { a, b in
//            a.urlString < b.urlString
////            let lexicalComparator = String.StandardComparator(.lexical)
////
////            let result = a.urlString.compare(b.urlString, options: .numeric)
////            switch result {
////
////            case .orderedAscending:
////
////            case .orderedSame:
////
////            case .orderedDescending:
////
////            }
//        }
        
    }

    func totalDuration() -> String {
        if self.sortedEntries.isEmpty {
            removeDuplicates(sortField: .sortByDuration, sortOp: .ascending)
        }
        let totalDuration = self.sortedEntries.reduce(0) { $0 + $1.duration }
        return TimeUtils.secondsToHMS(Int(totalDuration))
    }
}

// MARK: CustomStringConvertible
extension Playlist: CustomStringConvertible {
    public var description: String {
        var s = "\(type(of: self))\n"
        s += "fileURL: \(String(describing: fileURL?.path()))\n"
        s += "playlistEntries: \(playlistEntries.count)\n"
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

//extension Playlist: Equatable {
//    static func ==(lhs: Playlist, rhs: Playlist) -> Bool {
//        return lhs.duration == rhs.duration &&
//        lhs.count == rhs.count
//    }
//}

//extension PlaylistEntry: Comparable {
//    public static func <(lhs: PlaylistEntry, rhs: PlaylistEntry) -> Bool {
//        return lhs.duration < rhs.duration
//    }
//}
