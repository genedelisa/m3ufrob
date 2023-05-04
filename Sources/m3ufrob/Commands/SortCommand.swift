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
            abstract: "This reads a playlist, then removes duplicates and sorts it.",
            usage: """
              xcrun swift run m3ufrob sort filename
              """,
            version: version
        )
        
        @Argument(help: ArgumentHelp(
            NSLocalizedString("Input playlist file", comment: ""),
            discussion: "The filename of the input playlist."))
        var inputFile: String
        
        @Option(
            name: [.customShort("o"), .long],
            help: ArgumentHelp(
                NSLocalizedString("Output file name", comment: ""),
                discussion: "The filename of the processed playlist."))
        var outputFileName: String?
        
        @Option(
            name: [.long],
            help: ArgumentHelp(
                NSLocalizedString("Input Directory", comment: ""),
                discussion: "Frob all playlists in this directory."))
        var inputDirectoryName: String?
        
        @OptionGroup() var commonOptions: Options
        
        func validate() throws {
            
            guard !inputFile.isEmpty else {
                throw ValidationError("You need to set the input file")
            }
        }
        
        func run() async throws {
            print("verbose: \(commonOptions.verbose)  ")
            
            if commonOptions.verbose {
                let s = "input file name: \(inputFile)".justify(.left)
                    .fg256(.aqua).bg256(.deepPink3)
                print(s)
                
                print("input file name: \(inputFile)  ")
                print("output file \(outputFileName ?? "output file not set")  ")
                print("verbose \(commonOptions.verbose)")
            }
            
            //            guard let outputFileName = outputFile else {
            //                print("outputFileName cannot be nil")
            //                throw ValidationError("You need to set the output file")
            //            }
            //let outputFileURL = URL(fileURLWithPath: outputFileName)
            //  print("output file \(outputFileURL.absoluteString)")
            
            let inputFileURL = URL(fileURLWithPath: inputFile)
            guard FileManager.default.fileExists(atPath: inputFileURL.path) else {
                preconditionFailure("file expected at \(inputFileURL.path) is missing")
            }
            
            if commonOptions.verbose {
                print("input file url: \(inputFileURL.absoluteString)")
            }
            
            if let inputDirectoryName {
                
                let fileService = FileService()
                let durl = URL(fileURLWithPath: inputDirectoryName)
                fileService.userSelectedFolderURL = durl
                
            } else {
                
                let playlist = Playlist(fileURL: inputFileURL)
                await playlist.load()
                
                if commonOptions.verbose {
                    print("here is the playlist\n")
                    print(playlist)
                }
                
                playlist.removeDuplicates()
                
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
                    
                } else {
                    playlist.displayPlaylist()
                }
                
            }
        }
    }
    
}
