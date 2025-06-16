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
    
    struct FilterCommand:  AsyncParsableCommand {
        static let version = "0.1.0"
        
        static var configuration = CommandConfiguration(
            commandName: "filter",
            abstract:
                String(localized: "This filters playlists.", comment: ""),
            usage: """
              Playlist containing the word thing with whitespace both before and after the word.
              xcrun swift run m3ufrob filter --regexp '\\s+thing\\s+' playlist1 playlist2
              m3ufrob filter --regexp '\\s+thing\\s+' playlist1 playlist2
              
              Remove the matches
              m3ufrob filter --regexp '\\s+thing\\s+' --remove playlist
              
              Search for the literal string monday
              m3ufrob filter --search monday playlist1
              
              Play the videos by sending to mpv's stdin
              m3ufrob filter --search kitty playlist1 | mpv -
              
              Multiple regular expressions

              Concatenate the patterns
              m3ufrob filter --pattern-or --pattern foo --pattern bar file
              Logical Or the patterns
              m3ufrob filter --pattern foo --pattern bar file
              
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
            name: [.short, .long],
            help: ArgumentHelp(
                String(localized: "Search term.", comment: ""),
                discussion:
                    String(localized: "The search term.", comment: "")
            )
        )
        var search: String?
        
        @Option(
            name: [.short, .long],
            help: ArgumentHelp(
                String(localized: "Regexp Search term.", comment: ""),
                discussion:
                    String(localized: "The regular expression search term.", comment: "")
            )
        )
        var regexp: String?
        
        @Option(
            name: [.short, .long], // Allows -p or --pattern
            help: ArgumentHelp(
                String(localized: "Regexp Search terms.", comment: ""),
                discussion:
                    String(localized: "Regular expression pattern(s) to combine for matching. Can specify multiple times.", comment: "")
            )
        )
        var pattern: [String]
        
//        @Option(
//            name: [.short, .long], // Allows -p or --pattern
////            parsing: .unconditional, // Allows multiple -p options to build an array
//            help: "A regular expression pattern to match filenames. Can be specified multiple times to combine patterns."
//        )
//        var pattern: [String]

        
        @Flag(
            name: [.long],
            help:
                ArgumentHelp(
                    String(localized: "patternOr", comment: ""),
                    discussion:
                        String(localized: "Used with --pattern. Logical or the patterns instead of concatenation", comment: "")
                )
        )
        public var patternOr: Bool = false
        

        @Flag(
            name: [.long],
            help:
                ArgumentHelp(
                    String(localized: "remove", comment: ""),
                    discussion:
                        String(localized: "Remove the matching entries. Without this, show the matches.", comment: "")
                )
        )
        public var remove: Bool = false

        @Flag(
            name: [.long],
            help:
                ArgumentHelp(
                    String(localized: "color", comment: ""),
                    discussion:
                        String(localized: "Display ANSI colors in terminal output", comment: "")
                )
        )
        public var color: Bool = false
        
        
        @OptionGroup() var commonOptions: Options
        
        func validate() throws {
            if inputFileNames.isEmpty {
                throw ValidationError("You need to set the input files")
            }
            
            for filename in inputFileNames {
                if !FileManager.default.fileExists(atPath: filename) {
                    throw ValidationError("\(filename) does not exist")
                }
            }
        }
        
        func doFilter(playlist: Playlist, re: Regex<AnyRegexOutput>) async throws -> [PlaylistEntry] {
            var filtered = [PlaylistEntry]()

            for entry in playlist.sortedEntries {
                
                if entry.title.contains(re) {
                    if remove {
                        if let index = playlist.sortedEntries.firstIndex(of: entry) {
                            playlist.sortedEntries.remove(at: index)
                            if commonOptions.verbose {
                                print("removed \(index) count is now \(playlist.sortedEntries.count)")
                                print("entry removed \(entry.title)")
                            }
                        }
                    } else {
                        filtered.append(entry)
                    }
                }
            }
            if remove {
                return playlist.sortedEntries
            } else {
                return filtered
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
                print("output file \(outputFileName ?? "output file not set")  ")
                print("verbose \(commonOptions.verbose)")
            }
            
            if inputFileNames.count > 0 {
                
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
                
                var filtered = [PlaylistEntry]()
                
//                var filteredPlaylist: Playlist
//                if remove {
//                    filteredPlaylist = Playlist(entries: merged.playlistEntries, sortedEntries: merged.sortedEntries)
//                } else {
//                    filteredPlaylist = Playlist(entries: filtered)
//                }
                
                if let search {
                    for entry in merged.sortedEntries {
                        if entry.title.contains(search) {
                            if remove {
                                if let index = merged.sortedEntries.firstIndex(of: entry) {
                                    merged.sortedEntries.remove(at: index)
                                }
                            } else {
                                filtered.append(entry)
                            }
                        }
                    }
                } else if pattern.count > 0 {
                    if commonOptions.verbose {
                        print("patterns \(pattern)")
                    }
                    
                    let thePattern: String
                    
                    if patternOr {
                        // to or the patterns
                        thePattern = pattern.map { "(\($0))" }.joined(separator: "|")
                        //print("combinedOrPattern \(thePattern)")
                    } else {
                        // Combine patterns by concatenation.
                        thePattern = pattern.joined()
                        //print("combinedPattern \(thePattern)")
                    }

                    let regex: Regex<AnyRegexOutput>
                    do {
                        regex = try Regex(thePattern).ignoresCase(true)
                    } catch {
                        throw ValidationError("Error: Invalid regular expression pattern '\(thePattern)': \(error.localizedDescription)")
                    }
                    
                    do {
                        filtered = try await doFilter(playlist: merged, re: regex)
                        //print("\(filtered)")
                    } catch {
                        stderr.write("\(error.localizedDescription)")
                        MainCommand.exit(withError: ExitCode.failure)
//                        throw CleanExit.message("Error: Could not filter with regex '\(regex)': \(error.localizedDescription)")

                    }

                } else if let regexp {
                    do {
                        let re = try Regex(regexp)
                            .ignoresCase(true)
                        
                        for entry in merged.sortedEntries {
                            
                            if entry.title.contains(re) {
                                if remove {
                                    if let index = merged.sortedEntries.firstIndex(of: entry) {
                                        merged.sortedEntries.remove(at: index)
                                        if commonOptions.verbose {
                                            print("removed \(index) count is now \(merged.sortedEntries.count)")
                                            print("entry removed \(entry.title)")
                                        }
                                    }
                                } else {
                                    filtered.append(entry)
                                }
                            }
                        }
                    } catch {
                        stderr.write("\(error.localizedDescription)")
                        MainCommand.exit(withError: ExitCode.failure)
                    }
                }
                
                var filteredPlaylist: Playlist
                if remove {
                    filteredPlaylist = Playlist(entries: merged.sortedEntries,
                                                sortedEntries: merged.sortedEntries)
                } else {
                    filteredPlaylist = Playlist(entries: filtered)
                }

                //let filteredPlaylist = Playlist(entries: filtered)
                filteredPlaylist.removeDuplicates()
                
                
                if let outputFileName {
                    await Playlist.save(filePath: outputFileName, playlist: filteredPlaylist)
                    pasteboard.setString(outputFileName,
                                         forType: NSPasteboard.PasteboardType.string)
                    if commonOptions.verbose {
                        print("Saved to: \(outputFileName)".fg(.yellow))
                    }
                } else {
                    Terminal.shared.display(playlist: filteredPlaylist, color: color)
                }
                
            }
            
        }
        
    }
    
}


