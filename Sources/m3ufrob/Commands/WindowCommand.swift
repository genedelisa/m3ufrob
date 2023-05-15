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
                help: ArgumentHelp(
                    String(localized: "Voice.", comment: ""),
                    discussion:
                        "Set the voice")
        )
        var voice = "Serena"
        
//        @Option(name: .long,
//                help: ArgumentHelp(
//                    String(localized: "URL.", comment: ""),
//                    discussion:
//                        "The URL"
//                )
//        )
//        var url: URL?
        
//        var url: URL = URL(fileURLWithPath: ".")
        
        //var subject = "" // CurrentValueSubject<Int, Never>(4)

       // var windowCommandLogic =  WindowCommandLogic(url: URL(fileURLWithPath: "."))
        
        func validate() throws {
            if voice.isEmpty  {
                throw ValidationError("Please specify a valid 'voice'.")
            }
        }
        
        //var subscribers = Set<AnyCancellable>()
        
        func run() throws {
            
            guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
                print("'showWindow' isn't supported on this platform.")
                return
            }
            
            UserDefaults.standard.set(["it", "en"], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            let s = String(localized: "Choose", comment: "")
            print(s)


            
            let info = InfoClass(voiceName: voice)
            
//            let sub = info.$url
//                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
//                .receive(on: RunLoop.main)
//                .map { $0 }
//                .assign(to: \.url, on: self)
            
                //.assign(to:\MyViewModel.filterString, on: myViewModel)

            
//            let subscriber = info.$url.sink(
//                receiveCompletion: { (result) in
//                    switch result {
//                    case .finished:
//                        print("finished selecting url")
//                        //                    let app = NSApplication.shared
//                        //                    app.stop(self)
//                    case .failure(let error):
//                        print(error.localizedDescription)
//                    }
//                },
//                receiveValue: { (value) in
//                    print("\(value)".fg(.yellow))
//                    Task {
//                        await self.doit(url: value)
//                    }
//
//                    //                DispatchQueue.main.async {
//                    //                    let app = NSApplication.shared
//                    //                    if let d = app.delegate as? AppDelegate {
//                    //                        let w = d.window
//                    //                        w.close()
//                    //                    }
//                    //                    app.stop(self)
//                    //                }
//
//                    print(subscriber)
//
//                    //subscriber.cancel()
//                })
            
            if commonOptions.verbose {
                print("info \(info.info())")
            }
            
            DispatchQueue.main.sync {
                let delegate = AppDelegate(info: info)
//                let delegate = AppDelegate(windowCommandLogic: windowCommandLogic)
                let app = NSApplication.shared
                app.delegate = delegate
                app.run()
            }
            
            WindowCommand.exit(withError: ExitCode.success)
        }
        
        
        func doit(url: URL) async {
            let playlists = await Playlist.readPlaylistDirectory(url)
            for playlist in playlists {
                print("Playlist: \(playlist.fileURL.absoluteString)")
                print("Entry count: \(playlist.playlistEntries.count)")
            }
        }
    }
}
