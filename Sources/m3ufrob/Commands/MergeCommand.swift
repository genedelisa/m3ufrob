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
    
    struct MergeCommand:  AsyncParsableCommand {
        static let version = "0.1.0"
        
        static var configuration = CommandConfiguration(
            commandName: "merge",
            abstract:
                String(localized: "This merges playlists.", comment: ""),
            usage: """
              xcrun swift run m3ufrob merge playlist1 playlist2 playlist3 ...
              xcrun swift run m3ufrob merge playlist1 playlist2 -o merged.m3u8
              xcrun swift run m3ufrob merge -v playlist1 playlist2 -o merged.m3u8
              """,
            version: version
        )
        
        @Argument(
            parsing: .remaining,
            help: ArgumentHelp(
                String(localized: "Input playlists file names.", comment: ""),
                discussion:
                    String(localized: "The filenames of the input playlists.", comment: "")
            )
        )
        var inputFileNames: [String]
        
        
        //        @Option(
        //            name: [.short, .long],
        //            help: ArgumentHelp(
        //                String(localized: "Input Directory.", comment: ""),
        //                discussion:
        //                    String(localized: "Frob all playlists in this directory..", comment: "")
        //            )
        //        )
        //var inputDirectoryName: String?
        
        @Option(
            name: [.customShort("o"), .long],
            help: ArgumentHelp(
                String(localized: "Output file name.", comment: ""),
                discussion:
                    String(localized: "The filename of the processed playlist.", comment: "")
            )
        )
        var outputFileName: String?
        
//        @Option(
//            name: [.long],
//            help: ArgumentHelp(
//                String(localized: "Output directory.",
//                       comment: ""),
//                discussion:
//                    String(localized: "The directory for the processed playlists.",
//                           comment: "")
//            ),
//            transform: URL.init(fileURLWithPath:)
//        )
//        var outputDir: URL?
        
//        @Flag(
//            //name: [.short],
//            inversion: .prefixedNo,
//            exclusivity: .exclusive,
//            help:
//                ArgumentHelp(
//                    String(localized: "basename", comment: ""),
//                    discussion:
//                        String(localized: "Use the input file name as the output basename", comment: "")
//                )
//        )
//        public var basename: Bool = false
        
        @OptionGroup() var commonOptions: Options
        
        
        func validate() throws {
            
            //if let inputFileNames {
            //            if inputFileNames.isEmpty && inputDirectoryName == nil {
            
            if inputFileNames.isEmpty {
                throw ValidationError("You need to set the input files")
            }
            
            for filename in inputFileNames {
                if !FileManager.default.fileExists(atPath: filename) {
                    throw ValidationError("\(filename) does not exist")
                }
            }
            // }
            
        }
        
        func run() async throws {
            
            guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
                print("\(Self.configuration.commandName ?? "command") isn't supported on this platform.")
                return
            }
            
            let pasteboard: NSPasteboard = .general
            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)

            
            if commonOptions.verbose {
                //                let s = "input file name: \(inputFile ?? "no input file")".justify(.left)
                //                    .fg256(.aqua).bg256(.deepPink3)
                //                print(s)
                //                print("input file name: \(inputFile ?? "no input file")  ")
                
                print("output file \(outputFileName ?? "output file not set")  ")
                print("verbose \(commonOptions.verbose)")
            }
            
            
            // nah. just send filenames
            // have the shell select them
            //            if let inputDirectoryName {
            //
            //                print(String(localized:"Processing directory \(inputDirectoryName)",
            //                             comment: "")
            //                    .fg(.yellow))
            //
            //                guard let filename = self.outputFileName else {
            //                    print(String(localized:"You need to specify the output file name",
            //                                 comment: ""))
            //                    return
            //                }
            //
            //                var directoryURL = URL(fileURLWithPath: inputDirectoryName)
            //                directoryURL.resolveSymlinksInPath()
            //                directoryURL.standardize()
            //
            //                let playlists = await Playlist.readPlaylistDirectory(directoryURL)
            //                for playlist in playlists {
            //                    print("Playlist: \(playlist.fileURL.absoluteString)")
            //                    print("Entry count: \(playlist.playlistEntries.count)")
            //
            //                    let merged = await playlist.mergeLoadedPlaylists(filePath: filename, playlists: playlists)
            //
            //                    print("There are \(merged.playlistEntries.count) entries.")
            //                    print("View them? y/n")
            //
            //                    let y = Character("y").asciiValue!
            //                    let ch = getch()
            //                    if ch == y {
            //                        merged.displayPlaylist()
            //                    }
            //
            //                }
            //
            //                if basename {
            //                    let bname = directoryURL.deletingPathExtension().lastPathComponent
            //                    let ext = directoryURL.pathExtension
            //                    let parent = directoryURL.deletingLastPathComponent()
            //                    let ppath = parent.path(percentEncoded: false)
            //                    // ppath has a trailing /
            //                    var outputFileURL = URL(fileURLWithPath: ppath)
            //                    outputFileURL = outputFileURL.appending(path: "\(bname).su.\(ext)")
            //                    outputFileURL.resolveSymlinksInPath()
            //                    // for dealing with relative paths
            //                    outputFileURL.standardize()
            //
            //                    //playlist.displayPlaylist(outputFileURL.path)
            //                    print("\(outputFileURL.path)".fg(.orange))
            //
            //                }
            //
            //            } else
            
            if inputFileNames.count > 0 {
                
                // } else if let inputFileNames  {
                
                var playlists = [Playlist]()
                
                for filename in inputFileNames {
                    let url = URL(filePath: filename)
                    let playlist = Playlist(fileURL: url)
                    await playlist.load()
                    playlist.removeDuplicates()
                    playlists.append(playlist)
                    if commonOptions.verbose {
                        print("\(filename)".fg(.yellow))
                        playlist.displayPlaylist()
                    }
                }
                
                let merged = await Playlist.mergePlaylists(playlists: playlists)
                if commonOptions.verbose {
                    print("merged count: \(merged.playlistEntries.count)")
                    print("There are \(merged.playlistEntries.count) entries.")
                    print("View them? y/n")
                    
                    let y = Character("y").asciiValue!
                    let ch = getch()
                    if ch == y {
                        merged.displayPlaylist()
                    }
                }
                
                // what is directory name now?
                //                if basename {
                //                    let bname = directoryURL.deletingPathExtension().lastPathComponent
                //                    let ext = directoryURL.pathExtension
                //                    let parent = directoryURL.deletingLastPathComponent()
                //                    let ppath = parent.path(percentEncoded: false)
                //                    // ppath has a trailing /
                //                    var outputFileURL = URL(fileURLWithPath: ppath)
                //                    outputFileURL = outputFileURL.appending(path: "\(bname).su.\(ext)")
                //                    outputFileURL.resolveSymlinksInPath()
                //                    // for dealing with relative paths
                //                    outputFileURL.standardize()
                //
                //                    //playlist.displayPlaylist(outputFileURL.path)
                //                    print("\(outputFileURL.path)".fg(.orange))
                //                    await Playlist.save(filePath: outputFileURL.path, playlist: merged)
                //                }
                
                if let outputFileName {
                    await Playlist.save(filePath: outputFileName, playlist: merged)
                    pasteboard.setString(outputFileName,
                                         forType: NSPasteboard.PasteboardType.string)
                    if commonOptions.verbose {
                        print("Saved to: \(outputFileName)".fg(.yellow))
                    }
                }
                
            }
            
        }
        
    }
    
}
