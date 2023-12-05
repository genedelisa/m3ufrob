//
// File: InfoCommand.swift
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

enum DisplayOp: String, EnumerableFlag, Codable {
    case brief
    case long
    case detailed
    case onlySize
    case onlyTitle
    case titleAndDuration
    case hosts
    case directory
}

extension MainCommand {
    
    struct InfoCommand:  AsyncParsableCommand {
        static let version = "0.1.0"
        
        static var configuration = CommandConfiguration(
            commandName: "info",
            abstract: String(localized: """
            This reads a playlist, then displays info about it.
            """,
                             comment: "Help abstract"),
            usage: String(localized: """
              xcrun swift run m3ufrob info filename
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
        var inputFile: String = ""
        
        @Option(
            name: [.long],
            help: ArgumentHelp(
                String(localized: "Input Directory.", comment: ""),
                discussion:
                    String(localized: "Frob all playlists in this directory..", comment: "")
            )
        )
        var inputDirectoryName: String = FileManager.default.currentDirectoryPath
        
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
        
        @Flag(exclusivity: .exclusive,
              help:
                ArgumentHelp(
                    String(localized: "Choose field to sort on.", comment: ""),
                    discussion:
                        String(localized: "The playlist entries are sorted by this.", comment: "")
                )
        )
        var sortField: SortField = .sortByURLString
        
        @Flag(exclusivity: .exclusive,
              help:
                ArgumentHelp(
                    String(localized: "Choose sort direction.", comment: ""),
                    discussion:
                        String(localized: "The playlist entries are sorted by this.", comment: "")
                )
        )
        var sortOp: SortOp = .ascending
        
        @Flag(exclusivity: .exclusive,
              help:
                ArgumentHelp(
                    String(localized: "Choose display.", comment: ""),
                    discussion:
                        String(localized: "The .", comment: "")
                )
        )
        var displayOp: DisplayOp = .long
        
        //        @Flag(
        //            help: ArgumentHelp(
        //                String(localized: "Display .", comment: ""),
        //                discussion:
        //                    String(localized: "This will ", comment: "")
        //            )
        //        )
        //        var size = false
        
        @OptionGroup() var commonOptions: Options
        
        func validate() throws {
            if displayOp != .directory {
                guard !inputFile.isEmpty else {
                    throw ValidationError("You need to set the input file")
                }
            }
        }
        
        func run() async throws {
            
            if displayOp == .directory {
                await displayDirectory(inputDirectoryName)
                MainCommand.exit(withError: ExitCode.success)
            }

            let tildeExpanded = (inputFile as NSString).expandingTildeInPath
            let inputFileURL = URL(fileURLWithPath: tildeExpanded)
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: inputFileURL.path, isDirectory: &isDir) else {
                stderr.write("\(inputFileURL.path) does not exist\n".fg(.red))
                MainCommand.exit(withError: ExitCode.failure)
            }
            if isDir.boolValue {
                stderr.write("\(inputFileURL.path) is a directory\n".fg(.red))
                MainCommand.exit(withError: ExitCode.failure)
            }
            
            let playlist = Playlist(fileURL: inputFileURL)
            await playlist.load()
            playlist.removeDuplicates(sortField: self.sortField, sortOp: self.sortOp)
            
            
            if commonOptions.verbose {
                print("here is the playlist\n")
                print(playlist)
            }
            
            switch displayOp {
                
            case .brief:
                displayBrief(playlist, url: inputFileURL)
            case .long:
                displayLong(playlist, url: inputFileURL)
            case .detailed:
                displayDetailed(playlist, url: inputFileURL)
            case .onlySize:
                //print("\(inputFileURL.path)".fg(.yellow))
                displaySize(playlist)
            case .onlyTitle:
                displayTitle(playlist)
            case .hosts:
                displayHosts(playlist)
            case .titleAndDuration:
                displayTitleAndDuration(playlist)
            case .directory:
                await displayDirectory(inputDirectoryName)
            }
            
            
          
            
            
            
            
            //            if save {
            //
            //                var base = outputFile
            //                if self.outputFile.isEmpty {
            //                    base = URL(filePath: inputFile).deletingPathExtension().lastPathComponent
            //                }
            //                base += ".good"
            //                let outputURL = createSaveURL(basename: base)
            //
            //                FileService.shared.write(string: "#EXTM3U\n\n", to: outputURL)
            //
            //                let df = ISO8601DateFormatter()
            //                let now = df.string(from: Date())
            //                FileService.shared.write(string: "# \(now)\n\n", to: outputURL)
            //
            //                for link in goodLinks {
            //                    if commonOptions.verbose {
            //                        print("Writing \(link)".fg(.dodgerBlue))
            //                    }
            //                    FileService.shared.append(string: "\(link.extInf)\n", to: outputURL)
            //                    FileService.shared.append(string: "\(link.urlString)\n\n", to: outputURL)
            //                }
            //            }
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
            
            let tildeExpanded = (outputDir as NSString).expandingTildeInPath
            //print("tildeExpanded: \(tildeExpanded)".fg(.yellow))

//            var outputURL = URL(fileURLWithPath: outputDir)
            var outputURL = URL(fileURLWithPath: tildeExpanded)
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
        
        func displayDirectory(_ inputDirectoryName: String) async {
            // Expand any tilde in the path
            let tpath = (inputDirectoryName as NSString).expandingTildeInPath
            print("tilde path: \(tpath)".fg(.yellow))
            
            var directoryURL = URL(fileURLWithPath: tpath)
            directoryURL.resolveSymlinksInPath()
            directoryURL.standardize()

            print("Playlists in directory: \(directoryURL.path())")

            var dict:[Int: String] = [:]
            let playlists = await Playlist.readPlaylistDirectory(directoryURL)
            for playlist in playlists {
                if let url = playlist.fileURL {
                    dict[playlist.playlistEntries.count] = url.path()
                }
            }
            
//            let sortedDict = dict.sorted(by: { $0.value < $1.value } )
            let sortedDict = dict.sorted(by: { $0.key < $1.key } )
            for (k,v) in sortedDict {
                let s =
                k.formatted(.number.precision(.integerLength(5))).fg(.aqua) +
                " : ".fg(.red) +
                v.fg(.orange)
                print(s)
            }
        }
        
        
        func displayEntries(_ playlist: Playlist,
                            displayIndex: Bool = false,
                            displaySize: Bool = false,
                            displaySeconds: Bool = false
        ) {
            var index = 0
//            let nf = NumberFormatter()
//            nf.numberStyle = .none
//            nf.minimumIntegerDigits = 3
            
            for entry in playlist.sortedEntries {
                index += 1
                let url = URL(string: entry.urlString)!
                let title = entry.title
                let duration = entry.duration
                
                // https://github.com/apple/swift-evolution/blob/main/proposals/0329-clock-instant-duration.md
                let d: Duration = .seconds(duration)
                
                var str = ""
                if displayIndex {
                    //let i = nf.string(from: index as NSNumber)!
                    //str = "\(i) : "
                    str += "\(index.formatted(.number.precision(.integerLength(3)))) : ".fg(.dodgerBlue)
                }
                if displaySeconds {
                    str += "\(duration.formatted(.number.precision(.fractionLength(3))))\t".fg(.dodgerBlue)
                }
                str += "\(d.formatted())\t".fg(.orange)
                str += "\(title)".fg(.yellow)

                print(str)
            }
        }

        func displayInfo(_ playlist: Playlist, url: URL) {
            print("\(url.path)".fg(.yellow))
            print("Total duration: \(playlist.totalDuration())".fg(.orange))
            print("Unique Count: \(playlist.uniqueCount)".fg(.orange))
            print("Count: \(playlist.count)".fg(.orange))
            print()
        }
        
        func displayBrief(_ playlist: Playlist, url: URL) {
            displayEntries(playlist, displayIndex: false, displaySize: false, displaySeconds: false)
        }
        
        func displayLong(_ playlist: Playlist, url: URL) {
            displayInfo(playlist, url: url)
            displayEntries(playlist, displayIndex: true, displaySize: true, displaySeconds: false)
        }
        
        func displayDetailed(_ playlist: Playlist, url: URL) {
            displayInfo(playlist, url: url)
            displayHosts(playlist)
            displayEntries(playlist, displayIndex: true, displaySize: true, displaySeconds: true)
        }
        
        func displaySize(_ playlist: Playlist) {
            print("\(playlist.count)".fg(.orange))
        }
        
        func displayTitleAndDuration(_ playlist: Playlist) {
            playlist.removeDuplicates(sortField: .sortByDuration,
                                      sortOp: .ascending)
            for entry in playlist.sortedEntries {
                let title = entry.title
                let d: Duration = .seconds(entry.duration)
                print("\(d.formatted()) : \(title)".fg(.orange))
            }
        }
        
        func displayTitle(_ playlist: Playlist) {
            for entry in playlist.sortedEntries {
                let title = entry.title
                print("\(title)".fg(.orange))
            }
        }
        
        func displayHosts(_ playlist: Playlist) {
            var hosts:[String : [PlaylistEntry]] = [:]
            for entry in playlist.sortedEntries {
                if let host = entry.getHost() {
                    // https://developer.apple.com/documentation/swift/dictionary/subscript(_:default:)
                    hosts[host, default: []].append(entry)
                }
            }
            print("By host".fg(.yellow))
            let maxKeyLength = hosts.keys.reduce(0, {x, y in
                return y.lengthOfBytes(using: .isoLatin1)
            })
            for (k,v) in hosts {
                print(
                    k.right(targetLength: maxKeyLength).fg(.orange) +
                    " : ".fg(.red) +
                    v.count.formatted(.number.precision(.integerLength(3))).fg(.aqua) +
                    " entries".fg(.lightSkyBlue)
                )
            }
            print()
        }
        //    func display(_ playlist: Playlist) {
        //
        //    }
        
    } // command
}
