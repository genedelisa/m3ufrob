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

extension MainCommand {
    
    struct SortCommand:  AsyncParsableCommand {
        static let version = "0.1.0"
        
        static var configuration = CommandConfiguration(
            commandName: "sort",
            abstract:
                String(localized: "This reads a playlist(s), then removes duplicates and sorts it.", comment: ""),
            usage: """
              xcrun swift run m3ufrob sort filename
              xcrun swift run m3ufrob sort filename -o output.m3u8
              xcrun swift run m3ufrob sort filename -v -o output.m3u8
              xcrun swift run m3ufrob sort --input-directory-name ~/Video/test-playlists
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
                    String(localized: "Merge", comment: ""),
                    discussion:
                        String(localized: "Merge the playlists read from a directory..", comment: "")
                )
        )
        public var merge: Bool = true
        
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
            print("verbose: \(commonOptions.verbose)  ")
            
            guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
                print("\(Self.configuration.commandName ?? "command") isn't supported on this platform.")
                return
            }
            
            if commonOptions.verbose {
                let s = "input file name: \(inputFile ?? "no input file")".justify(.left)
                    .fg256(.aqua).bg256(.deepPink3)
                print(s)
                
                print("input file name: \(inputFile ?? "no input file")  ")
                print("output file \(outputFileName ?? "output file not set")  ")
                print("verbose \(commonOptions.verbose)")
            }
            
            //            guard let outputFileName = outputFile else {
            //                print("outputFileName cannot be nil")
            //                throw ValidationError("You need to set the output file")
            //            }
            //let outputFileURL = URL(fileURLWithPath: outputFileName)
            //  print("output file \(outputFileURL.absoluteString)")
            
            
            
            if let inputDirectoryName {
                
                //                let message = String.localizedStringWithFormat(
                //                    NSLocalizedString("Hello, %@! Welcome to %@!",
                //                                      tableName: "AppDelegate",
                //                                      comment: "Welcome message when the app starts"),
                //                    "Stefan", "Mozilla")
                
                
                
                print(String(localized:"Processing directory \(inputDirectoryName)",
                             comment: "").fg(.yellow))
                //let fileService = FileService()
                
                guard let filename = self.outputFileName else {
                    print(String(localized:"You need to specify the output file name",
                                 comment: ""))
                    return
                }
                
                let durl = URL(fileURLWithPath: inputDirectoryName)
                let playlists = await Playlist.readPlaylistDirectory(durl)
                for playlist in playlists {
                    print("Playlist: \(playlist.fileURL.absoluteString)")
                    print("Entry count: \(playlist.playlistEntries.count)")
                    
                    if merge {
                        let merged = await playlist.mergeLoadedPlaylists(filePath: filename, playlists: playlists)
                        
                        print("There are \(merged.playlistEntries.count) entries.")
                        print("View them? y/n")
                        
                        let y = Character("y").asciiValue!
                        let ch = getch()
                        if ch == y {
                            merged.displayPlaylist()
                        }
                    } else {
                        playlist.displayPlaylist()
                    }
                }
                
                // fileService.userSelectedFolderURL = durl
                //let entries = fileService.playlistFilesInDirectory(selectedFolderURL: durl)
                //                for entry in entries {
                //                    print("\(entry.fileURL.absoluteString)")
                //                }
                
                
            } else {
                
                
                
                if let inputFile {
                    print("Processing file \(inputFile)".fg(.yellow))
                    
                    var inputFileURL = URL(fileURLWithPath: inputFile)
                    inputFileURL.resolveSymlinksInPath()
                    inputFileURL.standardize()
                    
                    guard FileManager.default.fileExists(atPath: inputFileURL.path) else {
                        preconditionFailure("file expected at \(inputFileURL.path) is missing")
                    }
                    
                    
                    
                    if commonOptions.verbose {
                        print("input file url: \(inputFileURL.absoluteString)")
                    }
                    
                    let playlist = Playlist(fileURL: inputFileURL)
                    await playlist.load()
                    
                    if commonOptions.verbose {
                        print("here is the playlist\n")
                        print(playlist)
                    }
                    
                    playlist.removeDuplicates()
                    
                    if basename {
                        let bname = inputFileURL.deletingPathExtension().lastPathComponent
                        let ext = inputFileURL.pathExtension
                        let parent = inputFileURL.deletingLastPathComponent()
                        let ppath = parent.path(percentEncoded: false)
                        // ppath has a trailing /
                        //let newpath = "\(ppath)\(bname).su.\(ext)"
                        
                        var outputFileURL = URL(fileURLWithPath: ppath)
                        outputFileURL = outputFileURL.appending(path: "\(bname).su.\(ext)")
                        outputFileURL.resolveSymlinksInPath()
                        // for dealing with relative paths
                        outputFileURL.standardize()
                        //print(outputFileURL.path)
                        
                        //                        print("basename: \(bname)")
                        //                        print("ext: \(ext)")
                        //                        print("path: \(path)")
                        //                        print("nopercent: \(nopercent)")
                        //                        print("newpath: \(newpath)")
                        //                        print("outputFileURL: \(outputFileURL.absoluteString)")
                        //                        playlist.displayPlaylist(newpath)
                        //                        print("\(newpath)".fg(.orange))
                        
                        playlist.displayPlaylist(outputFileURL.path)
                        print("\(outputFileURL.path)".fg(.orange))
                    }
                    
                    if let path = outputFileName {
                        // path = (path as NSString).expandingTildeInPath
                        
                        if commonOptions.verbose {
                            // print("Writing to: \(path)")
                            
                            let s = "Writing to: \(path)".justify(.left)
                                .fg256(.aquamarine1).bg256(.deepPink3)
                            print(s)
                        }
                        
                        // let outputURL = URL(fileURLWithPath: path)
                        // playlist.displayPlaylist(outputURL)
                        
                        playlist.displayPlaylist(path)
                        
                    } else if !basename {
                        playlist.displayPlaylist()
                    }
                }
            }
        }
    }
    
}
