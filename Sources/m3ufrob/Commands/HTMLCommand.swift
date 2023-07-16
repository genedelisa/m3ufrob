// File: File.swift
// Project: 
// Package: 
// Product:  
// ~/Library/Developer/Xcode/UserDataIDETemplateMacros.plist
//
// Created by Gene De Lisa on 7/10/23
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
import ArgumentParser
import GDTerminalColor
import AppKit

extension MainCommand {
    
    struct HTMLCommand:  AsyncParsableCommand {
        static let version = "0.1.0"
        
        static var configuration = CommandConfiguration(
            commandName: "html",
            abstract:
                String(localized: "This reads a playlist(s), then creates a simple HTML page.",
                       comment: ""),
            usage: """
              xcrun swift run m3ufrob html filename
              """,
            version: version
        )
        
        @Argument(
            help: ArgumentHelp(
                String(localized: "Input files.",
                       comment: ""),
                discussion:
                    String(localized: "The path or one or more audio files.",
                           comment: "")
            ),
            transform: URL.init(fileURLWithPath:)
        )
        var inputFileURLs: [URL]
        
        @Option(
            name: [.customShort("o"), .long],
            help: ArgumentHelp(
                String(localized: "Output file name.",
                       comment: ""),
                discussion:
                    String(localized: "The filename of the html file.",
                           comment: "")
            )
        )
        var outputFileName: String?
        
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
            guard !inputFileURLs.isEmpty else {
                throw ValidationError("You need to specify at least one input file")
            }
        }
        
        func run() async throws {
            
            guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
                print("\(Self.configuration.commandName ?? "command") isn't supported on this platform.")
                return
            }
            let pasteboard: NSPasteboard = .general
            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)

            
            
            if let inputDirectoryName {
                
                print(String(localized:"Processing directory \(inputDirectoryName)",
                             comment: "").fg(.yellow))
                
                let durl = URL(fileURLWithPath: inputDirectoryName)
                let playlists = await Playlist.readPlaylistDirectory(durl)
                for playlist in playlists {
                    print("Playlist: \(playlist.fileURL.absoluteString)")
                    print("Entry count: \(playlist.playlistEntries.count)")

                    playlist.displayPlaylist()

                }
                
            } else {

                for var inputFileURL in self.inputFileURLs {
                    
                    if commonOptions.verbose {
                        print("input file url: \(inputFileURL.path)")
                        print("Processing file \(inputFileURL.absoluteString)".fg(.yellow))
                    }

                    
                    inputFileURL.resolveSymlinksInPath()
                    inputFileURL.standardize()
                    
                    guard FileManager.default.fileExists(atPath: inputFileURL.path) else {
                        preconditionFailure("file expected at \(inputFileURL.path) is missing")
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
                        outputFileURL = outputFileURL.appending(path: "\(bname).su.\(playlist.uniqueCount).\(ext)")
                        outputFileURL.resolveSymlinksInPath()
                        // for dealing with relative paths
                        outputFileURL.standardize()
                        //print(outputFileURL.path)
                        
//                        if commonOptions.verbose {
//                             print("basename: \(bname)")
//                             print("ext: \(ext)")
//                             print("path: \(path)")
//                             print("nopercent: \(nopercent)")
//                             print("newpath: \(newpath)")
//                             print("outputFileURL: \(outputFileURL.absoluteString)")
//                             playlist.displayPlaylist(newpath)
//                             print("\(newpath)".fg(.orange))
//                        }
                        
                        playlist.displayPlaylist(outputFileURL.path, comments: true)
                        print("\(outputFileURL.path)".fg(.orange))
                        pasteboard.setString(outputFileURL.path,
                                             forType: NSPasteboard.PasteboardType.string)
                    }
                    
                    else if let spath = outputFileName {
                        var path = (spath as NSString).expandingTildeInPath
                        
                        if commonOptions.verbose {
                            let s = "Writing to: \(path)".justify(.left)
                                .fg256(.aquamarine1).bg256(.deepPink3)
                            print(s)
                        }
                        
                        // let outputURL = URL(fileURLWithPath: path)
                        // playlist.displayPlaylist(outputURL)
                        
                        playlist.displayPlaylist(path)
                        pasteboard.setString(path,
                                             forType: NSPasteboard.PasteboardType.string)
                        
                    } else if !basename {
                        playlist.displayPlaylistAsHTML()
                    }
                }
            }
        }
    }
    
}
