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
import Combine

class InfoClass {
    static let version = "0.1.0"
    
    //    @Published var url: URL?
    
//    @Published var url: URL = URL(fileURLWithPath: ".")
    var url: URL?
    
    var voiceName = "Serena"
    
    init(voiceName: String) {
        self.voiceName = voiceName
    }
    
    func header() -> String {
        return "Directory"
    }
    
    func info() -> String {
        return "\(url?.lastPathComponent ?? "not set"))"
        
        //        if let url {
        //            return "\(url.lastPathComponent))"
        //        } else {
        //            return ""
        //        }
    }
    
    func calculateInfo() {
        
    }
    
    func show(merge: Bool, filename: String ) async {
        
        if let url {
            let playlists = await Playlist.readPlaylistDirectory(url)
            for playlist in playlists {
                print("Playlist: \(playlist.fileURL.absoluteString)")
                print("Entry count: \(playlist.playlistEntries.count)")
                playlist.removeDuplicates()
                
                if merge {
                    let merged = await playlist.mergeLoadedPlaylists(filePath: filename, playlists: playlists)
                    
                    print("There are \(merged.playlistEntries.count) entries.")
                    print("View them? y/n")
                    
                    let y = Character("y").asciiValue!
                    let ch = getch()
                    if ch == y {
                        merged.displayPlaylist()
                    }
                } else {
                    playlist.displayPlaylist()
                }
            }
        }
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
