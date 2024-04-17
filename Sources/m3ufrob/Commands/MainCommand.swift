//
// File:         MainCommand.swift
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

import ArgumentParser
import Foundation
import os.log
import OSLog
import GDTerminalColor

@available(macOS 10.15, *)
@main
struct MainCommand: AsyncParsableCommand {
    static let version = "0.1.0"
    
    static var configuration = CommandConfiguration(
        commandName: "m3ufrob",
        abstract: """
A few common frobs for playlists are available.
You can sort a playlist and remove duplicate entries.
You can check the links in the playlist and indicates which are dead.
""",
        usage: """
        xcrun swift run m3ufrob  -h
        xcrun swift run m3ufrob --prolix-help
        
        xcrun swift run m3ufrob sort inputfile
        xcrun swift run m3ufrob sort inputfile -o outputfile
        
        """,
        version: version,
        subcommands: [
            SortCommand.self,
            MergeCommand.self,
            FilterCommand.self,
            //TODO: what happened to this command?
            //SearchCommand.self,
            HTMLCommand.self,
            CheckLinksCommand.self,
            InfoCommand.self,
            ByHostCommand.self,
            TimerPublishCommand.self,
            WindowCommand.self]
        
        // the run() right here will never be executed if you specify this
        //        defaultSubcommand: SortCommand.self
    )
    
    struct Options: ParsableArguments {
        
        @Flag(name: .shortAndLong,
              help: ArgumentHelp(
                String(localized: "Yakity yak.", comment: ""),
                discussion:
                    String(localized: "Print a lot of debugging information", comment: "")
              )
        )
        var verbose = false
    }
    
    
    @OptionGroup() var commonOptions: Options
    
    @Flag(
        help: ArgumentHelp(
            String(localized: "Display the current version.", comment: ""),
            discussion:
                String(localized: "This will display the current version then exit", comment: "")
        )
    )
    var version = false
    
    @Flag(
        help: ArgumentHelp(
            String(localized: "Display the help document.", comment: ""),
            discussion:
                String(localized: "This will print the help file to stdout", comment: "")
        )
    )
    var prolixHelp = false
    
    @Flag(
        help: ArgumentHelp(
            String(localized: "Display the log entries for debugging.", comment: ""),
            discussion:
                String(localized: "Display the log entries for debugging.", comment: "")
        )
    )
    
    var showLogging = false
    
    @Flag(name: [.long],
          help: ArgumentHelp(
            String(localized: "reset all stored preferences", comment: ""),
            discussion:
                String(localized: "Remove all default values.", comment: "")
          )
    )
    var resetDefaults = false
    
    //MAKR: functions
    
    mutating func validate() throws {
    }
    
    func showHelp() {
        
        if let helpURL = Bundle.module.url(forResource: "help",
                                           withExtension: "txt") {
            
            Task {
                do {
                    print("Current Locale code: \(Locale.current.identifier)")
                    if let language = Locale.current.language.languageCode {
                        let languageCode = language.identifier
                        print("Language code: \(languageCode)")
                    }
                    if let code = Bundle.main.preferredLocalizations.first?.components(separatedBy: "-").first {
                        print("bundle code: \(code)")
                               // Locale.current.languageCode ?? "en"
                    }
                    let languagePrefix = Locale.preferredLanguages[0]
                    print(languagePrefix)
                    let langCode = Bundle.main.preferredLocalizations[0]
                    print("Bundle.main.preferredLocalizations: \(langCode)")

                    for pl in Bundle.main.preferredLocalizations {
                        print("preferred \(pl)")
                    }
                    for loc in Bundle.main.localizations {
                        print("localizations \(loc)")
                    }
                    
                    if let s = ProcessInfo().environment["LC_ALL"] {
                        print("LC_ALL \(s)")
                        if s.starts(with: "it") {
                            let itloc = Locale(identifier: "it_IT.ISO8859-15")
                            print("setting italian \(itloc)")
                            UserDefaults.standard.set(["it_IT.ISO8859-15"], forKey: "AppleLanguages")
                            UserDefaults.standard.synchronize()

                        }
                    }
                    if let s = ProcessInfo().environment["LANG"] {
                        print("LANG \(s)")
                    }

                    
                    ColorConsole.enablePrintColors()
                    for try await line in helpURL.lines {
                        print(line)
                    }
                    ColorConsole.disablePrintColors()
                    
                } catch  {
                    Logger.playlist.error("Could not read contents of \(helpURL, privacy: .public)")
                    Logger.playlist.error("\(error.localizedDescription, privacy: .public)")
                    stderr.write("Could not read contents of \(helpURL)")
                }
            }
            
            //            do {
            //                let data = try Data(contentsOf: helpURL)
            //                if let s = String(data: data, encoding: .utf8) {
            //                    print(s)
            //                }
            //            } catch {
            //                print(error.localizedDescription)
            //            }
            
        } else {
            stderr.write("The help file was not found.")
        }
    }
    
    func checkAndSetDefaults() {
        
        if resetDefaults {
            Preferences.resetDefaults()
            Preferences.sharedInstance.resetAll()
            MainCommand.exit(withError: ExitCode.success)
        }
        
    }
    
    func run() async throws {
        
        guard #available(macOS 12, *) else {
            print("\(Self.configuration.commandName ?? "command") isn't supported on this platform.")
            return
        }
        
        if Preferences.sharedInstance.isFirstRun() {
            Logger.command.debug("first run")
        }
        
        if version {
            print("version: \(Self.version)")
            MainCommand.exit(withError: ExitCode.success)
        }
        
        checkAndSetDefaults()
        
        
        if prolixHelp {
            showHelp()
            MainCommand.exit(withError: ExitCode.success)
        }
        
        if showLogging {
            
            let entries: [OSLogEntryLog] = Logger.findEntries(subsystem: OSLog.subsystem)
            let estrings =
            entries.map {
                (entry: OSLogEntryLog) -> String in
                "\(entry)"
            }
            
            for entry in estrings {
                print("\(entry)")
            }
        }
        
    }
    
}
