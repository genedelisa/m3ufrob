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


//TODO: implemant this!

extension MainCommand {
    
    struct SelectCommand:  AsyncParsableCommand {
        static let version = "0.1.0"
        
        static var configuration = CommandConfiguration(
            commandName: "select",
            abstract:
                String(localized: "This displays the url given a title.", comment: ""),
            usage: """
              return the url (default)
              m3ufrob select --search-title searchterm  playlist
              
              m3ufrob select --search-title searchterm  --return-url playlist
              m3ufrob select --search-title searchterm  --return-title playlist
              m3ufrob select --search-title searchterm  --return-both playlist
              
              m3ufrob select --search-image searchterm  --return-image-url playlist
              
              
              
              
              Playlist containing the word thing with whitespace both before and after the word.
              xcrun swift run m3ufrob filter --regexp '\\s+thing\\s+' playlist1 playlist2
              m3ufrob filter --regexp '\\s+thing\\s+' playlist1 playlist2
              
              Search for the literal string monday
              m3ufrob filter --search monday playlist1
              
              Play the videos by sending to mpv's stdin
              m3ufrob filter --search kitty playlist1 | mpv -
              
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
        
        @Flag(
            name: [.long],
            help:
                ArgumentHelp(
                    String(localized: "remove", comment: ""),
                    discussion:
                        String(localized: "Remove the matching entries", comment: "")
                )
        )
        public var remove: Bool = false
        
        
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
                
                var filteredPlaylist: Playlist
                if remove {
                    filteredPlaylist = merged
                } else {
                    filteredPlaylist = Playlist(entries: filtered)
                }
                
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
                } else if let regexp {
                    do {
                        let re = try Regex(regexp)
                            .ignoresCase(true)
                        for entry in merged.sortedEntries {
                            if entry.title.contains(re) {
                                if remove {
                                    if let index = merged.sortedEntries.firstIndex(of: entry) {
                                        merged.sortedEntries.remove(at: index)
                                        print("removed \(index) count is now \(filtered)")
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
                
                
                //let filteredPlaylist = Playlist(entries: filtered)
                filteredPlaylist.removeDuplicates()
                
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
                    await Playlist.save(filePath: outputFileName, playlist: filteredPlaylist)
                    pasteboard.setString(outputFileName,
                                         forType: NSPasteboard.PasteboardType.string)
                    if commonOptions.verbose {
                        print("Saved to: \(outputFileName)".fg(.yellow))
                    }
                } else {
                    Terminal.shared.display(playlist: filteredPlaylist)
                }
                
            }
            
        }
        
    }
    
}


