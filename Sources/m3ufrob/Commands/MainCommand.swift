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


import ArgumentParser
import Foundation
import os.log
import OSLog

@available(macOS 10.15, *)
@main
struct MainCommand: AsyncParsableCommand {
    static let version = "0.1.0"

    static var configuration = CommandConfiguration(
      commandName: "m3ufrob",
      abstract: "Create a thing",
      usage: """
        xcrun swift run m3ufrob  -h
        xcrun swift run m3ufrob --prolix-help

        """,
      version: version,
      subcommands: [
        SortCommand.self,
        CheckLinksCommand.self,
        TimerPublishCommand.self,
        WindowCommand.self],
      defaultSubcommand: SortCommand.self
    )

    struct Options: ParsableArguments {
        @Flag(name: .shortAndLong,
              help: ArgumentHelp(String(localized: "Yakity yak.", comment: "")))
        var verbose = false
    }
    @OptionGroup() var commonOptions: Options

    @Flag(
      help: ArgumentHelp(NSLocalizedString("Display the current version.", comment: ""),
                         discussion: "This will display the current version then exit")
    )
    var version = false

    @Flag(
      help: ArgumentHelp(NSLocalizedString("Display the help document.", comment: ""),
                         discussion: "This will print the help file to stdout")
    )
    var prolixHelp = false

    @Flag(
      help: ArgumentHelp(NSLocalizedString("Display the JSON response.", comment: ""),
                         discussion: "This will print the JSON returned from the server")
    )
    var displayJSON = false

    @Flag(help: ArgumentHelp(NSLocalizedString("Display the log entries for debugging.", comment: ""),
                             discussion: "Display the log entries for debugging.")
    )
    var showLogging = false


    @Flag(name: [.long],
          help: ArgumentHelp(NSLocalizedString("reset all stored preferences", comment: ""),
                             discussion: "Remove all default values."))
    var resetDefaults = false


    mutating func validate() throws {

//        guard !inputDirectoryName.isEmpty else {
//            throw ValidationError("You need to set the input directory.")
//        }

        //        guard fetchLimit >= 1 else {
        //            throw ValidationError("Please specify a 'fetchLimit' of at least 1.")
        //        }
    }

    func showHelp() {
        if let helpURL = Bundle.module.url(forResource: "help",
                                           withExtension: "txt") {
            do {
                let data = try Data(contentsOf: helpURL)
                if let s = String(data: data, encoding: .utf8) {
                    print(s)
                }
            } catch {
                print(error.localizedDescription)
            }
        } else {
            print("The help file was not found.")
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
            print("'m3ufrob' isn't supported on this platform.")
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


        //                if verbose {
        //                    Logger.command.info("Fetching user with id \(id, privacy: .public)")
        //                    print("🔭 Fetching user with id \(id)")
        //                }

        let dateFormatter: DateFormatter = {
            let dateFormat = DateFormatter()
            dateFormat.dateStyle = .medium
            dateFormat.timeStyle = .medium
            dateFormat.timeZone = TimeZone.current
            return dateFormat
        }()
        let ts = dateFormatter.string(from: Date())
        print("date \(ts)")

        // let inputDirectoryURL = URL(fileURLWithPath: self.inputDirectoryName)
        // if commonOptions.verbose {
        //     Logger.command.info("input directory \(inputDirectoryURL.absoluteString, privacy: .public)")
        //     print("input directory \(inputDirectoryURL.absoluteString)")
        // }


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
