//
// File:         CheckLinksCommand.swift
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
            
            for entry in playlist.playlistEntries {
                let url = URL(string: entry.urlString)!
                let isOK = await self.checkLink(url)
                if isOK {
                    print("Link \(entry.urlString) is groovy".fg(.yellow))
                } else {
                    print("Link \(entry.urlString) is dead, Jim".fg(.red))
                }
            }
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
                        stderr.write("400 Bad Request \(url)".fg(.red))
                    case 403:
                        stderr.write("403 Forbidden: \(url)".fg(.red))
                    default: break
                    }
                    return httpResponse.statusCode == 200
                } else {
                    return false
                }
            } catch {
                stderr.write("Error checking link: \(error.localizedDescription)".fg(.red))
                return false
            }
        }
    }
}
