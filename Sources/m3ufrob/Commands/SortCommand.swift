//
// File:         SortCommand
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
import os.log

enum SortField: String, EnumerableFlag, Codable {
    case sortByTitle
    case sortByURLString
    case sortByDuration
}
enum SortOp: String, EnumerableFlag, Codable {
    case ascending
    case descending
}


extension MainCommand {
    
    struct SortCommand:  AsyncParsableCommand {
        static let version = "0.1.0"
        
        static var configuration = CommandConfiguration(
            commandName: "sort",
            abstract:
                String(localized: "This reads a playlist(s), then removes duplicates and sorts it.", comment: ""),
            usage: """
              xcrun swift run m3ufrob sort filename
              m3ufrob sort filename

              m3ufrob sort --inplace filename
              
              m3ufrob sort filename -o output.m3u8
              m3ufrob sort filename -v -o output.m3u8
              m3ufrob sort --input-directory-name ~/Video/test-playlists

              m3ufrob sort --title --inplace filename
              m3ufrob sort --url-string --inplace filename
              
              m3ufrob sort --sort-by-title filename
              m3ufrob sort --sort-by-url-string filename
              m3ufrob sort --sort-by-duration filename
              
              cat file.m3u8 | m3ufrob sort --sort-by-title -
              cat file.m3u8 | m3ufrob sort --sort-by-title --descending -
              cat file.m3u8 | m3ufrob sort --sort-by-title --asscending -
              
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
        var inputFile: String? = "-"
        
        // maybe
        // specify multiple files, sort/uniq them, then write to their invidual output file
//        @Argument(
//            parsing: .remaining,
//            help: ArgumentHelp(
//                String(localized: "Input playlists file names.", comment: ""),
//                discussion:
//                    String(localized: "The filenames of the input playlists.", comment: "")
//            )
//        )
//        var inputFileNames: [String]
        
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
        
//        @Option(
//            name: [.long],
//            help: ArgumentHelp(
//                String(localized: "Input directory.",
//                       comment: ""),
//                discussion:
//                    String(localized: "The directory to read for m3u8 files.",
//                           comment: "")
//            ),
//            transform: URL.init(fileURLWithPath:)
//        )
//        var inputDir: URL?
        
        
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
            //exclusivity: .exclusive,
            help:
                ArgumentHelp(
                    String(localized: "In place", comment: ""),
                    discussion:
                        String(localized: "Overwrite the original playlist with the results", comment: "")
                )
        )
        public var inplace: Bool = false
        
        @Flag(
            name: [.long],
            inversion: .prefixedNo,
            //exclusivity: .exclusive,
            help:
                ArgumentHelp(
                    String(localized: "Unique", comment: ""),
                    discussion:
                        String(localized: "Remove duplicate entries", comment: "")
                )
        )
        public var unique: Bool = false
        
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
        
        
       

        @Flag(exclusivity: .exclusive,
              help: ArgumentHelp(NSLocalizedString("Choose field to sort on.", comment: "")))
        var sortField: SortField = .sortByURLString
        // This will default to .urlString.
        // If you want to force the user to specify one of the flags,
        // do not specify a value here.

        @Flag(exclusivity: .exclusive,
              help: ArgumentHelp(NSLocalizedString("Choose sort direction.", comment: "")))
        var sortOp: SortOp = .ascending


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
            
            //            guard let outputFileName = outputFile else {
            //                print("outputFileName cannot be nil")
            //                throw ValidationError("You need to set the output file")
            //            }
            //let outputFileURL = URL(fileURLWithPath: outputFileName)
            //  print("output file \(outputFileURL.absoluteString)")
            
            
            
            if let inputDirectoryName {
                
                Logger.command.debug("inputDirectoryName branch")

                
                //                let message = String.localizedStringWithFormat(
                //                    NSLocalizedString("Hello, %@! Welcome to %@!",
                //                                      tableName: "AppDelegate",
                //                                      comment: "Welcome message when the app starts"),
                //                    "Stefan", "Mozilla")
                
                
                
                print(String(localized:"# Processing directory \(inputDirectoryName)",
                             comment: "").fg(.yellow))
                //let fileService = FileService()
                
//                guard let filename = self.outputFileName else {
//                    print(String(localized:"You need to specify the output file name",
//                                 comment: ""))
//                    return
//                }
                
                //let pparser = PlaylistParser()
                
                let durl = URL(fileURLWithPath: inputDirectoryName)
                let playlists = await Playlist.readPlaylistDirectory(durl)
                for playlist in playlists {
                    if let fileURL = playlist.fileURL  {
                        print("Playlist: \(fileURL.absoluteString)")
                    }
                    print("Entry count: \(playlist.playlistEntries.count)")

                    playlist.displayPlaylist()

//                    if merge {
//                        let merged = await playlist.mergeLoadedPlaylists(filePath: filename, playlists: playlists)
//
//                        print("There are \(merged.playlistEntries.count) entries.")
//                        print("View them? y/n")
//
//                        let y = Character("y").asciiValue!
//                        let ch = getch()
//                        if ch == y {
//                            merged.displayPlaylist()
//                        }
//                    } else {
//                        playlist.displayPlaylist()
//                    }
                }
                
                // fileService.userSelectedFolderURL = durl
                //let entries = fileService.playlistFilesInDirectory(selectedFolderURL: durl)
                //                for entry in entries {
                //                    print("\(entry.fileURL.absoluteString)")
                //                }
                
                
            } else {
                
                var playlist: Playlist
                var inputFileURL: URL?
                
                if let inputFile {
                    Logger.command.debug("not inputDirectoryName branch")
                    Logger.command.debug("Processing file \(inputFile)")
                    //print("Processing file \(inputFile)".fg(.yellow))
                    
                    playlist = Playlist()
                    
                    if inputFile == "-" {
                        Logger.command.debug("reading from stdin")

                        if commonOptions.verbose {
                            print("reading from stdin")
                        }
                        await playlist.loadFromStdin()

                        // TODO: unique
                        if unique {
                            Logger.command.debug("unique")

                            let unique = Array<PlaylistEntry>(Set<PlaylistEntry>(playlist.playlistEntries))
                            playlist.sortEntries(entries: unique,
                                                 sortField: self.sortField,
                                                 sortOp: self.sortOp)
                        } else {
                            Logger.command.debug("not unique")
                            playlist.sortEntries(entries: playlist.playlistEntries,
                                                 sortField: self.sortField,
                                                 sortOp: self.sortOp)
                        }
                        
//                        playlist.removeDuplicates(sortField: self.sortField, sortOp: self.sortOp)

                        
                        //inputFile = stdin.pointee
//                        let file = FileHandle.standardInput
//                        while let line = readLine() {
//                           print(line)
//                        }

                    } else {
                        Logger.command.debug("reading inputfile \(inputFile)")
                        inputFileURL = URL(fileURLWithPath: inputFile)
                        if var url = inputFileURL {
                            url.resolveSymlinksInPath()
                            url.standardize()
                            
                            guard FileManager.default.fileExists(atPath: url.path) else {
                                preconditionFailure("file expected at \(url.path) is missing")
                            }
                            
                            if commonOptions.verbose {
                                print("input file url: \(url.path)")
                            }
                            
                            playlist = Playlist(fileURL: url)
                            await playlist.load()
                            
                            for entry in playlist.playlistEntries {
                                print("\(entry)")

//                                if entry.title == "badInput" {
//                                    print("entry has bad input")
//                                } else {
//                                    print("\(entry)")
//                                }
                            }
                            
                            if unique {
                                Logger.command.debug("unique")
                                let unique = Array<PlaylistEntry>(Set<PlaylistEntry>(playlist.playlistEntries))
                                playlist.sortEntries(entries: unique,
                                                     sortField: self.sortField,
                                                     sortOp: self.sortOp)
                            } else {
                                Logger.command.debug("not unique")
                                playlist.sortEntries(entries: playlist.playlistEntries,
                                                     sortField: self.sortField,
                                                     sortOp: self.sortOp)
                            }
                            //playlist.removeDuplicates(sortField: self.sortField, sortOp: self.sortOp)

                        }
                    }
                    
                    if commonOptions.verbose {
                        print("here is the playlist\n")
                        print(playlist)
                    }
                    
                   
                    
                   // playlist.removeDuplicates(sortField: self.sortField, sortOp: self.sortOp)
                    
                    if inplace {
                        Logger.command.debug("inplace")
                        if commonOptions.verbose {
                            print("sorting inplace\n")
                        }
                        
                        var rg = SystemRandomNumberGenerator()
                        let r = rg.next()
                        
                        let tmp = FileManager.default.temporaryDirectory
                        let outputFileURL = tmp.appendingPathComponent("m3ufrob-\(r)")
                        //print("outputFileURL: \(outputFileURL.absoluteString)")
                        
//                        var tempURL = URL(fileURLWithPath: FileManager.default.temporaryDirectory.path)
//                        tempURL.appendPathComponent(inputFileURL.lastPathComponent)
//                        print("tempURL \(tempURL.path)".fg(.orange))
                        
                        playlist.displayPlaylist(outputFileURL.path, comments: true)
                        //print("\(outputFileURL.path)".fg(.orange))
                        
                        if let inputFileURL = inputFileURL {
                            do {
                                if FileManager.default.fileExists(atPath: inputFileURL.path) {
                                    if commonOptions.verbose {
                                        print("removing input file because it exists. \(inputFileURL.path)")
                                    }
                                    try FileManager.default.removeItem(atPath: inputFileURL.path)
                                }
                                
                                try FileManager.default.moveItem(atPath: outputFileURL.path,
                                                                 toPath: inputFileURL.path)
                                print("Wrote to\n\(inputFileURL.path)")
                                print("The file path has been copied to the pasteboard")
                                
                                pasteboard.setString(inputFileURL.path,
                                                     forType: NSPasteboard.PasteboardType.string)
                            } catch {
                                stderr.write("\(error.localizedDescription)")
                                stderr.write("could not move to \(inputFileURL.path)")
                            }
                        }
                        
                        
                    }
                    
                    else if basename {
                        Logger.command.debug("using basename")
                        if commonOptions.verbose {
                            print("basename\n")
                        }
                        
                        if let inputFileURL = inputFileURL {
                            
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
                            
                            //                        print("basename: \(bname)")
                            //                        print("ext: \(ext)")
                            //                        print("path: \(path)")
                            //                        print("nopercent: \(nopercent)")
                            //                        print("newpath: \(newpath)")
                            //                        print("outputFileURL: \(outputFileURL.absoluteString)")
                            //                        playlist.displayPlaylist(newpath)
                            //                        print("\(newpath)".fg(.orange))
                            
                            playlist.displayPlaylist(outputFileURL.path, comments: true)
                            print("\(outputFileURL.path)".fg(.orange))
                            pasteboard.setString(outputFileURL.path,
                                                 forType: NSPasteboard.PasteboardType.string)
                        }
                    }
                    
                    else if let path = outputFileName {
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
                        pasteboard.setString(path,
                                             forType: NSPasteboard.PasteboardType.string)
                        
                    } else if !basename {
                        playlist.displayPlaylist()
                    }
                }
            }
        }
    }
    
}
