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
import Combine
import AppKit

extension MainCommand {

    struct WindowCommand: ParsableCommand {
        static let version = "0.1.0"

        static var configuration = CommandConfiguration(
          commandName: "showWindow",
          abstract: "Show a window",
          usage: """
            xcrun swift run m3ufrob showWindow
            """,
          version: version
        )


        @OptionGroup() var commonOptions: Options

        @Option(name: .long,
                help: ArgumentHelp(NSLocalizedString("Voice", comment: ""),
                                   discussion: "Set the voice"))
        var voice = "Serena"

        func validate() throws {
            if voice.isEmpty  {
                throw ValidationError("Please specify a valid 'voice'.")
            }
        }

        func run() throws {

            let info = InfoClass(voiceName: voice)

            if commonOptions.verbose {
                print("info \(info.info())")
            }

            DispatchQueue.main.sync {
                let delegate = AppDelegate(info: info)
                let app = NSApplication.shared
                app.delegate = delegate
                app.run()
            }

            WindowCommand.exit(withError: ExitCode.success)
        }
    }
}
