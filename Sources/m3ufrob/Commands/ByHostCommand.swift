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
import ArgumentParser
import GDTerminalColor
import AppKit

extension MainCommand {
    
    struct ByHostCommand:  AsyncParsableCommand {
        static let version = "0.1.0"
        
        static var configuration = CommandConfiguration(
            commandName: "byhost",
            abstract:
                String(localized: "This reads a playlist(s), then extracts by hostname.", comment: ""),
            usage: """
              xcrun swift run m3ufrob byhost filename
              xcrun swift run m3ufrob byhost filename -o output.m3u8
              xcrun swift run m3ufrob byhost filename -v -o output.m3u8
              xcrun swift run m3ufrob byhost --input-directory-name ~/Video/test-playlists
              xcrun swift run m3ufrob byhost --list-hosts playlist
              """,
            version: version
        )
        
        @Argument(
            help: ArgumentHelp(
                String(localized: "Input playlist file.", comment: ""),
                discussion:
                    String(localized: "The filename of the input playlist.", comment: "")
            )
        )
        var inputFile: String?
        
        @Option(
            name: [.customShort("o"), .long],
            help: ArgumentHelp(
                String(localized: "Output file name.", comment: ""),
                discussion:
                    String(localized: "The filename of the processed playlist.", comment: "")
            )
        )
        var outputFileName: String?
        
        @Option(
            name: [.long],
            help: ArgumentHelp(
                String(localized: "Output directory.",
                       comment: ""),
                discussion:
                    String(localized: "The directory for the processed playlists.",
                           comment: "")
            ),
            transform: URL.init(fileURLWithPath:)
        )
        var outputDir: URL?
        
        @Option(
            name: [.long],
            help: ArgumentHelp(
                String(localized: "Host name.", comment: ""),
                discussion:
                    String(localized: "Display playlist entries only with this host in the URL.",
                           comment: "")
            )
        )
        var selectedHost = "youtube.com"
        
        @Option(
            name: [.long],
            help: ArgumentHelp(
                String(localized: "Input Directory.", comment: ""),
                discussion:
                    String(localized: "Frob all playlists in this directory..", comment: "")
            )
        )
        var inputDirectoryName: String?
        
        @Flag(
            name: [.long],
            inversion: .prefixedNo,
            exclusivity: .exclusive,
            help:
                ArgumentHelp(
                    String(localized: "List the hostnames in the input playlist", comment: ""),
                    discussion:
                        String(localized: "List the hostnames in the input playlist.", comment: "")
                )
        )
        public var listHosts: Bool = false
        
        @Flag(
            //name: [.short],
            inversion: .prefixedNo,
            exclusivity: .exclusive,
            help:
                ArgumentHelp(
                    String(localized: "basename", comment: ""),
                    discussion:
                        String(localized: "Use the input file name as the output basename", comment: "")
                )
        )
        public var basename: Bool = false
        
        @OptionGroup() var commonOptions: Options
        
        func validate() throws {
            
            if let inputFile {
                guard !inputFile.isEmpty else {
                    throw ValidationError("You need to set the input file")
                }
            }
        }
        
        func run() async throws {
            
            guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
                print("\(Self.configuration.commandName ?? "command") isn't supported on this platform.")
                return
            }
            
            let pasteboard: NSPasteboard = .general
            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            
            if commonOptions.verbose {
                let s = "input file name: \(inputFile ?? "no input file")".justify(.left)
                    .fg256(.aqua).bg256(.deepPink3)
                print(s)
                
                print("input file name: \(inputFile ?? "no input file")  ")
                print("output file \(outputFileName ?? "output file not set")  ")
                print("verbose \(commonOptions.verbose)")
            }
            
            
            if let inputFile {
                
                var inputFileURL = URL(fileURLWithPath: inputFile)
                inputFileURL.resolveSymlinksInPath()
                inputFileURL.standardize()
                
                guard FileManager.default.fileExists(atPath: inputFileURL.path) else {
                    preconditionFailure("file expected at \(inputFileURL.path) is missing")
                }
                
                if commonOptions.verbose {
                    print("Processing file \(inputFile)".fg(.yellow))
                    print("input file url: \(inputFileURL.path)")
                }
                
                let playlist = Playlist(fileURL: inputFileURL)
                await playlist.load()
                
                if commonOptions.verbose {
                    print("here is the playlist\n")
                    print(playlist)
                }
                playlist.removeDuplicates()
                
                if listHosts {
                    if commonOptions.verbose {
                        print("Available hosts")
                    }
                    var hosts = Set<String>()
                    for entry in playlist.playlistEntries {
                        if let host = entry.getHost() {
                            hosts.insert(host)
                        }
                    }
                    for host in hosts {
                        print("\(host)")
                    }
                    
//                    print("There are \(hosts.count) hosts.")
//                    print("View them? y/n")
//                    
//                    let y = Character("y").asciiValue!
//                    let ch = getch()
//                    if ch == y {
//
//                    }
                    
                    return
                }

                
                let groupedByHost = Dictionary(grouping: playlist.playlistEntries) { (entry) -> String in
                    if let h = entry.getHost() {
                        return h
                    }
                    return ""
                }
                
                if let entries = groupedByHost[selectedHost] {
                    let pl = Playlist(entries: entries)
                    pl.removeDuplicates()
                    
                    
                     if basename {
                        let bname = inputFileURL.deletingPathExtension().lastPathComponent
                        let ext = inputFileURL.pathExtension
                        let parent = inputFileURL.deletingLastPathComponent()
                        let ppath = parent.path(percentEncoded: false)
                        // ppath has a trailing /
                        
                        var outputFileURL = URL(fileURLWithPath: ppath)
                        outputFileURL = outputFileURL.appending(path: "\(bname).\(selectedHost).\(ext)")
                        outputFileURL.resolveSymlinksInPath()
                        // for dealing with relative paths
                        outputFileURL.standardize()
                        pl.displayPlaylist(outputFileURL.path)
                        print("\(outputFileURL.path)".fg(.orange))
                        
                        pasteboard.setString(outputFileURL.path,
                                             forType: NSPasteboard.PasteboardType.string)
                        
                    } else if let path = outputFileName {
                        if commonOptions.verbose {
                            let s = "Writing to: \(path)".justify(.left)
                                .fg256(.aquamarine1).bg256(.deepPink3)
                            print(s)
                        }
                        pl.displayPlaylist(path)
                        
                        pasteboard.setString(path, forType: .string)
                        
                    } else if !basename {
                        pl.displayPlaylist()
                    }
                    
                } else {
                    print("no entries for \(selectedHost)")
                    print("Available hosts")
                    var hosts = Set<String>()
                    for entry in playlist.playlistEntries {
                        if let host = entry.getHost() {
                            hosts.insert(host)
                        }
                    }
                    for host in hosts {
                        print("\(host)")
                    }
                }
                
            }
        }
    }
}


