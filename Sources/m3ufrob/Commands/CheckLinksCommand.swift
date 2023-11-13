//
// File: CheckLinksCommand.swift
// Project:
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
import ArgumentParser
import GDTerminalColor
import AppKit

extension MainCommand {
    
    struct CheckLinksCommand:  AsyncParsableCommand {
        static let version = "0.1.0"
        
        static var configuration = CommandConfiguration(
            commandName: "check",
            abstract: String(localized: """
            This reads a playlist, then checks for dead links.
            """,
                             comment: "Help abstract"),
            usage: String(localized: """
              xcrun swift run m3ufrob check filename
            """,
                          comment: "Help Usage"),
            version: version
        )
        
        @Argument(help:
                    ArgumentHelp(
                        String(localized: "Input playlist file.",
                               comment: "help for arg"),
                        discussion:
                            String(localized: "The filename of the input playlist.",
                                   comment: "help discussion for arg")
                    )
        )
        var inputFile: String
        
        @Flag(
            help:
                ArgumentHelp(
                    String(
                        localized: "Save the output to a file.",
                        comment: ""),
                    discussion:
                        String(
                            localized: "Save the output to a file with the same basename.",
                            comment: "")
                )
        )
        var save = false
        
        @Option(
            name: [.long],
            help: ArgumentHelp(
                String(
                    localized: "The output directory.",
                    comment: ""),
                discussion:
                    String(
                        localized: "If --save is used, write to this directory.",
                        comment: "")
            )
        )
        var outputDir: String = FileManager.default.currentDirectoryPath
        
        @Option(
            name: [.short, .long],
            help: ArgumentHelp(
                String(
                    localized: "The output file.",
                    comment: ""),
                discussion:
                    String(
                        localized: "If --save is used, write to this file.",
                        comment: "")
            )
        )
        
        var outputFile: String = ""
        
        @Flag(
            name: [.long],
            help:
                ArgumentHelp(
                    String(localized: "Show good links", comment: ""),
                    discussion:
                        String(localized: "Show good links", comment: "")
                )
        )
        public var showGood: Bool = false
        
        @Flag(
            name: [.long],
            help:
                ArgumentHelp(
                    String(localized: "Show bad links", comment: ""),
                    discussion:
                        String(localized: "Show bad links", comment: "")
                )
        )
        public var showBad: Bool = false

        
        @OptionGroup() var commonOptions: Options
        
        func validate() throws {
            guard !inputFile.isEmpty else {
                throw ValidationError("You need to set the input file")
            }
        }
        
        func run() async throws {
            
            let inputFileURL = URL(fileURLWithPath: inputFile)
            
            if !FileManager.default.fileExists(atPath: inputFileURL.path) {
                //print("\(inputFile) does not exist".fg(.red))
                stderr.write("\(inputFile) does not exist".fg(.red))
                MainCommand.exit(withError: ExitCode.failure)
            }
            
           
            
            let playlist = Playlist(fileURL: inputFileURL)
            await playlist.load()
            
            if commonOptions.verbose {
                print("here is the playlist\n")
                print(playlist)
            }
            
            var goodLinks: [PlaylistEntry] = []
            var badLinks: [PlaylistEntry] = []
            
            for entry in playlist.playlistEntries {
                let url = URL(string: entry.urlString)!
                let isOK = await self.checkLink(url)
                if isOK {
                    if commonOptions.verbose {
                        print("Link \(entry.urlString) is groovy".fg(.yellow))
                    }
                    goodLinks.append(entry)
                } else {
                    if commonOptions.verbose {
                        print("Link \(entry.urlString) is dead, Jim".fg(.red))
                    }
                    badLinks.append(entry)
                }
            }
            
            //print("Good links")
            
            if showGood {
                for link in goodLinks {
                    print("\(link.extInf)")
                    print("\(link.urlString)\n")
                }
                //print("\n\n\n")
            }
            
            //print("Bad links")
            if showBad {
                for link in badLinks {
                    print("\(link.extInf)")
                    print("\(link.urlString)\n")
                }
            }
            
            if save {
                
                var base = outputFile
                if self.outputFile.isEmpty {
                    base = URL(filePath: inputFile).deletingPathExtension().lastPathComponent
                }
                base += ".good"
                let outputURL = createSaveURL(basename: base)
                
                FileService.shared.write(string: "#EXTM3U\n\n", to: outputURL)
                
                let df = ISO8601DateFormatter()
                let now = df.string(from: Date())
                FileService.shared.write(string: "# \(now)\n\n", to: outputURL)
                
                for link in goodLinks {
                    if commonOptions.verbose {
                        print("Writing \(link)".fg(.dodgerBlue))
                    }
                    FileService.shared.append(string: "\(link.extInf)\n", to: outputURL)
                    FileService.shared.append(string: "\(link.urlString)\n\n", to: outputURL)
                }
            }
        }
        
        func createSaveURL(basename: String) -> URL {
            
            var outputDir = self.outputDir
            
            // check preferences, then environment, then command line
            
            if let pref = Preferences.sharedInstance.outputDirectory {
                if commonOptions.verbose {
                    print("output directory from preferences: \(pref)")
                }
                outputDir = pref
            }
            
            if let env = ProcessInfo.processInfo.environment["M3UFROB_OUTPUT_DIR"] {
                outputDir = env
                
                if commonOptions.verbose {
                    print("M3UFROB_OUTPUT_DIR: \(env)")
                }
            }
            
            var outputURL = URL(fileURLWithPath: outputDir)
                .appendingPathComponent(basename)
                .appendingPathExtension("m3u8")
            
            outputURL.resolveSymlinksInPath()
            outputURL.standardize()
            
            // the path is percent encoded when the URL instance
            // is created. The fileExists func does not like that.
            let ucPath = outputURL.path(percentEncoded: false)
            
            if commonOptions.verbose {
                print("Writing to file path: \(outputURL.path())")
                print("Writing to file unpercent path: \(ucPath)")
            }
            
            let pasteboard: NSPasteboard = .general
            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            pasteboard.setString(
                ucPath, forType: NSPasteboard.PasteboardType.string)
            
            if FileManager.default.fileExists(atPath: ucPath) {
                print()
                Color256.print(
                    "\(ucPath) already exists",
                    fg: XTColorName.red)
                Color256.print(
                    "Overwrite? [y/N]\n",
                    fg: .red)
                
                let y = Character("y").asciiValue!
                let inputInt = getch()
                if inputInt != y {
                    Color256.print("Bye", fg: .red)
                    MainCommand.exit(withError: ExitCode.success)
                } else {
                    Color256.print("OK! Overwriting.", fg: .yellow)
                }
            }
            
          
            return outputURL
        }
        
        func checkLink(_ url: URL) async -> Bool {
            
            var request = URLRequest(url: url,
                                     cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                     timeoutInterval: 10.0)
            request.httpMethod = "HEAD"
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if commonOptions.verbose {
                        print("status \(httpResponse.statusCode) for url \(url.absoluteString)")
                    }
                    switch httpResponse.statusCode {
                    case 400:
                        stderr.write("400 Bad Request \(url)\n".fg(.red))
                    case 403:
                        stderr.write("403 Forbidden: \(url)\n".fg(.red))
                    default: break
                    }
                    return httpResponse.statusCode == 200
                } else {
                    return false
                }
            } catch {
                stderr.write("Error checking link: \(error.localizedDescription)\n".fg(.red))
                return false
            }
        }
    }
}
