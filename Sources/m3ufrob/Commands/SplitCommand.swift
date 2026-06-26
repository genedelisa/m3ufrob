//
// File:         SplitCommand
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


extension MainCommand {
    
    struct SplitCommand:  AsyncParsableCommand {
        static let version = "0.1.0"
        
        static var configuration = CommandConfiguration(
            commandName: "split",
            abstract:
                String(localized: "This reads a playlist(s), then splits it according to size.", comment: ""),
            usage: """
              xcrun swift run m3ufrob split $m3ufile
              m3ufrob split --split_size 100 filename
              
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
        var inputFile: String = "-"
        
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
        
        @Argument(help:
                    ArgumentHelp(
                        String(localized: "The size of the split.",
                               comment: "help for arg"),
                        discussion:
                            String(localized: "The size of the split.",
                                   comment: "help discussion for arg")
                    )
        )
        var splitSize: Int = 100
        
        @OptionGroup() var commonOptions: Options
        
        func validate() throws {
            
            // if let inputFile {
            guard !inputFile.isEmpty else {
                throw ValidationError("You need to set the input file")
            }
            //  }
        }
        
        func splitFileIntoChunks(inputFilePath: String, outputDirectory: String, linesPerChunk: Int = 100) {
            do {
                // Read the entire file content
                let fileContent = try String(contentsOfFile: inputFilePath)
                let lines = fileContent.components(separatedBy: .newlines)
                
                var chunkIndex = 0
                for chunkStart in stride(from: 0, to: lines.count, by: linesPerChunk) {
                    let chunkEnd = min(chunkStart + linesPerChunk, lines.count)
                    let chunkLines = lines[chunkStart..<chunkEnd]
                    let chunkContent = chunkLines.joined(separator: "\n")
                    
                    let outputFilePath = "\(outputDirectory)/chunk_\(chunkIndex).txt"
                    try chunkContent.write(toFile: outputFilePath, atomically: true, encoding: .utf8)
                    
                    chunkIndex += 1
                }
                
                print("Successfully split file into \(chunkIndex) chunks.")
            } catch {
                print("Error: \(error)")
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
                // let s = "input file name: \(inputFile ?? "no input file")".justify(.left)
                //   .fg256(.aqua).bg256(.deepPink3)
                let s = "input file name: \(inputFile)".justify(.left)
                    .fg256(.aqua).bg256(.deepPink3)
                print(s)
                
                //                print("input file name: \(inputFile ?? "no input file")  ")
                print("input file name: \(inputFile)")
                print("output file \(outputFileName ?? "output file not set")")
                print("verbose \(commonOptions.verbose)")
            }
            
            var playlist: Playlist
            var inputFileURL: URL?
            
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
                
                for (index, element) in playlist.playlistEntries.enumerated() {
                    if index >= splitSize {
                        break
                    }
                    print("# \(index)")
                    print("\(element.extInf)")
                    print("\(element.urlString)\n")
                }
                
                //                var count:Int = 0
                //                while(count < playlist.playlistEntries.count && count < splitSize) {
                //                    count += 1
                //                    let entry = playlist.playlistEntries[count]
                //                    print("\(entry)")
                //                }
                
                //                for entry in playlist.playlistEntries {
                //                    //print("\(entry)")
                //
                //                    //                                if entry.title == "badInput" {
                //                    //                                    print("entry has bad input")
                //                    //                                } else {
                //                    //                                    print("\(entry)")
                //                    //                                }
                //
                //                }
                
                //                if commonOptions.verbose {
                //                    print("here is the playlist\n")
                //                    print(playlist)
                //                }
            }
            
        } // run
    } // command
}

