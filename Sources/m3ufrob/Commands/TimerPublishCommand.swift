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

extension MainCommand {

    struct TimerPublishCommand: AsyncParsableCommand {

        static var configuration = CommandConfiguration(
            commandName: "poll",
            abstract: "This polls the service.",
            version: "0.1.0"
        )

        @OptionGroup() var commonOptions: Options

        @Option(name: [.customShort("i"), .long],
                help: ArgumentHelp(
                    String(localized:"Interval",
                           comment: "polling interval for poll command"),
                    discussion:
                        String(localized:"Set the publish interval",
                               comment: "arg for poll command")
                )
        )
        var interval: Double = 1.0

        func validate() throws {
            if interval <= 0.0 {
                throw ValidationError("Please specify a 'interval' > 0.")
            }
        }

        mutating func run() async throws {
            let service = PollingService()

            if commonOptions.verbose {
                print("running \(interval)")
            }

            service.interval = interval
            service.poll()
        }
    }
}
