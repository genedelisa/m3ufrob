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


import os.log
import OSLog


class InfoClass {
    static let version = "0.1.0"
    var date = Date()
    var voiceName = "Serena"

    init(voiceName: String) {
        self.voiceName = voiceName
    }


    func header() -> String {
        return "Here's the header"
    }

    func info() -> String {
        return "Here's some info\n\(date))"
    }

    func calculateInfo() {
        date = Date()
    }

    func say(blather: String) {
        let path = "/usr/bin/say"
        let arguments = ["-v", voiceName, blather]
        let task = Process.launchedProcess(launchPath: path, arguments: arguments)
        task.waitUntilExit()
    }

    func bash(_ command: String) -> String? {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        return output
    }
}
